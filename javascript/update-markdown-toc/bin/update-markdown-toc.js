#!/usr/bin/env node

import fs from "fs";
import path from "path";
import { parseCli } from "./parseCli.js";

/* ============================================================
 * Constants
 * ============================================================ */

const START = "<!-- TOC:START -->";
const END   = "<!-- TOC:END -->";

/* ============================================================
 * CLI configuration
 * ============================================================ */

const {
    checkMode,
    verbose,
    quiet,
    debug,
    recursivePath,
    targetFile,
    isRecursive
} = parseCli();

/* ============================================================
 * Debug helper
 * ============================================================ */

function debugLog(msg) {
    if (debug) {
        console.error(`[debug] ${msg}`);
    }
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
    const hasEnd   = content.includes(END);

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
    const endIndex   = content.indexOf(END);

    const before = content.slice(0, startIndex + START.length);
    const after  = content.slice(endIndex);

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
            .replace(/[^\w\s-]/g, "")   // remove punctuation
            .replace(/\s/g, "-")        // spaces → hyphens
            .replace(/^-+/g, "");       // FIX: trim leading hyphens ONLY

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

function processFile(filePath) {
    debugLog(`processing file: ${filePath}`);

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
                debugLog("result: skipped (no markers)");
                return { status: "skipped" };
            }
            throw err;
        }
        throw err;
    }

    if (updated === content) {
        debugLog("result: unchanged");
        return { status: "unchanged" };
    }

    if (checkMode) {
        debugLog("result: stale");
        return { status: "stale" };
    }

    fs.writeFileSync(filePath, updated, "utf8");
    debugLog("result: updated");
    return { status: "updated" };
}

/* ============================================================
 * Output
 * ============================================================ */

function maybePrintStatus(status, filePath) {
    debugLog(`printing decision: status=${status}`);

    if (quiet) return;

    if (checkMode) {
        if (status === "stale") {
            console.log(`Stale: ${filePath}`);
            return;
        }

        if (status === "skipped") {
            if (verbose) {
                console.log(`Skipped (no markers): ${filePath}`);
            }
            return;
        }

        if (status === "unchanged") {
            if (verbose) {
                console.log(`Up-to-date: ${filePath}`);
            }
            return;
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
        const result = processFile(file);

        if (checkMode && result.status === "stale") {
            staleFound = true;
            debugLog("staleFound set true");
        }

        maybePrintStatus(result.status, file);
    } catch (err) {
        console.error(`ERROR: ${err.message}`);
        process.exit(1);
    }
}

if (checkMode && staleFound) {
    debugLog("exiting with status 1 due to stale TOC");
    process.exit(1);
}

debugLog("exiting with status 0");
process.exit(0);
