# @doikayt/update-markdown-toc

<p align="center">
  <img
    src="doc/demo.gif"
    width="720"
    alt="update-markdown-toc demo">
</p>



<!-- TOC:START -->
- [@doikayt/update-markdown-toc](#doikaytupdate-markdown-toc)
  - [Introduction](#introduction)
  - [Why not Some Other Markdown TOC Generator ?](#why-not-some-other-markdown-toc-generator-)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Using npx (recommended)](#using-npx-recommended)
    - [Using npm scripts](#using-npm-scripts)
    - [Using a direct path (advanced)](#using-a-direct-path-advanced)
  - [Options](#options)
    - [Configurable Exclusion List for Recursive Traversal](#configurable-exclusion-list-for-recursive-traversal)
      - [Examples:](#examples)
  - [TOC Markers](#toc-markers)
  - [Usage Scenarios](#usage-scenarios)
    - [As Part of code/test/debug Work Flow](#as-part-of-codetestdebug-work-flow)
    - [Continuous Integration](#continuous-integration)
      - [Link Validation in Check Mode](#link-validation-in-check-mode)
    - [Recursively Traversing a Folder Hierarchy to Process all files vs. Single File Processing](#recursively-traversing-a-folder-hierarchy-to-process-all-files-vs-single-file-processing)
      - [Single-File Processing (Strict Mode)](#single-file-processing-strict-mode)
      - [Recursive Folder Traversal (Lenient Mode)](#recursive-folder-traversal-lenient-mode)
  - [Design Goals and Philosophy](#design-goals-and-philosophy)
  - [Packaging, Publishing, and Inter-relationship with Other Plugins](#packaging-publishing-and-inter-relationship-with-other-plugins)
  - [Heading Extraction Behavior](#heading-extraction-behavior)
    - [Code fences are excluded](#code-fences-are-excluded)
    - [Only ATX-style headings are included](#only-atx-style-headings-are-included)
    - [Inline code spans are stripped before marker detection](#inline-code-spans-are-stripped-before-marker-detection)
  - [Known Limitations](#known-limitations)
  - [Contributing and Releasing](#contributing-and-releasing)
<!-- TOC:END -->


## Introduction

A Node.js command-line **documentation helper** which automatically:

- generates Table of Contents (TOC) blocks for Markdown files (using GitHub's Markdown renderer)
- operates on either a single file, or recursively finds all `*.md` files from a root path
- regenerates TOCs from headings, targeting only regions explicitly marked with [TOC markers](#toc-markers)
- avoids gratuitous reformatting or changes of any kind outside of regions marked by the aforementioned [TOC markers](#toc-markers)
- avoids updating files when the generated TOC is already correct
- provides a `--check` mode which flags Markdown files with stale TOCs (intended for CI)
  - validates intra-document links (i.e., those between Markdown docs in the repo (including #fragments, image paths) 
  - validates external HTTP/HTTPS links, with configurable timeout 


## Why not Some Other Markdown TOC Generator ?

Most Markdown TOC tools  (e.g., [markdown-toc](https://github.com/jonschlinkert/markdown-toc), 
[md-toc-cli](https://github.com/eugene-khyst/md-toc-cli))
operate on a single file at a time, a mode which we also support.
The primary distinguishing feature of our tool is its ability to recursively search for, check, and update all Markdown documents within an entire folder hierarchy, making it suitable for CI and 
large repositories.



## Installation

Install as a development dependency (recommended):


```bash
npm install --save-dev @doikayt/update-markdown-toc
```

This installs the update-markdown-toc command into your project’s
node_modules/.bin/ directory.



## Usage


After installation, the `update-markdown-toc` command can be invoked in any
of the following ways from the project root (or a subdirectory) where the package was installed.
All examples below invoke the tool with the default README.md file as the TOC update target.


### Using npx (recommended)

```bash
npx update-markdown-toc 
````


### Using npm scripts

You may also add a script entry to your package.json:

```json
{
  "scripts": {
    "docs:toc": "update-markdown-toc"
  }
}
```
Then run:

```bash
npm run docs:toc
```

### Using a direct path (advanced)

```bash
./node_modules/.bin/update-markdown-toc 
```



## Options

This section assumes the command is invoked using `npx`, an npm script,
or another method that resolves the local `update-markdown-toc` binary.


```text
update-markdown-toc [options] [file]

Options:
  -c, --check                               Do not write files; exit non-zero if TOC is stale
  -n, --no-external-link-check              Skip external HTTP/HTTPS link validation during --check
  -l, --link-timeout-ms <ms>                Per-request timeout for external link checks (default: 3000)
  -r, --recursive <path-to-folder>          Recursively process all .md files under the given folder
  -e, --exclude   <dir1,dir2,...>           Directory names to exclude during recursive traversal (overrides default)
  -v, --verbose                             Print status for every file processed
  -q, --quiet                               Suppress all non-error output
  -d, --debug                               Print debug diagnostics to stderr
  -h, --help                                Show this help message and exit
```

When using `--check`, if no file is specified, the tool defaults to `README.md`
in the current working directory. This means the following two commands are equivalent:

```bash
npx update-markdown-toc --check
npx update-markdown-toc --check README.md
````

To check an entire documentation tree in CI, use `--check --recursive <path>.`



### Configurable Exclusion List for Recursive Traversal

The `--exclude` option only applies when `--recursive` is specified.
It accepts a comma-separated list of directory names (exact match, not glob patterns), and 
when provided, it replaces the default exclusion list.

By default, the recursive traversal excludes only: `node_modules`.

#### Examples:

Exclude node_modules and dist:

```bash 
npx update-markdown-toc --recursive . --exclude node_modules,dist
```

Exclude only dist (this allows traversal into node_modules):

```bash 
npx update-markdown-toc --recursive . --exclude dist
```

Disable exclusions entirely:

```bash 
npx update-markdown-toc --recursive . --exclude ""
```





## TOC Markers

The tool operates only on files containing **both** start and end markers,
as shown below:  


&nbsp;&nbsp;&nbsp;   &lt;!-- TOC:START --&gt;<br/>
&nbsp;&nbsp;&nbsp;   &lt;!-- TOC:END --&gt;



Any existing content between the region start and end markers is lost. The new content will be the generated TOC that
reflects the section headers marked with '#'s in the Markdown document.

Content outside the markers is preserved verbatim.
If either marker is missing, the tool prints an error message and exits with a non-zero status code.


## Usage Scenarios 



### As Part of code/test/debug Work Flow  

To ensure that your code is built afresh, passes tests, and that your documentation TOCs are up to date, you could 
invoke the tool via something akin to the package.json below. 
Before commit and push, you would type:  'npm run build' 


Your `package.json` might look like this:
```json
{
  "scripts": {
    "clean": "rm -rf dist",
    "compile": "tsc -p tsconfig.json",
    "pretest": "npm run compile",
    "test": "vitest run",
    "docs:toc": "update-markdown-toc --recursive docs/",
    "build": "npm run docs:toc && npm run test && npm run compile"
  }
}
```

### Continuous Integration  

The --check flag is designed primarily for continuous integration (CI).

In this mode, the tool:

- never writes files
- compares the existing TOC block against the generated TOC
- exits with a non-zero status if any TOC is stale


Example: 

```bash
npx update-markdown-toc --check --recursive docs/
```

#### Link Validation in Check Mode

When running with `--check`, the tool performs three tiers of link validation in these scopes:
  - table of contents links, 
  - intra-document links, and 
  - external links.

For full details on behavior, failure output, and performance considerations
see [Common CLI Behavior — Check Mode](../CLI-BEHAVIOR.md#6-check-mode---check)


To skip external link validation:
```bash
npx update-markdown-toc --check README.md --no-external-link-check
```


If a pull request modifies documentation headings but forgets to update TOCs or other links targeted for 
validation in a particular run, then the above command will fail the build, 
forcing the contributor to regenerate and commit with corrected TOC and other links.

### Recursively Traversing a Folder Hierarchy to Process all files vs. Single File Processing

The tool supports two distinct operating modes with intentionally different error-handling semantics:

- Single-file mode (--recursive not specified)
- Recursive folder traversal mode (--recursive specified)

These modes are designed to support both strict validation and incremental adoption across real-world repositories.
In the case of the latter mode, we assume some files may not yet have TOC markers, and that this is acceptable.

Refer to [this document](../CLI-BEHAVIOR.md) for information on these processing modes and a discussion of other behavioral 
commonalities that all focused-use plugins in this repository share.

#### Single-File Processing (Strict Mode)


When a single Markdown file is explicitly specified (or when the default README.md is used and --check not specified), 
the tool operates in strict mode.
In this mode, any of the following conditions cause an immediate error and a non-zero exit code:

- file does not exist, or cannot be read (e.g. due to permissions).
- file does not contain both TOC delimiters (&lt;!-- TOC:START --&gt;  and &nbsp; &lt;!-- TOC:END --&gt;).
- file is stale (i.e. the existing TOC differs from the generated TOC). 
- file contains TOC delimiters but no Markdown headings are found from which a TOC can be generated.


If either marker is missing, the tool prints an error message and exits with a non-zero status code.


#### Recursive Folder Traversal (Lenient Mode)

When operating in recursive mode, the tool traverses a directory tree and processes all `*.md` files it finds.

In this mode:

- Files without TOC markers are skipped silently (unless `--verbose` is specified).
- Files with valid TOC markers are processed normally.
- Stale files are reported (unless `--quiet` is specified).
- When running in `--check` mode, stale files cause a non-zero exit code after traversal completes.

Recursive mode is designed for gradual adoption across larger repositories, where not every Markdown file may yet contain TOC markers.
Unlike single-file mode, recursive mode does **not** treat missing TOC markers as an error. This allows incremental rollout of TOC enforcement.

However, structural or filesystem errors are always reported and cause a non-zero exit. These include:

- unreadable files (e.g., permission errors),
- mismatched TOC delimiters,
- malformed TOC marker pairs,
- files containing TOC markers but no Markdown headings.

When such errors occur, the tool prints an error message for each affected file and continues processing the remaining files. All errors are surfaced in a single pass; the process exits non-zero once traversal is complete.

When combined with `--verbose`, skipped files (Markdown files without start/end region markers) are reported explicitly. For example:

```bash
update-markdown-toc --recursive docs/ --verbose
```

yields example output:

```
Skipped (no markers): docs/legacy-notes.md
Updated: docs/guide.md
Up-to-date: docs/api.md
```

## Design Goals and Philosophy

This tool was designed in accordance with the top-level
[Build Philosophy](../../README.md#build-philosophy) of this repository.


- **update mode** (writes files: this should be run locally by developers, and should never run in CI. It is the default if `--check` not specified)
- **check mode** (validates and exits non-zero if stale:  mainly intended to be run in CI -- optional for local use) 

The intended workflow is:

1. Developers run the command locally  in default mode (update mode, a.k.a. non `--check` mode) in their workspace
2. Generated TOC content is reviewed and committed.
3. CI runs in `--check` mode to ensure no drift exists.



## Packaging, Publishing, and Inter-relationship with Other Plugins

This package is one component of a small ecosystem of JavaScript tooling plugins maintained as individual npm packages in this repository.
The versioning and release of these packages is governed by a coordinated release policy, and
the packages adhere to common design and architectural principles policies
that are more completely described [here](../../README.md).

## Heading Extraction Behavior

### Code fences are excluded

Lines inside fenced code blocks are not treated as headings. A `#` character
that appears inside a ` ``` ` block is code, not a heading, and will not appear
in the generated TOC.

If a code fence is opened but never closed, everything from the opening fence
to the end of the document is treated as inside the fence and excluded from
heading extraction. No error is thrown — the headings that appear before the
unclosed fence are still included.

### Only ATX-style headings are included

Only headings written with leading `#` characters (ATX style) are included in
the TOC:

```markdown
## This is included
```

Setext-style headings — a paragraph immediately followed by `---` or `===` on
the next line — are excluded. This avoids accidentally treating a paragraph
followed by a horizontal rule as a heading, which is a common Markdown pattern:

```markdown
A note for users.
---
```

The line above is a paragraph + horizontal rule, not a heading, and will not
appear in the TOC.

### Inline code spans are stripped before marker detection

Before checking for `<!-- TOC:START -->` and `<!-- TOC:END -->` markers, the
document is preprocessed to remove inline code spans. This means a marker
written inside backticks is treated as literal text and will not trigger marker
detection:

```markdown
Use `<!-- TOC:START -->` and `<!-- TOC:END -->` as delimiters.
```

The above line is documentation about the markers, not the markers themselves.
Only bare (unquoted) marker strings activate the TOC region.

## Known Limitations

**Fragment link validation with formatted headings**

Fragment link validation uses AST-based heading extraction, which may produce
different slugs than the TOC generator for headings containing inline formatting
such as code spans or bold text (e.g. `## Install \`foo\``).

In practice this affects only headings with inline code, bold, or italic syntax.
Plain-text headings are unaffected. A fix to unify both paths is planned for a
future release.


## Contributing and Releasing

For code overview, development setup, build workflow, and release procedures (including how to
trigger a publish via Changesets), see
[CONTRIBUTING.md](./docs/CONTRIBUTING.md).



[![Free Palestine!](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
