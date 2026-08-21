# Contributing to @doikayt/nx-graph-to-mermaid



# Code Structure Diagrams


## Component Diagram

<!-- UML:components:START -->
```mermaid
flowchart TB
  subgraph core["core"]
  end
  subgraph generate["generate"]
  end

  generate --> core
```
<!-- UML:components:END -->

## Components Table

<!-- UML:components-table:START -->
| Component | Description |
|-----------|-------------|
| [core](#core) | Mermaid diagram builder: validates an NX `project.json` targets map and emits a deterministic `graph TD` diagram with sanitized node IDs and sorted dependency edges |
| [generate](#generate) | NX executor entry point: resolves options, dispatches to `generate`, `inject`, `update`, or `check` mode, and writes the Mermaid diagram into a target Markdown file between `<!-- NX_GRAPH:START -->` / `<!-- NX_GRAPH:END -->` markers |
<!-- UML:components-table:END -->

## Component Details

<!-- UML:component-details:START -->
#### core
```mermaid
classDiagram
  direction TB
  class NxTarget {
    <<interface>>
    +dependsOn? string[]
    +description? string
  }
  class NxProjectJson {
    <<interface>>
    +name? string
    +targets? Record<string, NxTarget>
  }
```

#### generate
```mermaid
classDiagram
  direction TB
  class RawOptions {
    <<interface>>
    +projectJsonPath string
    +mode? Mode
    +generatedMermaidPath? string
    +markdownPath? string
    +debug? boolean
  }
  class NormalizedOptions {
    <<interface>>
    +projectJsonPath string
    +mode Mode
    +generatedMermaidPath? string
    +markdownPath? string
    +debug? boolean
  }
  class Mode {
    <<type>>
  }
  class ExecutionContext {
    <<type>>
  }
```
<!-- UML:component-details:END -->



# Build and Release 

For workspace-level setup, build pipeline, and release workflow see:
[javascript/docs/CONTRIBUTING.md](../../docs/CONTRIBUTING.md)

---

*Package-specific contributor documentation coming soon.*

[![No US Tax$ 4 genocide](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
