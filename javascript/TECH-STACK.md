# Tech Stack

This document describes the tools and technologies used across all packages in this workspace.

---

## Runtime

- **[Node.js](https://nodejs.org/)** ≥ 18
  Node 18 is the minimum required version. It introduced stable ESM support and
  built-in `fetch`, eliminating the need for polyfills in common automation scenarios.

---

## Module System

- **ESM-only** ([ECMAScript Modules](https://nodejs.org/api/esm.html))
  All packages are published as pure ESM. They use `import`/`export` syntax and
  declare `"type": "module"` in `package.json`. CommonJS `require()` is not supported.
  Consumers must use Node.js 18+ and an ESM-compatible toolchain.

  **Exception — NX executor bridge:** `nx-graph-to-mermaid` includes a
  `executor-bridge.cjs` shim at the package root. NX loads executors via
  `require()`, so a thin CJS wrapper is necessary to bridge into the ESM
  implementation. The shim contains no logic — it is a single `require`/dynamic
  `import` trampoline. All real code remains ESM in `src/`.

---

## Language

- **[TypeScript](https://www.typescriptlang.org/)** ≥ 5.4
  All source code is written in strict TypeScript. Compiled to ESM JavaScript via `tsc`.
  No bundler is used — `tsc` output is published directly.

---

## Build Orchestration

- **NX** (See: https://nx.dev/)  ≥ 22.x
  Manages build and test task execution across packages in the workspace.
  Dependency ordering is declared via `dependsOn` in each package's `project.json`.
  NX owns the full execution graph — npm workspace scripts are not used for orchestration.

---

## Test Runners

- **Vitest** — used by every package in the workspace.

---

## Release Management

- **[Changesets](https://github.com/changesets/changesets)**
  Manages versioning, changelog generation, and coordinated publishing across all
  packages. All version bumps must originate from a committed changeset.
  See [Contributing](./docs/CONTRIBUTING.md#publishing-as-npm-packages) for details.

---

## Internal Packages

- **[`@doikayt/tooling-core`](./tooling-core/README.md)**
  Contains shared core (framework) logic used by other packages in this workspace. 

---

## Package Relationships
```
@doikayt/autogen-markdown-doc
  ├── @doikayt/update-markdown-toc
  │     └── @doikayt/tooling-core
  ├── @doikayt/nx-graph-to-mermaid
  │     └── @doikayt/tooling-core
  └── @doikayt/update-markdown-uml
        └── @doikayt/tooling-core
```

### Type Resolution and the Lint Target

ESLint is configured for type-aware linting via
[`tsconfig.eslint.json`](tsconfig.eslint.json) with
`@typescript-eslint/parser`. That parser performs type-aware linting, which
means it needs fully resolved types for all imports.

Each package resolves `@doikayt/tooling-core` via a `paths` alias in its own
[`tsconfig.json`](nx-graph-to-mermaid/tsconfig.json), pointing directly at
the source:
```json
"paths": {
  "@doikayt/tooling-core": ["../tooling-core/src/index.ts"]
}
```

However, [`tsconfig.eslint.json`](tsconfig.eslint.json) is a standalone
config — it includes all package source files directly via its own `include`
globs, but it does not inherit from or compose the per-package `tsconfig.json`
files, and therefore does not see their `paths` declarations.

Without `paths` aliases in `tsconfig.eslint.json`, when ESLint's parser
encounters `import ... from '@doikayt/tooling-core'` it falls back to
standard Node module resolution — looking in
`node_modules/@doikayt/tooling-core/package.json` and following the
`exports` field's `"types"` condition:
```json
"exports": {
  ".": {
    "types": "./dist/index.d.ts",
    "import": "./dist/index.js"
  }
}
```

This points to `node_modules/@doikayt/tooling-core/dist/index.d.ts` — a
**static snapshot of the last published version**, installed by npm. This is
not the same as `tooling-core/dist/` in the workspace. It is a self-contained
copy inside `node_modules/` that reflects the last version that was published to npm, not 
the latest version of the source code that you are currently working on.

This causes one important failure mode during active development: if you add
a field or type to `tooling-core` locally and reference it from another package
before publishing, lint resolves through the published snapshot in `node_modules`
which does not yet have that field. The field appears as `error` typed, and any
access to it cascades into `no-unsafe-assignment`, `no-unsafe-member-access`,
and `no-unsafe-argument` errors — even though the code is perfectly correct. 

The fix is to declare `paths` aliases directly in `tsconfig.eslint.json`,
pointing all `@doikayt/*` imports at their local TypeScript source:
```json
"compilerOptions": {
  "paths": {
    "@doikayt/tooling-core": ["./tooling-core/src/index.ts"],
    "@doikayt/update-markdown-toc": ["./update-markdown-toc/src/index.ts"],
    "@doikayt/nx-graph-to-mermaid": ["./nx-graph-to-mermaid/src/index.ts"],
    "@doikayt/update-markdown-uml": ["./update-markdown-uml/src/index.ts"]
  }
}
```

This bypasses `node_modules` entirely for lint resolution — the parser reads
live local source directly, with no `dist/` involved and no dependency on
publish state.

**Maintenance rule:** whenever a new package is added to this workspace, its
`paths` entry must be added to `tsconfig.eslint.json`. Omitting it will cause
lint failures as soon as that package's types are referenced from another
package's source during active development.

#### Automatic Build Ordering

The lint target in [`project.json`](project.json) declares:
```json
"dependsOn": ["^build"]
```

With `paths` aliases declared in `tsconfig.eslint.json`, all `@doikayt/*`
imports resolve directly to TypeScript source at lint time — no `dist/`
required. The `dependsOn` on the workspace-level lint aggregator is therefore
redundant and could be removed. It is retained for now to avoid an unforced
change, but should be cleaned up in a future pass.


[![No US Tax$ 4 genocide](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
