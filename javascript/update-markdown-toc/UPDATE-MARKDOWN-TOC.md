# update-readme-toc

- [update-readme-toc](#update-readme-toc)
    - [Introduction](#introduction)
    - [Installation](#installation)
    - [Usage](#usage)
    - [TOC Markers](#toc-markers)
    - [Usage Scenarios](#usage-scenarios)
        - [As Part of code/test/debug Work Flow](#as-part-of-codetestdebug-work-flow)
        - [Continuous Integration  (CI)](#continuous-integration--ci)
        - [Recursively Traversing a Folder Hierarchy to Process all files vs. Single File Processing](#recursively-traversing-a-folder-hierarchy-to-process-all-files-vs-single-file-processing)
            - [Single-File Processing (Strict Mode)](#single-file-processing-strict-mode)
            - [Recursive Folder Traversal (Lenient Mode)](#recursive-folder-traversal-lenient-mode)

## Introduction

A Node.js command-line **documentation helper** which automatically:

- generates Table of Contents (TOC) blocks for Markdown files
- operates on either a single file, or recursively finds all `*.md` files from a root path
- regenerates TOCs from headings, replacing only explicitly marked regions, with no gratuitous reformatting
- avoids updating files when the generated TOC is already correct
- provides a `--check` mode which flags Markdown files with stale TOCs (intended for CI)



## Installation

Install from npm (recommended)

```bash
npm install --save-dev @datalackey/update-readme-toc
```

## Usage

```text
update-readme-toc [options] [file]

Options:
  -c, --check     <path-to-file-or-folder>  Do not write files; exit non-zero if TOC is stale
  -r, --recursive <path-to-folder>          Recursively process all .md files under the given folder
  -v, --verbose                             Print status for every file processed
  -q, --quiet                               Suppress all non-error output
  -h, --help                                Show this help message and exit

```

## TOC Markers

The tool operates only on files containing **both** markers:

```md
<!-- TOC:START -->
<!-- TOC:END -->
```

Any existing content between these markers is lost. The new content will be the generated TOC that
reflects the section headers marked with '#'s in the Markdown document.
 
Content outside the markers is preserved verbatim.


## Usage Scenarios 




### As Part of code/test/debug Work Flow  

Before commit and push, you could, with the package.json below, type:  'npm run build' to ensure that your code is built afresh, it passes tests, and 
that your documentation TOCs are up to date.

Your `package.json` might look like this:
```json
{
  "scripts": {
    "clean": "rm -rf dist"
    "compile": "tsc -p tsconfig.json",
    "pretest": "npm run compile",
    "test": "jest",
    "docs:toc": "update-readme-toc --recursive docs/",
    "bundle": "esbuild src/index.ts --bundle --platform=node --outdir=dist",
    "package": "npm run clean && npm run compile && npm run bundle",
    "build": "npm run docs:toc && npm run test && npm run package"
  }
}
```

### Continuous Integration  (CI)

The --check flag is designed primarily for continuous integration.

In this mode, the tool:

- never writes files
- compares the existing TOC block against the generated TOC
- exits with a non-zero status if any TOC is stale


Example: 

```bash
npx update-readme-toc --check --recursive docs/
```


If a pull request modifies documentation headings but forgets to update TOCs, this command will fail the build, forcing the contributor to regenerate and commit the correct TOC.

### Recursively Traversing a Folder Hierarchy to Process all files vs. Single File Processing

The tool supports two distinct operating modes with intentionally different error-handling semantics:

- Single-file mode (--recursive not specified)
- Recursive folder traversal mode (--recursive specified)

These modes are designed to support both strict validation and incremental adoption across real-world repositories.
In the case of the latter mode, we assume some files may not yet have TOC markers, and that this is acceptable.

#### Single-File Processing (Strict Mode)

When a single Markdown file is explicitly specified (or when the default README.md is used), the tool operates in strict mode.

In this mode:

The file must contain both TOC markers:
```md
<!-- TOC:START -->
<!-- TOC:END -->

```

If either marker is missing, the tool prints an error message and exits with a non-zero status code.


#### Recursive Folder Traversal (Lenient Mode)

When operating in recursive mode, the tool traverses a directory tree and processes all *.md files it finds.
In this mode, files without TOC markers are silently skipped, and files with TOC markers are processed normally.

When combined with --verbose, skipped files are reported explicitly in this mode.

update-readme-toc --recursive docs/ --verbose

Example output:

```
Skipped (no markers): docs/legacy-notes.md
Updated: docs/guide.md
Up-to-date: docs/api.md
```


