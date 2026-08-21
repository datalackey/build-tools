<!-- TOC:START -->
- [build-tools](#build-tools)
  - [Design Principles](#design-principles)
    - [UX Philosophy](#ux-philosophy)
    - [Build Philosophy](#build-philosophy)
      - [Release Exception (Version Management)](#release-exception-version-management)
  - [For Project Maintainers](#for-project-maintainers)
<!-- TOC:END -->

# build-tools

This repository contains tooling designed to assist in building and maintaining software projects —
primarily JavaScript/TypeScript projects at this point. The unifying theme of our currently available tools
(described [here](./javascript/README.md#packages)) is automated documentation generation and verification —
keeping documentation structurally correct and synchronized with source artifacts -- without manual effort.

The tools operate on the principle that documentation drift (inconsistency between source artifacts and 
documentation that describes those artifacts) is a build failure, not fodder for a review comment.
Generated content is deterministic, injected into Markdown files at precise locations, targeted by special start/end tags.
Running in `update` mode writes correct documentation, 
running in `check` mode verifies it, and the two are guaranteed to agree.

---

## Design Principles

### UX Philosophy

UX is typically considered to be GUI-related, but here we consider the commands and switches exposed by our 
CLI-based tools to be 'our UI'.  The design of this UI follows the principle of 
[progressive disclosure](https://www.nngroup.com/articles/progressive-disclosure/) —
a well-established UX pattern that surfaces simplicity first, and reveals
complexity only when needed. 

In practice this means:

- The default invocation of any tool should work correctly for the most common use case,
  with no flags or configuration required.
- Advanced options (custom exclusion lists, recursive depth, check-only mode, etc.)
  are available but never forced on the user.
- The `@doikayt/autogen-markdown-doc` package is the clearest expression of
  this principle: it bundles `update-markdown-toc` and `nx-graph-to-mermaid`
  into a single command with opinionated defaults that cover the 80% case:
  single invocation update of all Markdown tables-of-contents and Mermaid build graph anchor points across a repository 

This philosophy is closely related to 
[convention over configuration](https://en.wikipedia.org/wiki/Convention_over_configuration) —
wherein a system works correctly out of the box, and you only configure what deviates from the norm.

---

### Build Philosophy

Core principles:

- Checked-in source code is the source of truth.
- CI validates, tests, and publishes.
- CI does not generate code, does not modify existing logic and does not change any non-version related configuration
  (note: CI *will* bump version numbers as described in the *Release Exception* section below).
- Builds must be reproducible locally -- across developer machines and CI.

#### Release Exception (Version Management)

There is one controlled exception to the "CI does not modify the repository" rule:

Version bumps and changelog updates are managed using [Changesets](https://www.npmjs.com/package/@changesets/cli).

Depending on the release workflow configuration, CI may:

- Generate a version PR containing version bumps and changelog updates, or
- Publish packages after a developer has already committed version changes.

In either case:

- CI never modifies functional source code.
- Only version metadata and changelogs may be updated automatically.
- Release changes are explicit, reviewable, and traceable in Git history.

---

## For Project Maintainers

Please see [this document](CONTRIBUTING.md) for more information.

[![No US Tax$ 4 genocide](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
