#!/usr/bin/env node

import fs from "fs";
import path from "path";
import { parseArgs } from "node:util";
import { dedent } from "ts-dedent";

/* ============================================================
 * Constants
 * ============================================================ */

const START = "<!-- TOC:START -->";
const END = "<!-- TOC:END -->";

/* ============================================================
 * Debug helper
 * ============================================================ */

let debugEnabled = false;

function debug(msg) {
    if (debugEnabled) {
        console.error(`[debug] ${msg}`);
    }
}

/* ============================================================
 * Usage / Help
 * ============================================================ */

function printHelp() {
    console.log(dedent`
    update-readme-toc [options] [file]

    Options:
      -c, --check     <path-to-file-or-folder>  Do not write files; exit non-zero if TOC is stale
      -r, --recursive <path-to-folder>          Recursively process all .md files under the given folder
      -v, --verbose                             Print status for every file processed
      -q, --quiet                               Suppress all non-error output
      -d, --debug                               Print debug diagnostics to stderr
      -h, --help                                Show this help message and exit
  `);
}

/* ============================================================
 * Argument parsing
 * ============================================================ */

let values, positionals;

try {
    ({ values, positionals } = parseArgs({
        options: {
            check:      { type: "boolean", short: "c" },
            recursive:  { type: "string",  short: "r" },
            verbose:    { type: "boolean", short: "v" },
            quiet:      { type: "boolean", short: "q" },
            debug:      { type: "boolean", short: "d" },
            help:       { type: "boolean", short: "h" }
        },
        allowShort: true,
        allowPositionals: true
    }));
} catch (err) {
    console.error(`ERROR: ${err.message}`);
    process.exit(1);
}

debugEnabled = values.debug === true;

debug(`flags: check=${values.check} verbose=${values.verbose} quiet=${values.quiet} debug=${values.debug}`);
debug(`positionals: ${JSON.stringify(positionals)}`);

if (values.help) {
    printHelp();
    process.exit(0);
}

/* ============================================================
 * Extract flags
 * ============================================================ */

const checkMode = values.check === true;
const verbose = values.verbose === true;
const quiet = values.quiet === true;
const recursivePath =
    typeof values.recursive === "string" ? values.recursive : null;

let targetFile = null;

if (positionals.length > 1) {
    console.error("ERROR: Only one file argument may be provided");
    process.exit(1);
}

if (positionals.length === 1) {
    targetFile = positionals[0];
}

debug(`mode: ${checkMode ? "check" : "write"}`);

/* ============================================================
 * Contract validation
 * ============================================================ */

if (quiet && verbose) {
    console.error("ERROR: --quiet and --verbose cannot be used together");
    process.exit(1);
}

if (checkMode && !recursivePath && !targetFile) {
    console.error("ERROR: --check requires a file or --recursive <path>");
    process.exit(1);
}

if (recursivePath && targetFile) {
    console.error("ERROR: Cannot use --recursive with a file argument");
    process.exit(1);
}

/* ============================================================
 * Helpers
 * ============================================================ */

function collectMarkdownFiles(dir) {
    const results = [];
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            results.push(...collectMarkdownFiles(full));
        } else if (entry.isFile() && entry.name.endsWith(".md")) {
            results.push(full);
        }
    }
    return results;
}

function generateTOC(content) {
    const hasStart = content.includes(START);
    const hasEnd = content.includes(END);

    if (!hasStart && !hasEnd) {
        throw new Error("TOC delimiters not found");
    }
    if (hasStart && !hasEnd) {
        throw new Error("TOC start delimiter found without end");
    }
    if (!hasStart && hasEnd) {
        throw new Error("TOC end delimiter found without start");
    }

    const startIndex = content.indexOf(START);
    const endIndex = content.indexOf(END);

    const before = content.slice(0, startIndex + START.length);
    const after = content.slice(endIndex);

    const contentWithoutTOC =
        content.slice(0, startIndex) +
        content.slice(endIndex + END.length);

    const lines = contentWithoutTOC.split("\n");
    const headings = [];

    for (const line of lines) {
        const m = /^(#{1,6})\s+(.*)$/.exec(line);
        if (!m) continue;

        const level = m[1].length;
        const title = m[2].trim();

        const anchor = title
            .toLowerCase()
            .replace(/[^\w\s-]/g, "")
            .replace(/\s/g, "-")
            .replace(/^-|-$/g, "");

        headings.push({ level, title, anchor });
    }

    if (headings.length === 0) {
        throw new Error("No headings found to generate TOC");
    }

    const minLevel = Math.min(...headings.map(h => h.level));
    const tocLines = headings.map(h => {
        const indent = "  ".repeat(h.level - minLevel);
        return `${indent}- [${h.title}](#${h.anchor})`;
    });

    const tocBlock = "\n" + tocLines.join("\n") + "\n";
    return before + tocBlock + after;
}

/* ============================================================
 * File processing
 * ============================================================ */

function processFile(filePath, { isRecursive }) {
    debug(`processing file: ${filePath}`);

    let content;
    try {
        content = fs.readFileSync(filePath, "utf8");
    } catch {
        throw new Error(`Unable to read markdown file: ${filePath}`);
    }

    let updated;
    try {
        updated = generateTOC(content);
    } catch (err) {
        if (err.message === "TOC delimiters not found") {
            if (isRecursive) {
                debug("result: skipped (no markers)");
                return { status: "skipped" };
            }
            throw err; // single-file mode → hard error
        }
        throw err;
    }

    if (updated === content) {
        debug("result: unchanged");
        return { status: "unchanged" };
    }

    if (checkMode) {
        debug("result: stale");
        return { status: "stale" };
    }

    fs.writeFileSync(filePath, updated, "utf8");
    debug("result: updated");
    return { status: "updated" };
}

/* ============================================================
 * Output
 * ============================================================ */

function maybePrintStatus(status, filePath) {
    debug(`printing decision: status=${status}`);

    if (quiet) return;

    if (checkMode) {
        if (!verbose) return;

        if (status === "stale") {
            console.log(`Stale: ${filePath}`);
        } else if (status === "unchanged") {
            console.log(`Up-to-date: ${filePath}`);
        } else if (status === "skipped") {
            console.log(`Skipped (no markers): ${filePath}`);
        }
        return;
    }

    if (verbose) {
        if (status === "updated") {
            console.log(`Updated: ${filePath}`);
        } else if (status === "unchanged") {
            console.log(`Up-to-date: ${filePath}`);
        } else if (status === "skipped") {
            console.log(`Skipped (no markers): ${filePath}`);
        }
        return;
    }

    if (status === "updated") {
        console.log(`Updated: ${filePath}`);
    }
}

/* ============================================================
 * Execution
 * ============================================================ */

let files = [];
let isRecursive = false;

if (recursivePath) {
    const resolved = path.resolve(process.cwd(), recursivePath);

    if (!fs.existsSync(resolved)) {
        console.error("ERROR: Recursive path does not exist");
        process.exit(1);
    }
    if (!fs.statSync(resolved).isDirectory()) {
        console.error("ERROR: --recursive requires a directory");
        process.exit(1);
    }

    files = collectMarkdownFiles(resolved);
    files.sort();
    isRecursive = true;
} else {
    const resolved = path.resolve(
        process.cwd(),
        targetFile || "README.md"
    );
    files = [resolved];
}

let staleFound = false;

for (const file of files) {
    try {
        const result = processFile(file, { isRecursive });

        if (checkMode && result.status === "stale") {
            staleFound = true;
            debug("staleFound set true");
        }

        maybePrintStatus(result.status, file);
    } catch (err) {
        console.error(`ERROR: ${err.message}`);
        process.exit(1);
    }
}

if (checkMode && staleFound) {
    debug("exiting with status 1 due to stale TOC");
    process.exit(1);
}

debug("exiting with status 0");
process.exit(0);
