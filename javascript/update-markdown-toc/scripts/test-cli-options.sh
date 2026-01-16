# ------------------------------------------------------------
# Setup: markdown files for --check tests
# ------------------------------------------------------------

GOOD_MD="$TMPDIR/good.md"
STALE_MD="$TMPDIR/stale.md"
DIR_PATH="$TMPDIR/dir"

mkdir "$DIR_PATH"

cat > "$GOOD_MD" <<'EOF'
# Title

<!-- TOC:START -->
- [Title](#title)
  - [Section](#section)
<!-- TOC:END -->

## Section
EOF

cat > "$STALE_MD" <<'EOF'
# Title

<!-- TOC:START -->
<!-- TOC:END -->

## Section
EOF

# ------------------------------------------------------------
# Test: --check passes when TOC is correct
# ------------------------------------------------------------

echo "→ --check passes when TOC is correct"

node "$CLI" --check "$GOOD_MD"

echo "✔ --check passed for correct TOC"
echo

# ------------------------------------------------------------
# Test: --check fails when TOC is stale
# ------------------------------------------------------------

echo "→ --check fails when TOC is stale"

set +e
node "$CLI" --check "$STALE_MD"
STATUS=$?
set -e

if [[ "$STATUS" -eq 0 ]]; then
  echo "ERROR: Expected --check to fail for stale TOC"
  exit 1
fi

echo "✔ --check correctly detected stale TOC"
echo

