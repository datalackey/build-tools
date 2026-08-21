# CLAUDE.md — build-tools

## ACTIVE ROLE:  DEV

---

## General guidance for all packages

The following workspace-wide documents are available as reference material regardless of which
package you are working on. Consult them when you need orientation in the relevant area —
they are not required reading for every task.

| Document | Useful for |
|---|---|
| `javascript/docs/CONTRIBUTING.md` | Setup, build process, and day-to-day workflow |
| `javascript/docs/DESIGN-PRINCIPLES.md` | Understanding architectural decisions and their rationale |
| `javascript/docs/DOCS_AS_ARCHITECTURE_REVIEW.md` | How documentation is used as architectural feedback in this project |
| `javascript/CLI-BEHAVIOR.md` | Shared CLI conventions that apply across all tools |
| `javascript/TECH-STACK.md` | Technology choices and why they were made |
| `javascript/README.md` | Package list and workspace overview |

---

## Task routing — per-package files to read

When a task involves a specific package, read the files listed under that package below.
The package is identified by its path prefix (e.g. a file under `javascript/update-markdown-toc/`
belongs to the `update-markdown-toc` package).

### tooling-core (`javascript/tooling-core/`)
> Foundation framework — all other plugins are built on top of this API.

- `javascript/tooling-core/README.md` — plugin authoring API reference
- `javascript/tooling-core/src/index.ts` — public exports; start here for any API question
- `javascript/tooling-core/tests/` — canonical usage examples for all public API surface
- `javascript/tooling-core/docs/CONTRIBUTING.md` — package-level setup and conventions

### update-markdown-toc (`javascript/update-markdown-toc/`)
> Also read: tooling-core (above) — this plugin is built on the tooling-core framework.

- `javascript/update-markdown-toc/README.md` — TOC generator and link validator

### nx-graph-to-mermaid (`javascript/nx-graph-to-mermaid/`)
> Also read: tooling-core (above) — this plugin is built on the tooling-core framework.

- `javascript/nx-graph-to-mermaid/README.md` — NX executor modes and project.json patterns

### update-markdown-uml (`javascript/update-markdown-uml/`)
> Also read: tooling-core (above) — this plugin is built on the tooling-core framework.

- `javascript/update-markdown-uml/README.md` — UML diagram generator (in development)
- `javascript/update-markdown-uml/_DESIGN_DOC.md` — design document (in development)

### autogen-markdown-doc (`javascript/autogen-markdown-doc/`)
> Uber-bundle: aggregates all other plugins with opinionated defaults.
> Also read: tooling-core + all plugin READMEs above, since this package delegates to each.

- `javascript/autogen-markdown-doc/README.md` — entry point and opinionated defaults

### End-to-end examples (user-perspective reference)

Two e2e fixtures document the complete user journey — marker-annotated README in,
generated content out. These are the clearest statement of what the tools actually
produce and are the best first stop when diagnosing any output or behavior issue.

- `javascript/update-markdown-uml/tests/e2e/` — single-plugin scenario: UML markers → mermaid diagrams
  - Fixture (before): `tests/e2e/fixtures/math-cli/README.md`
  - Test: `tests/e2e/math-cli-example.e2e.test.ts`

- `javascript/autogen-markdown-doc/tests/e2e/` — uber-plugin scenario: TOC + NX graph + UML in one pass
  - Fixture (before): `tests/e2e/fixtures/math-cli-nx/README.md`
  - Test: `tests/e2e/math-cli-nx-example.e2e.test.ts`
  - Also exercises each bundled plugin standalone and `--exclude-packages` forwarding

Key insight: UML runs before TOC, so UML-injected headings are already present when TOC
runs — the uber plugin converges in a single pass (no second update needed).

---

## Critical rules (not covered elsewhere)

- **Never use `npm run` at workspace root** — always `npx nx run-many` or `npx nx run <target>`
- **Never run `npm install` inside a package directory** — always run from `javascript/`
- **When adding a new package**, add its `paths` entry to `javascript/tsconfig.eslint.json` immediately or lint will fail
- **Never manually edit version numbers** — Changesets owns all versioning
- **Release workflow is handled manually by the maintainer** — never run changeset commands or bump versions

---

## Before Committing

Run 'npx nx run build-tools-workspace:update-all-format' in workspace route to avoid formatting failures in CI.


## Current work

State the current task in your first message — no need to maintain this section between sessions.

[![Free Palestine!](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
