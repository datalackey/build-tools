# Code Review: autogen-markdown-doc

You are performing a structured code review of the `autogen-markdown-doc` package
in the `build-tools` monorepo under the `@doikayt` npm scope.

This is the uber-plugin that orchestrates the sibling plugins. Its review is
informed by the full review chain output from all dependencies.

## Prerequisites

Before starting, read ALL of the following in order:

1. `javascript/docs/DESIGN-PRINCIPLES.md` — monorepo-wide design intent
2. `javascript/CLI-BEHAVIOR.md` — expected CLI conventions (flag naming, exit codes, output format)
3. `javascript/TECH-STACK.md` — declared technology choices per package (deps, test runners, build tools)
4. `packages/tooling-core/_REVIEW_CONTEXT.md`
5. `packages/update-markdown-toc/_REVIEW_CONTEXT.md`
6. `packages/nx-graph-to-mermaid/_REVIEW_CONTEXT.md`
7. `packages/update-markdown-uml/_REVIEW_CONTEXT.md`

## Scope

Review the following for `autogen-markdown-doc`:
- `packages/autogen-markdown-doc/src/` — all source files
- `packages/autogen-markdown-doc/tests/` — all test files
- `packages/autogen-markdown-doc/README.md` and any `CONTRIBUTING.md`
- `packages/autogen-markdown-doc/package.json`
- `packages/autogen-markdown-doc/tsconfig.json`
- `packages/autogen-markdown-doc/vitest.config.ts` (if present)
- `.github/workflows/` — all workflow files (if not already reviewed in prior passes)

Do not review `dist/`, `node_modules/`, or lockfiles.

---

## Run three parallel sub-reviews

Spawn three subagents. Each receives:
- The scoped files listed above
- `javascript/docs/DESIGN-PRINCIPLES.md`
- `javascript/CLI-BEHAVIOR.md`
- `javascript/TECH-STACK.md`
- All four `_REVIEW_CONTEXT.md` files listed in Prerequisites

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
- Plugin orchestration surface: does it pass untrusted CLI args into child plugin
  invocations unsanitized?
- Cross-reference: does `autogen-markdown-doc` propagate or amplify any security
  issue flagged in the dependency `_REVIEW_CONTEXT.md` → Known Issues files?

Output format:
```
## Security Findings — autogen-markdown-doc

### Critical
- <finding>: <file>:<line> — <explanation>

### Warning
- <finding>: <file>:<line> — <explanation>

### Info
- <finding>: <file>:<line> — <explanation>

### Inherited / propagated risks from dependencies
- <description> — (source: <dependency>/_REVIEW_CONTEXT.md → Known Issues)

### Clean
(list areas explicitly checked and found clean)
```

---

### Subagent 2 — Docs vs Implementation Conformance

Scan: source files, test files, README, CONTRIBUTING.md, DESIGN-PRINCIPLES.md, CLI-BEHAVIOR.md, TECH-STACK.md.

Read `javascript/docs/DESIGN-PRINCIPLES.md`, `javascript/CLI-BEHAVIOR.md`,
`javascript/TECH-STACK.md`, and all four `_REVIEW_CONTEXT.md` files
first. Then read the README and JSDoc/TSDoc. Then read implementation and tests.

Tests are evidence of intended behavior — if a test asserts X but README claims Y,
that is a conformance gap.

Identify gaps where:
- The uber-plugin's docs promise behavior that differs from what the implementation
  actually does when delegating to child plugins
- The orchestration order documented does not match the actual invocation order
- Any child plugin's known doc gaps (from `_REVIEW_CONTEXT.md`) surface as
  misleading claims in `autogen-markdown-doc`'s own docs
- CLI flags passed through to child plugins are undocumented or mis-documented
- Examples in docs would fail against current implementation
- Tests reveal behavior that contradicts README claims
- Implementation violates a principle stated in `DESIGN-PRINCIPLES.md`
- CLI behavior violates a convention stated in `CLI-BEHAVIOR.md` (flag naming, exit codes, output format)
- Actual dependencies or test runner in `package.json` / config files contradict what `TECH-STACK.md`
  claims for this package

Output format:
```
## Docs vs Implementation Findings — autogen-markdown-doc

### Gaps (doc claims X, impl does Y)
- <symbol>: <file> — <explanation>

### Orchestration order mismatch
- <description>: <file> — <explanation>

### Test-revealed behavior contradicting docs
- <description>: <test file>:<line> — <explanation>

### Inherited doc gaps surfacing here
- <description> — (source: <dependency>/_REVIEW_CONTEXT.md → Doc Gaps)

### Undocumented passthrough flags
- <flag>: <file> — <explanation>

### DESIGN-PRINCIPLES violations
- <principle>: <file> — <explanation>

### CLI-BEHAVIOR violations
- <convention>: <file> — <explanation>

### TECH-STACK violations
- <claim>: <file> — <explanation>

### In sync
(list areas explicitly verified as matching)
```

---

### Subagent 3 — DRY / Refactor Opportunities

Scan: source files only. Do NOT scan test files for this subagent.

Use all four `_REVIEW_CONTEXT.md` → Canonical Patterns and Canonical Pattern
Conformance sections as the reference baseline.

Focus on:
- Does `autogen-markdown-doc` re-implement orchestration logic that could live
  in `tooling-core`?
- Are child plugins invoked in a consistent pattern, or does each get
  slightly different treatment?
- Does the uber-plugin duplicate option parsing that each child already does?
- Is there an abstraction for "run these plugins in sequence" that is
  partially implemented and could be generalized?

Do NOT suggest speculative improvements. Only flag concrete duplication or
deviation from patterns established in the dependency chain.

Output format:
```
## DRY / Refactor Findings — autogen-markdown-doc

### Reimplements dependency functionality
- <description>: <file(s)> — (canonical location: <package>/<file>)

### Inconsistent child plugin invocation
- <description>: <file(s)> — (expected: tooling-core/_REVIEW_CONTEXT.md → Canonical Patterns)

### Internal duplication
- <description>: <file(s)> — <suggested consolidation>
```

---

## After all three subagents complete

Synthesize findings into a final report with three sections (one per subagent).

This is the terminal node of the review chain — no `_REVIEW_CONTEXT.md` output
is needed. Instead, write a single summary file:

**Write `_REVIEW_CHAIN_SUMMARY.md` to the monorepo root** with this structure:

```markdown
# build-tools Review Chain Summary

## Cross-cutting Security Issues
<!-- Issues that appear in multiple packages or propagate across the dependency chain -->

## Cross-cutting Doc Gaps
<!-- Doc gaps that appear consistently across packages — may indicate a systemic
     documentation process gap rather than per-package oversight -->

## DESIGN-PRINCIPLES Conformance Summary
<!-- Which principles are consistently honored across the codebase, which have gaps -->

## CLI-BEHAVIOR Conformance Summary
<!-- Which CLI conventions are consistently honored, which deviate across plugins -->

## TECH-STACK Conformance Summary
<!-- Which packages match their TECH-STACK.md declarations; flag any drift (wrong test runner,
     undeclared deps, packages that should have migrated to Vitest but haven't) -->

## Cross-cutting Refactor Opportunities
<!-- Patterns that, if consolidated into tooling-core, would clean up 2+ plugins -->

## Per-package Highlights
<!-- One paragraph per package: most important finding only -->

## Recommended Action Order
<!-- Prioritized list: what to fix first and why -->
```

**Also write the file `packages/autogen-markdown-doc/_REVIEW_REPORT.md`** with the full
human-readable findings for this package. Start the file with:

```markdown
# Code Review Report: packages/autogen-markdown-doc
<!-- Generated by review-autogen.md -->

## Security Findings
...

## Docs vs Implementation Findings
...

## DRY / Refactor Findings
...
```

No line limit. Include all findings with full file paths and line numbers.
This is the artifact a human reads; do not compress it.

[![Remember the USS Liberty!](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
