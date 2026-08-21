
# Future Directions

### Decoupling the Graph Engine from Nx


The rendering engine (`buildMermaid`) is NX-agnostic.

It operates on:

```
{
  targets: {
    [name: string]: {
      dependsOn?: string[]
      description?: string
    }
  }
}
```

NX is simply one producer of that structure.

---

`nx-graph-to-mermaid` is currently implemented as an Nx executor because it integrates cleanly into existing Nx workflows:

- Targets are already defined in `project.json`
- `dependsOn` relationships already form a directed task graph
- CI drift detection fits naturally into Nx task pipelines

However, the core rendering engine (`buildMermaid`) is intentionally Nx-agnostic.

It operates on a simple structure:

{
targets: {
[name: string]: {
dependsOn?: string[]
description?: string
}
}
}

This structure represents a generic directed task graph.
Nx is simply one producer of that graph.

### Why Consider Decoupling?

Over time, it may be valuable to separate:

- Graph extraction (Nx-specific)
- Graph rendering (generic Mermaid output)

This separation would allow:

- A standalone CLI mode:
  nx-graph-to-mermaid --input build-graph.json --output diagram.md
- Support for other build systems that can emit task graphs
- Use outside Nx workspaces
- Broader documentation tooling use cases
- Rendering CI pipelines or custom DAG definitions

The current implementation already contains a clean architectural boundary:

Nx Executor
↓
normalizeOptions
↓
buildMermaid()

A future CLI would simply call `buildMermaid()` directly.

---



[![No US Tax$ 4 genocide](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
