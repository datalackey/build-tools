#!/usr/bin/env bash
source "$(dirname "$0")/test-lib.sh" "$@"

# ============================================================
# Recursive error contract tests
#
# IMPORTANT:
# This suite deliberately disables the ERR trap and relies
# entirely on explicit exit-code and output assertions.
# ============================================================

# Disable automatic failure handling for this suite
set +e +E
trap - ERR


ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$ROOT/bin/update-markdown-toc.js"

TMPDIR="$(make_tmpdir)"
mkdir -p "$TMPDIR"

echo "========================================"
echo " Recursive error contract tests"
echo "========================================"
echo

# ------------------------------------------------------------
# Case 1: --recursive with missing path
# ------------------------------------------------------------

echo "→ --recursive with missing path errors (and exits non-zero)"

MISSING_PATH="$TMPDIR/definitely-not-there"

OUTPUT="$(node "$CLI" --recursive "$MISSING_PATH" 2>&1)"
STATUS=$?

if [[ "$STATUS" -eq 0 ]]; then
  echo "ERROR: expected non-zero exit for missing recursive path"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "ERROR: Recursive path does not exist"; then
  echo "ERROR: expected missing-path error message"
  echo "Actual output:"
  echo "$OUTPUT"
  exit 1
fi

echo "✔ missing recursive path rejected"
echo

# ------------------------------------------------------------
# Case 2: --recursive path is a file, not a directory
# ------------------------------------------------------------

echo "→ --recursive with file path errors"

NOT_A_DIR="$TMPDIR/not-a-dir.md"
echo "# not a dir" > "$NOT_A_DIR"

OUTPUT="$(node "$CLI" --recursive "$NOT_A_DIR" 2>&1)"
STATUS=$?

if [[ "$STATUS" -eq 0 ]]; then
  echo "ERROR: expected non-zero exit for non-directory recursive path"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "ERROR: --recursive requires a directory"; then
  echo "ERROR: expected directory-required error message"
  echo "Actual output:"
  echo "$OUTPUT"
  exit 1
fi

echo "✔ non-directory recursive path rejected"
echo

# ------------------------------------------------------------
# Case 3: --recursive without argument (parse-level error)
# ------------------------------------------------------------

echo "→ --recursive without argument errors"

OUTPUT="$(node "$CLI" --recursive 2>&1)"
STATUS=$?

if [[ "$STATUS" -eq 0 ]]; then
  echo "ERROR: expected non-zero exit for missing --recursive argument"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "ERROR:"; then
  echo "ERROR: expected parse error output"
  echo "Actual output:"
  echo "$OUTPUT"
  exit 1
fi

echo "✔ missing --recursive argument rejected"
echo

# ------------------------------------------------------------
# Case 4: --recursive combined with positional file argument
# ------------------------------------------------------------

echo "→ --recursive with positional file argument errors"

DUMMY_MD="$TMPDIR/file.md"
echo "# dummy" > "$DUMMY_MD"

OUTPUT="$(node "$CLI" --recursive "$TMPDIR" "$DUMMY_MD" 2>&1)"
STATUS=$?

if [[ "$STATUS" -eq 0 ]]; then
  echo "ERROR: expected non-zero exit for recursive + file argument"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "ERROR: Cannot use --recursive with a file argument"; then
  echo "ERROR: expected recursive/file conflict error"
  echo "Actual output:"
  echo "$OUTPUT"
  exit 1
fi

echo "✔ recursive + file argument rejected"
echo

# ------------------------------------------------------------
# Case 5: mismatched TOC markers report absolute file path
# ------------------------------------------------------------

echo "→ recursive run reports absolute path for mismatched TOC markers"

BAD_MD="$TMPDIR/bad.md"

cat > "$BAD_MD" <<'EOF'
# Bad

<!-- TOC:START -->

## Section
EOF

OUTPUT="$(node "$CLI" --recursive "$TMPDIR" 2>&1)"
STATUS=$?

if [[ "$STATUS" -eq 0 ]]; then
  echo "ERROR: expected non-zero exit for mismatched TOC markers"
  exit 1
fi

ABS_BAD_MD="$(cd / && realpath "$BAD_MD")"

if ! echo "$OUTPUT" | grep -q "^ERROR: $ABS_BAD_MD:"; then
  echo "ERROR: expected absolute file path in error message"
  echo "Expected prefix:"
  echo "ERROR: $ABS_BAD_MD:"
  echo "Actual output:"
  echo "$OUTPUT"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "TOC start delimiter found without end"; then
  echo "ERROR: expected delimiter mismatch message"
  echo "Actual output:"
  echo "$OUTPUT"
  exit 1
fi

echo "✔ mismatched TOC marker path reported"
echo

echo "========================================"
echo " ✅ RECURSIVE ERROR CONTRACT TESTS PASSED"
echo "========================================"

