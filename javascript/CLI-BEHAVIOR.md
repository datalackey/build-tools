<!-- TOC:START -->
- [Common CLI Behavior](#common-cli-behavior)
- [1. Processing Modes](#1-processing-modes)
  - [Single-File Mode](#single-file-mode)
  - [Recursive Mode](#recursive-mode)
- [2. Status Types](#2-status-types)
    - [Updated](#updated)
    - [Up-to-date](#up-to-date)
    - [Needs-update](#needs-update)
    - [Skipped](#skipped)
- [3. Default Output Behavior](#3-default-output-behavior)
- [4. Verbose Mode (`--verbose`)](#4-verbose-mode---verbose)
- [5. Quiet Mode (`--quiet`)](#5-quiet-mode---quiet)
- [5a. Debug Mode (`--debug`)](#5a-debug-mode---debug)
  - [6. Check Mode (`--check`)](#6-check-mode---check)
    - [TOC Validation](#toc-validation)
    - [Intra-document Link Validation](#intra-document-link-validation)
    - [External Link Validation](#external-link-validation)
    - [Exit Behavior](#exit-behavior)
- [7. Exit Codes](#7-exit-codes)
- [8. Error Behavior](#8-error-behavior)
- [9. Deterministic Processing](#9-deterministic-processing)
- [Passing CLI flags when invoking via NX](#passing-cli-flags-when-invoking-via-nx)
<!-- TOC:END -->

# Common CLI Behavior

This document describes the shared command-line behavior used by repository-processing tools in this workspace.

For example, the following commands use:

```
npx @doikayt/update-markdown-toc
```

Other tools follow the same behavior patterns. The one exception is 
[`autogen-markdown-doc`](./autogen-markdown-doc/README.md), which bundles
capabilities of all the more focused use plugins, and provides a simplified CLI and options to accomodate 
the most common use cases.



---

# 1. Processing Modes

Tools operate in one of two modes.

## Single-File Mode

A single file is specified.

Example:

```
npx @doikayt/update-markdown-toc README.md
```

In this mode:

- Only that file is processed.
- Errors stop execution immediately.
- No summary line is printed.


## Recursive Mode

A directory is specified using `--recursive`.

Example:

```
npx @doikayt/update-markdown-toc --recursive docs/
```

In this mode:

- All matching files under the directory are processed.
- Files are processed in deterministic (path-sorted) order.
- Files that do not contain required markers are skipped.
- Structural errors stop the run immediately.


---

# 2. Status Types

Each processed file falls into one of four categories.

### Updated

The file was modified.

Example output:

```
Updated: docs/guide.md
```

### Up-to-date

The file already contained the correct content.

Example output:

```
Up-to-date: docs/api.md
```

### Needs-update

The file would be modified, but the tool is running in `--check` mode.

Example output:

```
Needs update: docs/guide.md
```

### Skipped

The file does not contain required markers and is ignored (recursive mode only).

Example output:

```
Skipped (no markers): docs/notes.md
```


---

# 3. Default Output Behavior

Without any flags:

- Only `Updated:` lines are printed.
- Files that are already correct are not printed.
- Skipped files are not printed.
- No summary is printed.


---

# 4. Verbose Mode (`--verbose`)

When `--verbose` is used:

- All file statuses are printed:
    - Updated
    - Up-to-date
    - Needs update
    - Skipped

In recursive mode, a summary line is printed at the end:

```
Summary: 3 updated, 1 needs update, 2 unchanged, 4 skipped
```

The summary appears only in recursive mode and only when `--verbose` is enabled.

Single-file mode does not print a summary.


---

# 5. Quiet Mode (`--quiet`)

When `--quiet` is used:

- No output is printed.
- Exit codes still reflect success or failure.


---

# 5a. Debug Mode (`--debug`)

When `--debug` is used:

- Diagnostic messages are written to `stderr`.
- Each internal logging message is prefixed with `[debug]`.
- Normal stdout output is unaffected.
- Intended for development and troubleshooting only -- orthogonal to `--quiet` and `--verbose`

---

## 6. Check Mode (`--check`)

When `--check` is specified:

- Files are not modified.
- Files that would change are reported as `Needs update`.
- The tool exits with a non-zero status if any file is needs update.

For tools that support link validation, `--check` performs three tiers of validation
in order:

### TOC Validation

Verifies that the auto-generated TOC block is up to date with the document's
headings. This is the baseline `--check` behavior. If the TOC is needs update the file
is reported as `Needs update` and the run exits non-zero. Link validation continues to run
even if TOC validation fails.

### Intra-document Link Validation

Verifies links in the authored body of the file — outside the TOC block. Covers:

- relative file links (e.g. `[x](./other-doc.md)`)
- relative links with anchors (e.g. `[x](./other-doc.md#install)`)
- fragment-only same-file links (e.g. `[x](#install)`)
- image paths (e.g. `![diagram](./diagram.png)`)

Links using `mailto:`, `tel:`, `data:`, or `javascript:` schemes are ignored.

### External Link Validation

Verifies HTTP/HTTPS links by making outbound requests. Runs after intra-document
validation.

Each request is subject to a per-request timeout (default: 3000ms), configurable
via `--link-timeout-ms`. If a request exceeds the timeout it is reported as a
failure.

Note: in this release, each external URL is requested independently with no
response caching. In repositories with many external links, or where the same
URL appears multiple times, this may noticeably slow down a `--check` run.
Per-run caching is planned for a subsequent release. In the meantime,
`--no-external-link-check` is available to skip this tier entirely in
time-sensitive CI environments.

To disable external link validation entirely use `--no-external-link-check`.

### Exit Behavior

- Exit code `0` → no changes required, no broken links.
- Exit code `1` → at least one file is needs update, or at least one broken link found.
- Non-zero exit codes also occur for structural errors.

---

# 7. Exit Codes

Exit codes are consistent across tools:

- `0` → success, no issues
- `1` → needs update files detected in `--check` mode
- Non-zero → structural or fatal error


---

# 8. Error Behavior

Structural errors stop execution immediately.

Examples include:

- unreadable files
- malformed marker regions
- mismatched delimiters
- invalid structure

Errors are printed in the format:

```
ERROR: <description>
```

In recursive mode, skipped files do not cause failure.


---

# 9. Deterministic Processing

Recursive traversal is deterministic:

- Files are processed in path-sorted order.
- `node_modules` directories are ignored by default.
- Only supported file extensions are processed.


# Passing CLI flags when invoking via NX

When invoking the tool through an NX target, flags like `--help` are consumed
by NX before reaching the script. Use `--args` to pass them through:
```bash
npx nx run build-tools-workspace:update:toc --args="--help"
```

This applies to any CLI flag intended for the tool itself rather than NX.

[![Free Palestine!](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
