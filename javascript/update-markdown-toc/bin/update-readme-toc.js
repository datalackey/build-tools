#!/usr/bin/env node

import fs from "fs";
import path from "path";

/* ============================================================
 * Argument parsing
 * ============================================================ */

const args = process.argv.slice(2);

let markdownPath = "README.md";

if (args.length > 0 && !args[0].startsWith("-")) {
  markdownPath = args[0];
}

markdownPath = path.resolve(process.cwd(), markdownPath);

/* ============================================================
 * File existence / readability checks
 * ============================================================ */

if (!fs.existsSync(markdownPath)) {
  console.error(`ERROR: Markdown file not found: ${markdownPath}`);
  process.exit(1);
}

let content;
try {
  content = fs.readFileSync(markdownPath, "utf8");
} catch (err) {
  console.error(`ERROR: Unable to read markdown file: ${markdownPath}`);
  process.exit(1);
}

/* ============================================================
 * TOC delimiter detection
 * ============================================================ */

const START = "<!-- TOC:START -->";
const END = "<!-- TOC:END -->";

const hasStart = content.includes(START);
const hasEnd = content.includes(END);

if (!hasStart && !hasEnd) {
  console.error("ERROR: TOC delimiters not found");
  process.exit(1);
}

if (hasStart && !hasEnd) {
  console.error("ERROR: TOC start delimiter found without end");
  process.exit(1);
}

if (!hasStart && hasEnd) {
  console.error("ERROR: TOC end delimiter found without start");
  process.exit(1);
}

/* ============================================================
 * Split content into regions
 * ============================================================ */

const startIndex = content.indexOf(START);
const endIndex = content.indexOf(END);

const before = content.slice(0, startIndex + START.length);
const after = content.slice(endIndex);

/*
 * IMPORTANT:
 * We must ignore everything currently inside the TOC block
 * when generating the new TOC.
 */

const contentWithoutTOC =
  content.slice(0, startIndex) +
  content.slice(endIndex + END.length);

/* ============================================================
 * Heading extraction (outside TOC only)
 * ============================================================ */

const lines = contentWithoutTOC.split("\n");

const headings = [];

for (const line of lines) {
  const match = /^(#{1,6})\s+(.*)$/.exec(line);
  if (!match) continue;

  const level = match[1].length;
  const title = match[2].trim();

  const anchor = title
    .toLowerCase()
    .replace(/[^\w\s-]/g, "")   // remove punctuation like &
    .replace(/\s/g, "-")        // EACH space → hyphen
    .replace(/^-|-$/g, "");     // trim leading/trailing hyphens

  headings.push({ level, title, anchor });
}

if (headings.length === 0) {
  console.error("ERROR: No headings found to generate TOC");
  process.exit(1);
}

/* ============================================================
 * TOC generation
 * ============================================================ */

const minLevel = Math.min(...headings.map(h => h.level));

const tocLines = [];

for (const h of headings) {
  const indent = "  ".repeat(h.level - minLevel);
  tocLines.push(`${indent}- [${h.title}](#${h.anchor})`);
}

const tocBlock =
  "\n" +
  tocLines.join("\n") +
  "\n";

/* ============================================================
 * Assemble final content
 * ============================================================ */

const updated =
  before +
  tocBlock +
  after;

/* ============================================================
 * Write back
 * ============================================================ */

try {
  fs.writeFileSync(markdownPath, updated, "utf8");
} catch (err) {
  console.error(`ERROR: Unable to write markdown file: ${markdownPath}`);
  process.exit(1);
}


