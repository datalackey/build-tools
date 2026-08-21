<!-- TOC:START -->
- [Documentation as Active Infrastructure: Architectural Mirror, Navigation Layer, and Quality Gate](#documentation-as-active-infrastructure-architectural-mirror-navigation-layer-and-quality-gate)
  - [Role 1 — The Architectural Mirror](#role-1--the-architectural-mirror)
    - [Signal 1 — The Busy UML Diagram](#signal-1--the-busy-uml-diagram)
    - [Signal 2 — The Verbose Component Summary](#signal-2--the-verbose-component-summary)
    - [Signal 3 — The Deep TOC](#signal-3--the-deep-toc)
    - [Signal 4 — The Complex Build Graph](#signal-4--the-complex-build-graph)
    - [The Mirror Principle](#the-mirror-principle)
  - [Role 2 — The Navigation Layer](#role-2--the-navigation-layer)
    - [Why This Is Better Than Naive RAG](#why-this-is-better-than-naive-rag)
    - [The TOC as a Retrieval Index](#the-toc-as-a-retrieval-index)
    - [The Navigation Layer as Contributor Discipline](#the-navigation-layer-as-contributor-discipline)
  - [Role 3 — The Quality Gate](#role-3--the-quality-gate)
    - [The Check Invariant](#the-check-invariant)
  - [The Unified View](#the-unified-view)
<!-- TOC:END -->

# Documentation as Active Infrastructure: Architectural Mirror, Navigation Layer, and Quality Gate

Most projects treat documentation as a cost — something written after the fact, checked into a
folder, and quietly tolerated until it goes stale. This document argues for a different model:
documentation as active infrastructure that does real work at every stage of the development
lifecycle.

The tools in this repository embody three distinct roles for documentation, each valuable on its
own and more powerful in combination:

1. **Architectural mirror** — generated output reflects source structure honestly;
   difficult-to-interpret output is a design or code smell, not a formatting problem
2. **Navigation layer** — per-component descriptions form a curated, semantically meaningful index
   over the code artifacts of a repository. Such an index enables a contributor or AI agent to
   understand a codebase without opening source files (saving time for the human and reducing
   context pressure for the AI)
3. **Quality gate** — the same artifacts that document the code are verified in CI; drift between
   code and docs fails the build

These are not three separate features bolted on independently. They emerge from a single design
decision: make documentation generation automatic, deterministic, and structurally coupled to the
source.

---

## Role 1 — The Architectural Mirror

Documentation generators work by analysing source structure and reflecting it back in a readable
form. That reflection is inherently honest — it shows what is actually there, not what was
intended. When the output is hard to read, that difficulty is usually a property of the source,
not the tool.

Every documentation run is therefore an implicit architectural review.

### Signal 1 — The Busy UML Diagram

**Tool:** `update-markdown-uml`

When a component diagram is too busy to read — too many boxes, too many relationships, labels
overlapping — the instinct is to reach for exclusion lists or layout tweaks. That instinct should
be resisted.

A diagram that cannot be rendered readably is telling you that the subsystem has too many
concerns. The correct response is decomposition, not configuration.

This is why `autogen-markdown-doc` exposes UML generation without exclusion lists. The unfiltered
picture is intentional — hiding types from the diagram hides the signal.

### Signal 2 — The Verbose Component Summary

**Tool:** `update-markdown-uml`

The per-package component count output:
```
  markdown     — 14 types
  cli          — 5 types
  repository   — 4 types
  policy       — 3 types
  logging      — 2 types
  util         — 1 type
```

Output is sorted by type count descending, which makes the heaviest component immediately
visible. A component that grows noticeably from run to run is a passive signal that the subsystem
may be accumulating too many concerns — surfaced without any dedicated architectural review
process.

### Signal 3 — The Deep TOC

**Tool:** `update-markdown-toc`

A document whose generated TOC is very long and deeply nested is exhibiting the same symptom as
a busy class diagram — too many concerns in one place. A README with 40 entries spanning 6 levels
of nesting is telling you the document needs decomposition, or that the subsystem it describes
does.

The TOC generator surfaces this by making the structure impossible to ignore. A deep TOC is
visually uncomfortable in a way that a long source file is not.

### Signal 4 — The Complex Build Graph

**Tool:** `nx-graph-to-mermaid`

A build graph with many nodes and tangled dependency chains reflects the same problem at the
pipeline level. A task graph that is difficult to follow visually is a signal that the build
pipeline has too many responsibilities or unclear separation between stages.

The generated Mermaid diagram makes this structure concrete and reviewable in a way that reading
`project.json` directly does not.

### The Mirror Principle

Each signal shares the same structure:

1. The tool generates output mechanically from source structure
2. The output is difficult to read or visually uncomfortable
3. That discomfort is a property of the source, not the tool
4. The correct response is to address the source, not to suppress the output

This is the documentation-as-mirror principle: the tools are not just keeping documentation up
to date, they are reflecting the architecture back at the people who built it.

---

## Role 2 — The Navigation Layer

The second role emerges from a different artifact: the per-component `_COMPONENT_INFO.md` file.

Each component directory — meaning any folder that owns a coherent set of TypeScript files —
may contain a `_COMPONENT_INFO.md`. The convention is minimal: the file's first sentence (ending
with a period) describes what that component does.

```
Handles CLI argument parsing and validation.
```

The `update-markdown-uml` tool reads these files and incorporates their descriptions into the
generated components table in the README:

| Component | Description |
|-----------|-------------|
| [cli] | Handles CLI argument parsing and validation |
| [repository] | Manages file discovery and processing lifecycle |
| [util] | Shared utility functions |

This creates a two-tier index of the codebase:

**Tier 1 — The README TOC** maps what is in this document at section level:
> "there is a section about `parseOptions`"

**Tier 2 — The component descriptions** map what each module folder does:
> "this folder handles CLI arg parsing and validation"

Together they form a navigable hierarchy:

```
README TOC              → "there is a section about parseOptions"
_COMPONENT_INFO.md      → "this folder handles CLI arg parsing and validation"
actual .ts files        → implementation detail
```

A contributor — or an AI agent — can answer "what does this package do and where should I look?"
using only the first two tiers, without opening a single source file.

### Why This Is Better Than Naive RAG

Retrieval-augmented generation over a codebase typically chunks documents arbitrarily — by token
count, by line count, or by file boundary. These boundaries rarely align with meaning.

The `_COMPONENT_INFO.md` pattern is different. The chunking boundary is the module folder, which
is already a meaningful unit of the system. The descriptions are human-curated, semantically
coherent, and intentionally terse. They are designed to answer exactly the question an agent or
new contributor asks first: *what does this part of the system do?*

This makes component descriptions better than RAG chunks in the same way an index is better than
a full-text search: the structure is meaningful by construction, not inferred by similarity. You
control the granularity. Naive RAG chunks documents at arbitrary boundaries (often badly);
`_COMPONENT_INFO.md` files are curated at the boundary that already matters — the module.

### The TOC as a Retrieval Index

The generated TOC has a second use beyond human navigation and architectural signalling. Because
every section boundary is explicitly named and anchored, the TOC also serves as a pre-computed
chunk manifest for agent retrieval.

The pattern:

1. **Read the TOC only** — the first ~2KB of a markdown file with TOC markers reveals what
   sections exist without loading the full document into context
2. **Decide relevance** — based on section headings alone, determine which sections are likely
   to answer the query
3. **Retrieve on demand** — read only the relevant sections; the rest of the document never
   enters the context window

This is lazy document retrieval: the full markdown is never loaded speculatively.

A pre-computed index per document formalises this:

```json
{
  "path": "javascript/tooling-core/README.md",
  "summary": "Framework for building markdown documentation plugins",
  "sections": [
    {
      "heading": "Plugin Authoring API",
      "anchor": "#plugin-authoring-api",
      "preview": "The core interface for building plugins...",
      "vector": [0.12, 0.45, "..."]
    }
  ]
}
```

With vectors pre-computed at documentation generation time, an agent can embed a query once,
compare against stored section vectors using cosine similarity, and retrieve only the top-k
sections — rather than scanning entire documents for relevant content.

**Why TOC-anchored chunks outperform token-count chunks:** naive RAG pipelines frequently split
a heading from the paragraph that follows it, destroying the context signal the heading provides.
TOC-anchored chunks are always complete sections — the heading and its body stay together,
preserving the semantic unit the author intended.

This extends the navigation layer to four tiers:

| Tier | Artifact | Answers |
|------|----------|---------|
| 0 | `_COMPONENT_INFO.md` | "what does this module do?" |
| 1 | Document TOC (first 2KB) | "what sections exist in this document?" |
| 2 | Section content | "what does this section say?" (retrieved on demand) |
| 3 | Pre-computed vectors | "which section is semantically closest to my query?" |

Tiers 0 and 1 are generated automatically and cost nothing at query time. An agent can route
most questions from those two tiers alone, descending to Tier 2 only when it has identified the
right target — and optionally using Tier 3 to make that descent semantic rather than
keyword-based. Tier 3 requires an embedding API call per section at generation time and is
optional; the retrieval pattern is useful even without it.

### The Navigation Layer as Contributor Discipline

There is a secondary benefit that has nothing to do with tools or agents. Writing a
`_COMPONENT_INFO.md` forces the author to articulate what the folder is for in one sentence. If
that sentence is difficult to write — if the folder does several unrelated things and resists a
clean description — that difficulty is itself a signal. The folder may need to be split.

The act of documenting is, again, a form of architectural review. The navigation layer and the
mirror are the same mechanism seen from two different angles.

---

## Role 3 — The Quality Gate

The third role is enforced rather than observed. The same tools that generate documentation run
in CI in `--check` mode: they regenerate the output and compare it byte-for-byte against what is
committed. Any drift fails the build.

This transforms documentation from a best-effort artifact into a build output with a pass/fail
condition — the same status as compiled code or passing tests.

The practical consequence: documentation cannot go stale silently. A code change that would
produce different output from any of the generators — a new type, a refactored dependency, a
renamed section — must be accompanied by an updated documentation commit, or CI fails. The
feedback is immediate and unambiguous.

This also removes the enforcement burden from code review. Reviewers do not need to verify that
the UML diagram reflects the current types, or that the build graph matches `project.json`, or
that the TOC reflects the actual headings. The build verifies this automatically.

### The Check Invariant

The correctness property CI enforces is:

```
check(update(repo)) === pass
```

If `update` is run and then `check` is run immediately after, check must always pass. This
invariant holds because both operations are fully deterministic: identical input always produces
identical output. Any deviation is evidence of drift, never of non-determinism in the tool.

---

## The Unified View

These three roles — mirror, navigation, gate — are not separate tools with separate purposes.
They are three properties of the same design decision: generate documentation automatically from
source structure, with deterministic and verifiable output.

| Role | What it does | Why it works |
|------|--------------|--------------|
| Mirror | Surfaces architectural smells | Generation is structural; output mirrors source |
| Navigation | Indexes codebase for humans and agents | Module folders are natural chunk units |
| Quality gate | Prevents documentation drift | Deterministic output makes drift detectable |

A project that adopts all three simultaneously gets something rare: documentation that is always
current, always structured, and actively useful to both humans and tools — without a dedicated
documentation maintenance effort.

---

*This document describes the philosophy behind the tools in this workspace. For the tools
themselves, see the individual package READMEs. For day-to-day development workflows, see
[CONTRIBUTING.md](./CONTRIBUTING.md).*

[![Free Palestine!](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
