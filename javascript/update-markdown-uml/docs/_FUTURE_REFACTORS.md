## Tooling Core Contributions (completed)

### `findMarker` and `findMarkers`

Both utilities are implemented and exported from `tooling-core`
(`src/markdown/findMarker.ts`). The original motivation:
```typescript
export interface MarkerLocation {
  startMarker: string
  endMarker: string
  startLine: number
  endLine: number
  startIndex: number
  endIndex: number
}

/**
 * Locates a single marker pair within a content string.
 * Returns null if either marker is not found or if end precedes start.
 */
export function findMarker(
  content: string,
  startMarker: string,
  endMarker: string
): MarkerLocation | null

/**
 * Locates multiple named marker pairs in a single pass over the content.
 * Returns a map keyed by startMarker string.
 * Markers not found in the content are absent from the result map.
 */
export function findMarkers(
  content: string,
  pairs: Array<{ startMarker: string; endMarker: string }>
): Map<string, MarkerLocation>
```

`findMarker` is a general-purpose utility applicable to any plugin that needs
to locate or report on marker positions without necessarily replacing their
content. It has no dependency on UML-specific behavior and belongs in the
core library.

### `injectSections`

Inject a collection of named headed sections as a single block between one
marker pair. Generalizes `injectBetweenMarkers` for the case where multiple
sub-sections must be written inside a single outer marker region.

---

## Refactor Candidates

Once `findMarker` is implemented and tested in `tooling-core`, the following
existing code should be refactored to use it. These are not blocking for the
UML plugin but represent cleanup that improves consistency and error quality
across the ecosystem.

**`tooling-core/src/markdown/injectBetweenMarkers.ts`**

Current ad-hoc index checks should be replaced with a call to `findMarker`,
propagating the returned `MarkerLocation` or throwing a consistent error with
line numbers if `findMarker` returns `null`.

**`update-markdown-toc/src/engine/generateToc.ts`**

Current ad-hoc presence checks should be replaced with `findMarker`, which
handles all three error cases and additionally surfaces line numbers for more
actionable error output:
```
ERROR: path/to/file.md:4: TOC start delimiter found without matching end
```

Benefits of consolidation:

- Single well-tested detection implementation across all plugins
- Consistent error message format
- Line numbers surfaced in all marker-related errors
- Eliminates the silent `endIndex <= startIndex` case in `injectBetweenMarkers`
  which currently produces a confusing generic error rather than identifying
  the reversed-marker condition explicitly

---

## Dependencies

| Package | Role |
|---------|------|
| `ts-morph` | TypeScript compiler API — discovers types, resolves imports, generates Mermaid DSL |
| `@doikayt/tooling-core` | CLI framework, file processing, injection utilities |

---

## Out of Scope (v1)

- `autogen-markdown-doc` integration — deferred to a subsequent release
- Cross-package type-level relationship arrows in the overview diagram
- Recursive repository traversal — one source tree and one injection target per invocation
- Auto-generation of `_COMPONENT_INFO.md` files
- Per-type exclusion in `autogen-markdown-doc` integration
- Diagram caching or incremental regeneration

---

## Resolved Questions

1. **tsuml2 vs ts-morph** — resolved: `ts-morph` is used for all diagram
   generation. `tsuml2` was removed from dependencies.

[![No US Tax$ 4 genocide](https://badge.techforpalestine.org/ceasefire-now)](https://techforpalestine.org/learn-more)
