# update-readme-toc

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
  --check     <path-to-file-or-folder>   Do not write files; exit non-zero if TOC is stale
  --recursive <path-to-folder>           Recursively process all .md files under the given folder
  -q, --quiet                            Suppress per-file output
  -h, --help                             Show this help message and exit
```

## TOC Markers

The tool operates only on files containing **both** markers:

```md
<!-- TOC:START -->
- [update-readme-toc](#update-readme-toc)
  - [Introduction](#introduction)
  - [Installation](#installation)
  - [Usage](#usage)
  - [TOC Markers](#toc-markers)
  - [Usage Scenarios](#usage-scenarios)
    - [As Part of code/test/debug Work Flow](#as-part-of-codetestdebug-work-flow)
    - [Continuous Integration  (CI)](#continuous-integration--ci)
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

