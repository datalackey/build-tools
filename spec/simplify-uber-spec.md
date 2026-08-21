TASK: Simplify usage of uber-plugin to one use case:  operate on a designated file (README.md
in cwd if not specified), and apply bundled plugins as appropriate:
    - toc generation
    - UML diagrams if any UML:components*:START/END tags detected.
    - mermaid diagram generation (only if project.json detected and appropriate tags are in markdown      file

    Special behavior:
        * if no start/end tags are detected for any of the above:
            emit warning msg (unless quiet mode is specified) 
                "README.md contains no recognized markers 
                    (TOC:START, UML:*, NX_GRAPH:START). Nothing to do."

        * Mirror behavior of The individual plugins if they find a START without an END. 
            hard error msg -- a malformed tag pair is always an error, regardless of --quiet.
    

    UNIT tests for all new or modified behavior

    MODIFY readme to clarify the uber plugin's special use case, and 
    detail how individual bundled plugins can be executed with 'npx ...' 
    for more complicated scenarios (e.g., -recursive etc)

    README should have an explicit section: "Using bundled plugins independently" 
    with npx one-liners for each. This also serves as the "escape hatch" documentation so users know where to go when they outgrow the uber-bundle.


Proposed simplified CLI contract

autogen-markdown-doc [update|check] [file]  [--check] [--quiet] [--debug] [--help]
                     [--exclude-packages <pkg1,pkg2>]

Positional:
  file                  Target Markdown file (default: README.md)

Subcommands:
  update (default)      Apply all tag transformations in-place
  check                 Validate all tags; exit non-zero on drift (no writes)

Options:
  --exclude-packages    Forwarded to UML generation (leaf src/ dirs to skip)
  --quiet               Suppress all non-error output (incl. "no markers" warning)
  --debug               Print debug diagnostics to stderr
  --help                Show help


Note: for the UML plugin's behavior: just document "the targeted markdown file must live next to src/"?

On unit tests for --quiet / --debug

Yes, these need tests. The current pattern in this repo is:
- --quiet: assert stderr/stdout is empty on a valid run
- --debug: assert diagnostic lines appear on stderr
- --help: assert exit 0 and expected flag list in stdout

These are low-effort and already exist for the individual plugins — the pattern is established.








CONTEXT:
  Repo: ~/build-tools
  Platform workspace: javascript/ (NX monorepo, run all NX commands from there)
  Package under change: javascript/autogen-markdown-doc

  The uber plugin autogen-markdown-doc combines functionality of 
  update-markdown-uml nx-graph-to-mermaid   and update-markdown-toc.





UPDATE FORMATTING BEFORE VALIDATION:
  cd ~/build-tools/javascript
  npx nx run build-tools-workspace:update-all-format

VALIDATION:
  cd ~/build-tools/javascript
  npx nx run build-tools-workspace:check-format             # must exit 0
  npx nx run-many -t build,test --skip-nx-cache             # must exit 0


[![Remember the USS Liberty!](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
