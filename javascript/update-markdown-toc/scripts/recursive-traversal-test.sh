#!/usr/bin/env bash
source "$(dirname "$0")/test-lib.sh"

# ------------------------------------------------------------
# Setup
# ------------------------------------------------------------

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$ROOT/bin/update-readme-toc.js"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "========================================"
echo " Recursive traversal tests"
echo "========================================"
echo

# ------------------------------------------------------------
# Fixture layout
#
# tree/
# ├── a.md                (has TOC)
# ├── z.txt               (non-md, ignored)
# ├── empty-dir/          (empty)
# ├── sub/
# │   ├── b.md            (has TOC)
# │   ├── c.md            (no TOC)
# │   └── note.txt        (ignored)
# └── sub2/
#     └── d.md            (has TOC)
# ------------------------------------------------------------

TREE="$TMPDIR/tree"
mkdir -p "$TREE/empty-dir" "$TREE/sub" "$TREE/sub2"

cat > "$TREE/a.md" <<'EOF'
# A

<!-- TOC:START -->
<!-- TOC:END -->

## Section
EOF

cat > "$TREE/sub/b.md" <<'EOF'
# B

<!-- TOC:START -->
<!-- TOC:END -->

## Section
EOF

cat > "$TREE/sub/c.md" <<'EOF'
# C

## No TOC markers here
EOF

cat > "$TREE/sub2/d.md" <<'EOF'
# D

<!-- TOC:START -->
<!-- TOC:END -->

## Section
EOF

echo "hello" > "$TREE/z.txt"
echo "note"  > "$TREE/sub/note.txt"

# ------------------------------------------------------------
# Test 1: nested traversal actually visits all .md files
# ------------------------------------------------------------

echo "→ traverses nested directories and finds all .md files"

RAW_OUTPUT="$(
  run node "$CLI" --verbose --recursive "$TREE" 2>/dev/null
)"

OUTPUT="$(printf '%s\n' "$RAW_OUTPUT" | filter_run_lines)"
ACTUAL="$(normalize "$OUTPUT")"

EXPECTED_ORDER=$(
cat <<EOF
Updated: $TREE/a.md
Updated: $TREE/sub/b.md
Skipped (no markers): $TREE/sub/c.md
Updated: $TREE/sub2/d.md
EOF
)

if [[ "$ACTUAL" != "$EXPECTED_ORDER" ]]; then
  echo "ERROR: traversal output mismatch"
  echo "Expected:"
  echo "$EXPECTED_ORDER"
  echo
  echo "Actual:"
  echo "$ACTUAL"
  exit 1
fi

echo "✔ nested traversal and filtering correct"
echo

# ------------------------------------------------------------
# Test 2: deterministic ordering across directory boundaries
# ------------------------------------------------------------

echo "→ traversal order is deterministic and path-sorted"

RAW_OUTPUT2="$(
  run node "$CLI" --verbose --recursive "$TREE" 2>/dev/null
)"

PATHS_ONLY="$(
  printf '%s\n' "$RAW_OUTPUT2" \
    | filter_run_lines \
    | strip_status \
    | normalize
)"

EXPECTED_PATH_ORDER=$(
cat <<EOF
$TREE/a.md
$TREE/sub/b.md
$TREE/sub/c.md
$TREE/sub2/d.md
EOF
)

if [[ "$PATHS_ONLY" != "$EXPECTED_PATH_ORDER" ]]; then
  echo "ERROR: traversal order is not deterministic"
  echo "Expected paths:"
  echo "$EXPECTED_PATH_ORDER"
  echo
  echo "Actual paths:"
  echo "$PATHS_ONLY"
  exit 1
fi

echo "✔ deterministic ordering verified"
echo

# ------------------------------------------------------------
# Test 3: empty directories do not affect traversal
# ------------------------------------------------------------

echo "→ empty directories are ignored without error"

if echo "$ACTUAL" | grep -q "empty-dir"; then
  echo "ERROR: empty directory appeared in output"
  exit 1
fi

echo "✔ empty directories ignored"
echo

# ------------------------------------------------------------
# Test 4: non-.md files are ignored
# ------------------------------------------------------------

echo "→ non-.md files are ignored"

if echo "$ACTUAL" | grep -q "z.txt\|note.txt"; then
  echo "ERROR: non-markdown files were processed"
  exit 1
fi

echo "✔ non-.md files ignored"
echo

echo "========================================"
echo " ✅ RECURSIVE TRAVERSAL TESTS PASSED"
echo "========================================"


