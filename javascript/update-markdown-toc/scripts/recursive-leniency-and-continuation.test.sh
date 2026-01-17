#!/usr/bin/env bash
source "$(dirname "$0")/test-lib.sh" "$@"

# ------------------------------------------------------------
# Setup
# ------------------------------------------------------------

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$ROOT/bin/update-markdown-toc.js"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "========================================"
echo " Recursive leniency and continuation tests"
echo "========================================"
echo

# ------------------------------------------------------------
# Fixture layout
#
# tree/
# ├── good.md             (has TOC, should be processed)
# ├── no-toc.md           (no TOC markers, should be skipped)
# ├── unreadable.md       (unreadable file)
# ├── sub/
# │   ├── good-sub.md     (has TOC, should be processed)
# │   └── no-toc-sub.md  (no TOC markers, should be skipped)
# ------------------------------------------------------------

TREE="$TMPDIR/tree"
mkdir -p "$TREE/sub"

cat > "$TREE/good.md" <<'EOF'
# Good

<!-- TOC:START -->
<!-- TOC:END -->

## Section
EOF

cat > "$TREE/no-toc.md" <<'EOF'
# No TOC

## Section
EOF

cat > "$TREE/sub/good-sub.md" <<'EOF'
# Good Sub

<!-- TOC:START -->
<!-- TOC:END -->

## Subsection
EOF

cat > "$TREE/sub/no-toc-sub.md" <<'EOF'
# No TOC Sub

## Subsection
EOF

cat > "$TREE/unreadable.md" <<'EOF'
# Unreadable

<!-- TOC:START -->
<!-- TOC:END -->

## Section
EOF

chmod 000 "$TREE/unreadable.md"

# ------------------------------------------------------------
# Test 1: recursive mode continues despite skipped files
# ------------------------------------------------------------

echo "→ continues processing despite skipped files (ignore the ERRROR)"

RAW_OUTPUT="$(
  run_capture node "$CLI" --recursive "$TREE"
)"

# Restore permissions so cleanup works
chmod 644 "$TREE/unreadable.md"

OUTPUT="$(
  printf '%s\n' "$RAW_OUTPUT" \
    | filter_run_lines \
    | normalize
)"

if ! echo "$OUTPUT" | grep -q "good.md"; then
  echo "ERROR: good.md was not processed"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "good-sub.md"; then
  echo "ERROR: good-sub.md was not processed"
  exit 1
fi

echo "✔ skipped files did not abort recursive run"
echo

# ------------------------------------------------------------
# Test 2: good files are actually written
# ------------------------------------------------------------

echo "→ successfully processed files are written"

if ! grep -q '\- \[Good\]' "$TREE/good.md"; then
  echo "ERROR: good.md TOC was not written"
  exit 1
fi

if ! grep -q '\- \[Good Sub\]' "$TREE/sub/good-sub.md"; then
  echo "ERROR: good-sub.md TOC was not written"
  exit 1
fi

echo "✔ processed files were written correctly"
echo

# ------------------------------------------------------------
# Test 3: skipped files remain unchanged
# ------------------------------------------------------------

echo "→ skipped files remain unchanged"

if grep -q 'TOC:START' "$TREE/no-toc.md"; then
  echo "ERROR: no-toc.md was modified unexpectedly"
  exit 1
fi

if grep -q 'TOC:START' "$TREE/sub/no-toc-sub.md"; then
  echo "ERROR: no-toc-sub.md was modified unexpectedly"
  exit 1
fi

echo "✔ skipped files were not modified"
echo

# ------------------------------------------------------------
# Test 4: recursive mode exits 0 despite mixed outcomes
# ------------------------------------------------------------

echo "→ recursive mode exits successfully with mixed outcomes"

run node "$CLI" --recursive "$TREE" >/dev/null 2>&1

STATUS=$?
if [[ "$STATUS" -ne 0 ]]; then
  echo "ERROR: recursive mode exited non-zero unexpectedly"
  exit 1
fi

echo "✔ recursive mode exited 0 as expected"
echo

echo "========================================"
echo " ✅ RECURSIVE LENIENCY & CONTINUATION TESTS PASSED"
echo "========================================"

