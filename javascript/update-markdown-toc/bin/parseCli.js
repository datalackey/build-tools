import { parseArgs } from "node:util";
import { dedent } from "ts-dedent";

export function parseCli() {
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

    if (values.help) {
        printHelp();
        process.exit(0);
    }

    const checkMode = values.check === true;
    const verbose   = values.verbose === true;
    const quiet     = values.quiet === true;
    const debug     = values.debug === true;

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

    // -------------------------
    // Contract validation
    // -------------------------

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

    return Object.freeze({
        checkMode,
        verbose,
        quiet,
        debug,

        recursivePath,
        targetFile,

        isRecursive: Boolean(recursivePath)
    });
}

function printHelp() {
    console.log(dedent`
    update-markdown-toc [options] [file]

    Options:
      -c, --check     <path-to-file-or-folder>  Do not write files; exit non-zero if TOC is stale
      -r, --recursive <path-to-folder>          Recursively process all .md files under the given folder
      -v, --verbose                             Print status for every file processed
      -q, --quiet                               Suppress all non-error output
      -d, --debug                               Print debug diagnostics to stderr
      -h, --help                                Show this help message and exit
      
      When using --check, a target file or a recursive folder must be specified
      explicitly. Unlike normal operation, --check does not default to README.md.

  `);
}
