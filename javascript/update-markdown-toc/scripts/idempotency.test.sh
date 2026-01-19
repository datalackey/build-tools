#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$ROOT/bin/update-markdown-toc.js"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "========================================"
echo " Idempotency tests"
echo "========================================"
echo

FILE="$TMPDIR/README.md"

# ------------------------------------------------------------
# Initial markdown (stale TOC)
# ------------------------------------------------------------

cat > "$FILE" <<'EOF'
# Idempotency Example

<!-- TOC:START -->
<!-- TOC:END -->

## Intro
## Usage
EOF

# ------------------------------------------------------------
# First run: should update the file
# ------------------------------------------------------------

echo "→ first run updates the file"

FIRST_OUTPUT="$(
  node "$CLI" "$FILE"
)"

if ! echo "$FIRST_OUTPUT" | grep -q "Updated:"; then
  echo "ERROR: expected Updated: output on first run"
  echo "Actual output:"
  echo "$FIRST_OUTPUT"
  exit 1
fi

FIRST_HASH="$(sha256sum "$FILE" | awk '{print $1}')"

echo "✔ first run updated file"
echo

# ------------------------------------------------------------
# Second run: must be idempotent
# ------------------------------------------------------------

echo "→ second run is idempotent (no changes, no Updated:)"

SECOND_OUTPUT="$(
  node "$CLI" "$FILE"
)"

SECOND_HASH="$(sha256sum "$FILE" | awk '{print $1}')"

if [[ "$FIRST_HASH" != "$SECOND_HASH" ]]; then
  echo "ERROR: file changed on second run"
  echo
  echo "Before hash: $FIRST_HASH"
  echo "After hash:  $SECOND_HASH"
  echo
  diff -u <(sed -n l "$FILE") <(sed -n l "$FILE") || true
  exit 1
fi

if echo "$SECOND_OUTPUT" | grep -q "Updated:"; then
  echo "ERROR: second run emitted Updated:"
  echo
  echo "$SECOND_OUTPUT"
  exit 1
fi

echo "✔ second run made no changes"
echo

# ------------------------------------------------------------
# Third run: --verbose must say Up-to-date
# ------------------------------------------------------------

echo "→ third run with --verbose reports Up-to-date"

VERBOSE_OUTPUT="$(
  node "$CLI" --verbose "$FILE"
)"

EXPECTED="Up-to-date: $FILE"

if [[ "$VERBOSE_OUTPUT" != "$EXPECTED" ]]; then
  echo "ERROR: unexpected --verbose output"
  echo
  echo "Expected:"
  echo "$EXPECTED"
  echo
  echo "Actual:"
  echo "$VERBOSE_OUTPUT"
  exit 1
fi

echo "✔ --verbose reports Up-to-date correctly"
echo

echo "========================================"
echo " ✅ IDEMPOTENCY TESTS PASSED"
echo "========================================"
