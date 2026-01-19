#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$ROOT/bin/update-markdown-toc.js"
FIXTURES="$ROOT/test-fixtures"

# Enable debug tracing if needed (off by default for CI)
DEBUG_FLAG=""
#DEBUG_FLAG="--debug"

normalize_output() {
  # Remove trailing newlines only
  printf '%s' "$1" | sed -e ':a' -e '/\n$/{$d;N;ba}'
}

echo "========================================"
echo " Running positive fixture tests"
echo "========================================"

cleanup_fixture() {
  if [[ -f "$README.tmp" ]]; then
    mv "$README.tmp" "$README"
  fi
}

for dir in "$FIXTURES"/*; do
  README="$dir/README.md"
  EXPECTED="$dir/expected.md"

  if [[ -f "$EXPECTED" ]]; then
    FIXTURE_NAME="$(basename "$dir")"
    echo "→ Testing fixture: $FIXTURE_NAME"

    cp "$README" "$README.tmp"

    # Always restore README on exit from this iteration
    trap cleanup_fixture EXIT

    node "$CLI" $DEBUG_FLAG "$README" 2>/dev/null

    if ! diff "$README" "$EXPECTED"; then
      echo
      echo "✖ FIXTURE FAILED: $FIXTURE_NAME"
      echo "----------------------------------------"
      diff "$README" "$EXPECTED"
      echo "----------------------------------------"
      exit 1
    fi

    # Success path cleanup
    cleanup_fixture
    trap - EXIT
  else
    echo "→ Skipping $(basename "$dir") (no expected.md)"
  fi
done

echo "✔ Positive fixture tests passed"
echo

# ------------------------------------------------------------
# Negative test 1: missing markdown file
# ------------------------------------------------------------

echo "========================================"
echo " Negative test: missing markdown file"
echo "========================================"

MISSING_FILE="/tmp/not-there-file-$$.md"

set +e
OUTPUT="$(node "$CLI" $DEBUG_FLAG "$MISSING_FILE" 2>&1)"
STATUS=$?
set -e

if [[ "$STATUS" -eq 0 ]]; then
  echo "ERROR: Expected non-zero exit for missing file"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "Unable to read markdown file"; then
  echo "ERROR: Expected 'Unable to read markdown file' message"
  echo "Actual output:"
  echo "$OUTPUT"
  exit 1
fi

echo "✔ Missing file test passed"
echo

# ------------------------------------------------------------
# Negative test 2: missing TOC delimiters
# ------------------------------------------------------------

echo "========================================"
echo " Negative test: missing TOC delimiters"
echo "========================================"

NO_TOC_FILE="/tmp/no-toc-$$.md"

cat > "$NO_TOC_FILE" <<'EOF'
# No TOC Here

## Intro
## Usage
EOF

set +e
OUTPUT="$(node "$CLI" $DEBUG_FLAG "$NO_TOC_FILE" 2>&1)"
STATUS=$?
set -e

rm -f "$NO_TOC_FILE"

if [[ "$STATUS" -eq 0 ]]; then
  echo "ERROR: Expected non-zero exit for missing TOC delimiters"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "TOC delimiters not found"; then
  echo "ERROR: Expected 'TOC delimiters not found' message"
  echo "Actual output:"
  echo "$OUTPUT"
  exit 1
fi

echo "✔ Missing TOC delimiters test passed"
echo

# ------------------------------------------------------------
# Negative test 3: unreadable file (permissions)
# ------------------------------------------------------------

echo "========================================"
echo " Negative test: unreadable markdown file"
echo "========================================"

UNREADABLE_FILE="/tmp/unreadable-$$.md"

cat > "$UNREADABLE_FILE" <<'EOF'
# Unreadable File

<!-- TOC:START -->
<!-- TOC:END -->

## Intro
EOF

chmod 000 "$UNREADABLE_FILE"

set +e
OUTPUT="$(node "$CLI" $DEBUG_FLAG "$UNREADABLE_FILE" 2>&1)"
STATUS=$?
set -e

chmod 644 "$UNREADABLE_FILE"
rm -f "$UNREADABLE_FILE"

if [[ "$STATUS" -eq 0 ]]; then
  echo "ERROR: Expected non-zero exit for unreadable file"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "Unable to read markdown file"; then
  echo "ERROR: Expected 'Unable to read markdown file' message"
  echo "Actual output:"
  echo "$OUTPUT"
  exit 1
fi

echo "✔ Unreadable file test passed"
echo

echo "========================================"
echo " ✅ ALL FIXTURE TESTS PASSED"
echo "========================================"

