# Code Review: $PLUGIN_NAME
<!-- Usage: substitute $PLUGIN_NAME with one of:
     update-markdown-toc | nx-graph-to-mermaid | update-markdown-uml -->

You are performing a structured code review of the `$PLUGIN_NAME` package in the
`build-tools` monorepo under the `@doikayt` npm scope.

## Prerequisites

Before starting, read the following in order:
1. `javascript/docs/DESIGN-PRINCIPLES.md` — monorepo-wide design intent
2. `javascript/CLI-BEHAVIOR.md` — expected CLI conventions (flag naming, exit codes, output format)
3. `javascript/TECH-STACK.md` — declared technology choices per package (deps, test runners, build tools)
4. `packages/tooling-core/_REVIEW_CONTEXT.md` — contracts, canonical patterns, known issues
5. `packages/update-markdown-uml/_DESIGN_DOC.md` — **only if reviewing `update-markdown-uml`**

## Scope

Review the following for `$PLUGIN_NAME`:
- `packages/$PLUGIN_NAME/src/` — all source files
- `packages/$PLUGIN_NAME/tests/` — all test files
- `packages/$PLUGIN_NAME/README.md` and any `CONTRIBUTING.md`
- `packages/$PLUGIN_NAME/package.json`
- `packages/$PLUGIN_NAME/tsconfig.json`
- `packages/$PLUGIN_NAME/vitest.config.ts` (if present)
- `.github/workflows/` — all workflow files (if not already reviewed in tooling-core pass)

Do not review `dist/`, `node_modules/`, or lockfiles.

---

## Run three parallel sub-reviews

Spawn three subagents. Each receives:
- The scoped files listed above
- `javascript/docs/DESIGN-PRINCIPLES.md`
- `javascript/CLI-BEHAVIOR.md`
- `javascript/TECH-STACK.md`
- `packages/tooling-core/_REVIEW_CONTEXT.md`
- `packages/update-markdown-uml/_DESIGN_DOC.md` (Subagent 2 only, and only if reviewing `update-markdown-uml`)

Each subagent writes its findings independently. Do not share findings between
subagents until all three are complete.

---

### Subagent 1 — Security

Scan: source files, test files, fixtures, config files, workflow files.

Focus exclusively on:
- Hardcoded secrets, tokens, API keys, or credentials anywhere in source or fixtures
- Auth material committed to git
- GitHub Actions workflow files: secrets exposure, untrusted input, token scopes
- npm publish configuration (`package.json`): anything that could leak private tokens
- Any file paths or URLs in fixtures that reveal internal infrastructure
- Cross-reference: does this plugin repeat any security issue flagged in
  `tooling-core/_REVIEW_CONTEXT.md` → Known Issues?

Output format:
```
## Security Findings — $PLUGIN_NAME

### Critical
- <finding>: <file>:<line> — <explanation>

### Warning
- <finding>: <file>:<line> — <explanation>

### Info
- <finding>: <file>:<line> — <explanation>

### Inherited risk from tooling-core
- <description> — (source: tooling-core/_REVIEW_CONTEXT.md → Known Issues)

### Clean
(list areas explicitly checked and found clean)
```

---

### Subagent 2 — Docs vs Implementation Conformance

Scan: source files, test files, README, CONTRIBUTING.md, DESIGN-PRINCIPLES.md, CLI-BEHAVIOR.md,
TECH-STACK.md, and `_DESIGN_DOC.md` if reviewing `update-markdown-uml`.

Read `javascript/docs/DESIGN-PRINCIPLES.md`, `javascript/CLI-BEHAVIOR.md`,
`javascript/TECH-STACK.md`, and `tooling-core/_REVIEW_CONTEXT.md` first as baseline
references. If reviewing `update-markdown-uml`, also read
`packages/update-markdown-uml/_DESIGN_DOC.md`.
Then read the README and JSDoc/TSDoc. Then read implementation and tests.

Tests are evidence of intended behavior — if a test asserts X but README claims Y,
that is a conformance gap.

Identify gaps where:
- Plugin docs describe behavior that differs from implementation
- Exported CLI flags/options are undocumented or mis-documented
- Plugin misrepresents how it uses `tooling-core` APIs (e.g., wrong default for
  `validateExternalLinks`, wrong `onDebug` usage) — use Key Contracts as reference
- Type signatures in docs differ from actual TypeScript types
- Examples in docs would fail against current implementation
- Tests reveal behavior that contradicts README claims
- Implementation violates a principle stated in `DESIGN-PRINCIPLES.md`
- CLI behavior violates a convention stated in `CLI-BEHAVIOR.md` (flag naming, exit codes, output format)
- Actual dependencies or test runner in `package.json` / config files contradict what `TECH-STACK.md`
  claims for this package — check both directions: does impl match the claim, and if this is a
  newer package, is it using Vitest as prescribed for new packages?
- (`update-markdown-uml` only) Implementation diverges from `_DESIGN_DOC.md` intent

Pay special attention to (plugin-specific):
- `update-markdown-toc`: heading extraction logic, TOC insertion markers, idempotency
- `nx-graph-to-mermaid`: graph traversal output, `validateExternalLinks` default (must be `false`)
- `update-markdown-uml`: ts-morph class/package diagram output, `_PACKAGE_INFO.md` convention,
  `micromatch` exclusion patterns

Output format:
```
## Docs vs Implementation Findings — $PLUGIN_NAME

### Gaps (doc claims X, impl does Y)
- <symbol>: <file> — <explanation>

### Test-revealed behavior contradicting docs
- <description>: <test file>:<line> — <explanation>

### tooling-core usage mismatches
- <description>: <file> — (reference: tooling-core/_REVIEW_CONTEXT.md → <section>)

### DESIGN-PRINCIPLES violations
- <principle>: <file> — <explanation>

### CLI-BEHAVIOR violations
- <convention>: <file> — <explanation>

### TECH-STACK violations
- <claim>: <file> — <explanation (e.g. package.json uses Jest but TECH-STACK.md says Vitest for this package)>

### _DESIGN_DOC divergence (update-markdown-uml only)
- <description>: <file> — <explanation>

### Undocumented exports
- <symbol>: <file> — <explanation>

### In sync
(list symbols explicitly verified as matching)
```

---

### Subagent 3 — DRY / Refactor Opportunities

Scan: source files only. Do NOT scan test files for this subagent.

Use `tooling-core/_REVIEW_CONTEXT.md` → Canonical Patterns as the reference for
what correct patterns look like. Flag deviations.

Focus on:
- Does this plugin implement anything that already exists in `tooling-core`?
  (option parsing, link validation, debug callbacks, file processing loops)
- Are `PluginDescriptor` / `runCli` / `FileProcessor` used consistently with
  canonical patterns?
- Inconsistent error handling vs. the canonical pattern
- Any `ts-morph` usage (uml plugin) that reimplements something extractable

Do NOT suggest speculative improvements. Only flag concrete duplication or
deviation from canonical patterns.

Output format:
```
## DRY / Refactor Findings — $PLUGIN_NAME

### Reimplements tooling-core functionality
- <description>: <file(s)> — (canonical location: <tooling-core file>)

### Deviates from canonical pattern
- <description>: <file(s)> — (expected: tooling-core/_REVIEW_CONTEXT.md → Canonical Patterns)

### Internal duplication
- <description>: <file(s)> — <suggested consolidation>
```

---

## After all three subagents complete

Synthesize findings into a final report with three sections (one per subagent).
Then write a compressed context file:

**Write the file `packages/$PLUGIN_NAME/_REVIEW_CONTEXT.md`** with this structure:

```markdown
# $PLUGIN_NAME Review Context
<!-- Generated by code review chain. Input for autogen-markdown-doc review. -->

## Plugin Contract
<!-- What this plugin does, its CLI surface, key options, and any non-obvious
     behavioral contracts discovered during review. -->

## Known Issues
<!-- Security or correctness issues found. -->

## Canonical Pattern Conformance
<!-- Does this plugin conform to tooling-core patterns? Note any deviations. -->

## Doc Gaps
<!-- Areas where plugin docs are absent or wrong. -->

## DESIGN-PRINCIPLES Conformance
<!-- Which principles are well-honored, which have gaps. -->

## CLI-BEHAVIOR Conformance
<!-- Which CLI conventions are honored, which deviate. -->
```

Keep `_REVIEW_CONTEXT.md` under 300 lines. Compress aggressively.

**Also write the file `packages/$PLUGIN_NAME/_REVIEW_REPORT.md`** with the full
human-readable findings. Start the file with:

```markdown
# Code Review Report: packages/$PLUGIN_NAME
<!-- Generated by review-plugin.md -->

## Security Findings
...

## Docs vs Implementation Findings
...

## DRY / Refactor Findings
...
```

No line limit. Include all findings with full file paths and line numbers.
This is the artifact a human reads; do not compress it.

[![No US Tax$ 4 genocide](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
