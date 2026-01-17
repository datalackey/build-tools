#!/usr/bin/env bash
source "$(dirname "$0")/test-lib.sh" "$@"

# ============================================================
# Recursive output matrix tests
# ============================================================

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$ROOT/bin/update-markdown-toc.js"

TMPDIR="$(make_tmpdir)"

echo "========================================"
echo " Recursive output matrix tests"
echo "========================================"
echo

# ------------------------------------------------------------
# Case 1: default recursive → Updated only
# ------------------------------------------------------------

TREE1="$TMPDIR/tree-case1"
mkdir -p "$TREE1"

cat > "$TREE1/only.md" <<'EOF'
# Only

<!-- TOC:START -->
<!-- TOC:END -->

## Section
EOF

OUTPUT="$(
  run_capture node "$CLI" --recursive "$TREE1"
)"

ACTUAL="$(printf '%s\n' "$OUTPUT" | filter_run_lines | normalize)"
EXPECTED="Updated: $TREE1/only.md"

[[ "$ACTUAL" == "$EXPECTED" ]] || exit 1
echo "✔ default recursive output correct"
echo

# ------------------------------------------------------------
# Case 2: recursive --verbose → full status matrix
# ------------------------------------------------------------

TREE2="$TMPDIR/tree-case2"
mkdir -p "$TREE2"

cat > "$TREE2/good.md" <<'EOF'
# Good

<!-- TOC:START -->
- [Good](#good)
<!-- TOC:END -->
EOF

cat > "$TREE2/stale.md" <<'EOF'
# Stale

<!-- TOC:START -->
<!-- TOC:END -->

## Section
EOF

cat > "$TREE2/no-toc.md" <<'EOF'
# No TOC
## Section
EOF

OUTPUT="$(
  run_capture node "$CLI" --recursive "$TREE2" --verbose
)"

ACTUAL="$(printf '%s\n' "$OUTPUT" | filter_run_lines | normalize)"
EXPECTED=$(
cat <<EOF
Up-to-date: $TREE2/good.md
Skipped (no markers): $TREE2/no-toc.md
Updated: $TREE2/stale.md
EOF
)

[[ "$ACTUAL" == "$EXPECTED" ]] || exit 1
echo "✔ recursive --verbose output correct"
echo

# ------------------------------------------------------------
# Case 3: recursive --check exits non-zero for stale files
# ------------------------------------------------------------

TREE3="$TMPDIR/tree-case3"
mkdir -p "$TREE3"

cat > "$TREE3/stale.md" <<'EOF'
# Stale

<!-- TOC:START -->
<!-- TOC:END -->

## Section
EOF

echo "→ recursive --check exits non-zero for stale files"

if run_expect_fail node "$CLI" --recursive "$TREE3" --check >/dev/null 2>&1; then
  echo "ERROR: expected non-zero exit for stale TOC"
  exit 1
fi

echo "✔ recursive --check exit code correct"
echo

# ------------------------------------------------------------
# Case 4: recursive --check --verbose reports stale files
# ------------------------------------------------------------

TREE4="$TMPDIR/tree-case4"
mkdir -p "$TREE4"

cat > "$TREE4/good.md" <<'EOF'
# Good

<!-- TOC:START -->
- [Good](#good)
<!-- TOC:END -->
EOF

cat > "$TREE4/stale.md" <<'EOF'
# Stale

<!-- TOC:START -->
<!-- TOC:END -->

## Section
EOF

cat > "$TREE4/no-toc.md" <<'EOF'
# No TOC
## Section
EOF

OUTPUT="$(
  if run_expect_fail node "$CLI" --recursive "$TREE4" --check --verbose; then
    echo "__UNEXPECTED_SUCCESS__"
  fi
)"

[[ "$OUTPUT" != "__UNEXPECTED_SUCCESS__" ]] || exit 1

ACTUAL="$(printf '%s\n' "$OUTPUT" | filter_run_lines | normalize)"
EXPECTED=$(
cat <<EOF
Up-to-date: $TREE4/good.md
Skipped (no markers): $TREE4/no-toc.md
Stale: $TREE4/stale.md
EOF
)

[[ "$ACTUAL" == "$EXPECTED" ]] || exit 1
echo "✔ recursive --check --verbose output correct"
echo

echo "========================================"
echo " ✅ RECURSIVE OUTPUT MATRIX TESTS PASSED"
echo "========================================"
