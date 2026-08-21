<!-- TOC:START -->
- [Design Principles](#design-principles)
  - [Bin Files Are JavaScript, Not TypeScript](#bin-files-are-javascript-not-typescript)
  - [ESM-Only, No CommonJS](#esm-only-no-commonjs)
  - [No Bundler](#no-bundler)
  - [One Lock File at the Workspace Root](#one-lock-file-at-the-workspace-root)
  - [The CLI Framework Pattern](#the-cli-framework-pattern)
  - [Check Mode Is Byte-for-Byte Comparison](#check-mode-is-byte-for-byte-comparison)
  - [The Marker Injection Pattern](#the-marker-injection-pattern)
  - [Why `dist/` Must Be Present at Publish Time](#why-dist-must-be-present-at-publish-time)
    - [The `prepack` contract](#the-prepack-contract)
  - [Progressive Disclosure in CLI Design](#progressive-disclosure-in-cli-design)
  - [Documentation Tools as Architectural Signals](#documentation-tools-as-architectural-signals)
<!-- TOC:END -->


# Design Principles

This document explains the reasoning behind structural and architectural
decisions in this workspace. It is intended for contributors who want to
understand not just how things work but why they are designed the way they are.

For day-to-day development workflows see:
[CONTRIBUTING.md](./CONTRIBUTING.md)

For the technology choices themselves see:
[TECH-STACK.md](../TECH-STACK.md)

---

## Bin Files Are JavaScript, Not TypeScript

Every plugin in this workspace follows the same entry point pattern:
```
bin/plugin-name.js   ← thin .js entry point, imports from dist/
src/                 ← all logic authored in TypeScript
dist/                ← compiled output produced by tsc, what bin/ imports
```

The bin file is deliberately kept as `.js` because Node.js executes it
directly as an ESM script. Node does not run TypeScript natively, and adding
a transpile step for the bin entry point alone would complicate the execution
model without adding value.

The bin file should remain as thin as possible — typically just a `runCli`
call and a descriptor import. All real logic belongs in `src/` as TypeScript.

Implication: unfortunately, you can't click on a referenced type in the bin file and get your IDE to jump to
the definition.

---

## ESM-Only, No CommonJS

All packages are published as pure ESM. They declare `"type": "module"` in
`package.json` and use `import`/`export` throughout.

CommonJS `require()` is not supported and dual publishing (ESM + CJS) is
deliberately avoided. The reasons:

- Node 18+ has stable, reliable ESM support — the minimum version required
  by all packages in this workspace
- Dual publishing doubles the maintenance surface and introduces subtle
  compatibility edge cases
- The tooling ecosystem this workspace targets (NX, Vitest, ts-morph) is
  ESM-native

Consumers must use Node.js 18+ and an ESM-compatible toolchain.

---

## No Bundler

TypeScript source is compiled directly to ESM JavaScript via `tsc`. The
compiler output is what gets published to npm — no bundler (esbuild, rollup,
webpack) is involved.

The reasons:

- These are Node.js CLI tools and library packages, not browser bundles.
  Bundling adds no value and obscures the published output.
- `tsc` output is transparent and debuggable — what you write is what gets
  published, modulo type erasure.
- Keeping the build pipeline minimal reduces the surface area for
  build-related failures and makes the workspace easier to onboard into.

---
## One Lock File at the Workspace Root

This workspace uses npm workspaces. There is a single `package-lock.json`
at `javascript/` that covers all packages in the workspace — individual
package directories do not have their own lock files.

This is standard npm workspaces behavior. When you run `npm install` from
`javascript/`, npm resolves dependencies across all packages and writes a
single lock file at the workspace root.

The practical consequence: never run `npm install` from inside an individual
package directory. Always run it from `javascript/`. Running it inside a
package directory would create a local `node_modules/` and `package-lock.json`
that conflict with the workspace setup.

For JVM developers: this is roughly analogous to a single `gradle.lockfile`
at the root of a multi-module Gradle build rather than one per submodule.

---

## The CLI Framework Pattern

> **NX executor exception:** `nx-graph-to-mermaid` is an NX executor, not a
> standalone CLI tool. It does not use `runCli`, `PluginDescriptor`, or
> `FileProcessor` — NX controls orchestration and invokes `runExecutor()`
> directly via `executor-bridge.cjs`. 

All other CLI plugins are built on a common framework provided by
`@doikayt/tooling-core`. The key concepts are:

- **`PluginDescriptor`** — declarative metadata describing the plugin's name,
  description, and custom CLI options. Drives help generation and option
  parsing automatically.
- **`runCli`** — the single entry point that handles argv parsing, config
  construction, file resolution, processing, and link validation. Plugins
  call this once from their bin file.
- **`FileProcessor`** — the interface a plugin implements to describe what
  to do with each file. Contains a single `process(filePath, config)` method.

This separation means plugin authors write a descriptor and a processor.
Everything else — argument parsing, error handling, exit codes, output
formatting, recursive traversal — is handled by the framework.

---

## Check Mode Is Byte-for-Byte Comparison

When running with `--check`, the tool compares the current file content
against the content that would be generated, as full strings. If there is
any difference anywhere the file is reported as stale.

Semantic comparison — detecting only meaningful changes while ignoring
whitespace or ordering differences — was deliberately not chosen. The reasons:

- Byte-for-byte comparison is simple, fast, and has no edge cases
- Generated output is fully deterministic — identical input always produces
  identical output — so any difference is always meaningful
- Semantic comparison would require understanding the output format, which
  couples the check logic to the generator logic

The invariant this enforces: `check(update(repo)) === pass`. If `update`
is run and then `check` is run immediately after, check must always pass.

---

## The Marker Injection Pattern

Plugins inject generated content into Markdown files between fixed marker
pairs, for example:
```
<!-- TOC:START -->
<!-- TOC:END -->
```

Content between the markers is replaced on each run. Content outside the
markers is never touched.

This pattern was chosen over config files or separate generated files for
several reasons:

- The marker placement is the configuration — the user decides where in their
  document the generated content appears, with no separate config file to
  maintain
- Generated content is co-located with the document it belongs to, making
  it immediately reviewable in pull requests
- The pattern is git-friendly — diffs show exactly what changed in the
  generated content
- It is consistent with established conventions in the markdown ecosystem
  (similar patterns are used by tools like doctoc and markdown-toc)

---
## Why `dist/` Must Be Present at Publish Time

All packages compile TypeScript to `dist/` via `tsc`. This directory is
gitignored — compiled artifacts are never committed. But `dist/` IS included
in the npm published artifact via the `files` field in `package.json`.

Packages lower in the dependency tree (e.g. `autogen-markdown-doc`) import
compiled JavaScript from `dist/` of their `@doikayt/*` dependencies —
never TypeScript source. This is the standard npm model.

The dependency tree is:
```
autogen-markdown-doc
  ├── update-markdown-toc  → dist/
  │     └── tooling-core   → dist/
  └── nx-graph-to-mermaid  → dist/
        └── tooling-core   → dist/
```

`tooling-core` sits at the base and has no `@doikayt/*` dependencies of
its own.

### The `prepack` contract

Every package in this workspace that compiles TypeScript must declare:
```json
"prepack": "npm run build"
```

This ensures `tsc` runs before `npm publish`, so `dist/` is always present
and current in the published artifact.
---


## Progressive Disclosure in CLI Design

The CLI surface of each plugin follows the progressive disclosure principle:
simplicity first, complexity only when needed.

In practice this means:

- The default invocation with no flags works correctly for the most common
  use case
- Advanced options exist but are never required
- The `autogen-markdown-doc` uber-plugin exposes the most opinionated and
  restricted interface — fewest options, most conventions enforced
- Individual plugins expose more control for users who need it

A user who learns one plugin already understands the interface of every other
plugin in the ecosystem. Consistent flag names, consistent exit codes,
consistent output formatting.

---

## Documentation Tools as Architectural Signals

The tools in this workspace are not only documentation generators — they are
architectural feedback mechanisms. When generated output is difficult to read,
that difficulty is usually a property of the source structure, not the tool.

See [DOCS_AS_ACTIVE_INFRASTRUCTURE.md](./DOCS_AS_ACTIVE_INFRASTRUCTURE.md) for a full
treatment of this principle and the specific signals each tool surfaces.


[![Remember the USS Liberty!](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
