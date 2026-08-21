# Code Review: tooling-core

You are performing a structured code review of the `tooling-core` package in the
`build-tools` monorepo under the `@doikayt` npm scope.

## Prerequisites

Before starting, read the following from the monorepo root:
- `javascript/docs/DESIGN-PRINCIPLES.md` — monorepo-wide design intent
- `javascript/CLI-BEHAVIOR.md` — expected CLI conventions (flag naming, exit codes, output format)
- `javascript/TECH-STACK.md` — declared technology choices per package (deps, test runners, build tools)

Subagent 2 will verify conformance against all three.

## Scope

Review the following for `tooling-core`:
- `packages/tooling-core/src/` — all source files
- `packages/tooling-core/tests/` — all test files
- `packages/tooling-core/README.md` and any `CONTRIBUTING.md`
- `packages/tooling-core/package.json`
- `packages/tooling-core/tsconfig.json`
- `packages/tooling-core/vitest.config.ts` (if present)
- `.github/workflows/` — all workflow files
- `nx.json` (monorepo root)

Do not review `dist/`, `node_modules/`, or lockfiles.

---

## Run three parallel sub-reviews

Spawn three subagents. Each receives the same files as context.
Each subagent writes its findings independently. Do not let subagents share
findings until all three are complete.

---

### Subagent 1 — Security

Scan: source files, test files, fixtures, config files, workflow files.

Focus exclusively on:
- Hardcoded secrets, tokens, API keys, or credentials anywhere in source or test fixtures
- Auth material committed to git (check `.npmrc` references, env var usage)
- GitHub Actions workflow files: secrets exposure, untrusted input injection, overly
  broad token scopes
- npm publish configuration (`package.json`): anything that could leak private tokens
- Any file paths or URLs in fixtures that reveal internal infrastructure
- `tsconfig.json` / `package.json`: misconfiguration that could expose internals at publish time

Output format:
```
## Security Findings

### Critical
- <finding>: <file>:<line> — <explanation>

### Warning
- <finding>: <file>:<line> — <explanation>

### Info
- <finding>: <file>:<line> — <explanation>

### Clean
(list areas explicitly checked and found clean)
```

---

### Subagent 2 — Docs vs Implementation Conformance

Scan: source files, test files, README, CONTRIBUTING.md, DESIGN-PRINCIPLES.md, CLI-BEHAVIOR.md, TECH-STACK.md.

Read `javascript/docs/DESIGN-PRINCIPLES.md`, `javascript/CLI-BEHAVIOR.md`, and
`javascript/TECH-STACK.md` first. Then read the README and any
JSDoc/TSDoc. Then read the implementation and tests.

Tests are evidence of intended behavior — if a test asserts X but README claims Y,
that is a conformance gap.

Identify gaps where:
- A function/export is documented but behaves differently than described
- A function/export exists in source but is absent from docs
- A CLI flag or option is documented but not implemented (or vice versa)
- Type signatures in docs differ from actual TypeScript types
- Examples in docs would fail against current implementation
- Tests reveal behavior that contradicts README claims
- Implementation violates a principle stated in `DESIGN-PRINCIPLES.md`
- CLI behavior violates a convention stated in `CLI-BEHAVIOR.md` (flag naming, exit codes, output format)
- Actual dependencies or test runner in `package.json` / config files contradict what `TECH-STACK.md`
  claims for this package (e.g. wrong test runner, undeclared dep, deprecated tool still in use)

Pay special attention to:
- `PluginDescriptor` interface contract
- `runCli` function signature and options
- `FileProcessor` pattern
- `onDebug` callback contract
- `validateExternalLinks` default value

Output format:
```
## Docs vs Implementation Findings

### Gaps (doc claims X, impl does Y)
- <symbol>: <file> — <explanation>

### Test-revealed behavior contradicting docs
- <description>: <test file>:<line> — <explanation>

### DESIGN-PRINCIPLES violations
- <principle>: <file> — <explanation>

### CLI-BEHAVIOR violations
- <convention>: <file> — <explanation>

### TECH-STACK violations
- <claim>: <file> — <explanation (e.g. package.json uses Jest but TECH-STACK.md says Vitest)>

### Undocumented exports
- <symbol>: <file> — <explanation>

### Docs absent entirely
- <area> — no documentation found

### In sync
(list symbols explicitly verified as matching)
```

---

### Subagent 3 — DRY / Refactor Opportunities

Scan: source files only. Do NOT scan test files for this subagent.

Focus on:
- Repeated logic patterns within `tooling-core` itself
- Abstractions that are partially applied (started but not completed)
- Any utility that is reimplemented elsewhere rather than imported from here
- Error handling patterns that are inconsistent
- Option parsing patterns that could be generalized

Do NOT suggest speculative improvements. Only flag concrete duplication or
inconsistency visible in the current source code.

Output format:
```
## DRY / Refactor Findings

### Concrete duplication
- <description>: <file(s)> — <suggested consolidation>

### Inconsistent patterns
- <description>: <file(s)> — <explanation>

### Partial abstractions
- <description>: <file> — <explanation>
```

---

## After all three subagents complete

Synthesize findings into a final report with three sections (one per subagent).
Then write a compressed context file as follows:

**Write the file `packages/tooling-core/_REVIEW_CONTEXT.md`** with this structure:

```markdown
# tooling-core Review Context
<!-- Generated by code review chain. Input for dependent plugin reviews. -->

## Key Contracts
<!-- Precise description of PluginDescriptor, runCli, FileProcessor, onDebug signatures
     and any non-obvious behavioral contracts discovered during review. -->

## Known Issues
<!-- Security or correctness issues found. Dependent plugins should be checked
     for the same patterns. -->

## Canonical Patterns
<!-- The correct/intended patterns for option parsing, error handling, debug callbacks,
     link validation defaults. Dependent plugins should conform to these. -->

## Doc Gaps
<!-- Areas where tooling-core docs are absent or wrong — relevant when reviewing
     plugins that reference this package in their own docs. -->

## DESIGN-PRINCIPLES Conformance
<!-- Which principles are well-honored, which have gaps. -->

## CLI-BEHAVIOR Conformance
<!-- Which CLI conventions are honored, which deviate. Relevant for plugins that
     delegate to or wrap tooling-core CLI entry points. -->
```

Keep `_REVIEW_CONTEXT.md` under 400 lines. Compress aggressively — this file is
input context for subsequent reviews, not a human report.

**Also write the file `packages/tooling-core/_REVIEW_REPORT.md`** with the full
human-readable findings. Start the file with:

```markdown
# Code Review Report: packages/tooling-core
<!-- Generated by review-tooling-core.md -->

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
