#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$ROOT/bin/update-markdown-toc.js"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "========================================"
echo " CRLF vs LF line ending stability tests"
echo "========================================"
echo

FILE="$TMPDIR/crlf.md"

# ------------------------------------------------------------
# Create CRLF file explicitly
# ------------------------------------------------------------

printf '# CRLF Example\r\n\r\n<!-- TOC:START -->\r\n<!-- TOC:END -->\r\n\r\n## Intro\r\n## Usage\r\n' > "$FILE"

# Sanity check: file really contains CRLF
if ! grep -q $'\r$' "$FILE"; then
  echo "ERROR: test setup failed — file is not CRLF"
  exit 1
fi

# ------------------------------------------------------------
# Run tool
# ------------------------------------------------------------

node "$CLI" "$FILE" >/dev/null

# ------------------------------------------------------------
# Assert: still CRLF everywhere
# ------------------------------------------------------------

if grep -n $'\r$' "$FILE" >/dev/null; then
  echo "✔ CRLF preserved"
else
  echo "ERROR: CRLF was not preserved"
  echo
  echo "File contents (showing line endings):"
  sed -n l "$FILE"
  exit 1
fi


# ------------------------------------------------------------
# Guard: ensure all newlines are CRLF (no bare LF)
# ------------------------------------------------------------

LF_COUNT="$(tr -cd '\n' < "$FILE" | wc -c)"
CRLF_COUNT="$(grep -o $'\r\n' "$FILE" | wc -l)"

if [[ "$LF_COUNT" -ne "$CRLF_COUNT" ]]; then
  echo "ERROR: mixed or LF-only line endings detected"
  echo
  echo "LF count:    $LF_COUNT"
  echo "CRLF count:  $CRLF_COUNT"
  echo
  sed -n l "$FILE"
  exit 1
fi


echo
echo "========================================"
echo " ✅ CRLF LINE ENDING TESTS PASSED"
echo "========================================"
