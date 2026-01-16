#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLI="$ROOT/bin/update-readme-toc.js"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# ------------------------------------------------------------
# Setup: markdown files
# ------------------------------------------------------------

GOOD_MD="$TMPDIR/good.md"
STALE_MD="$TMPDIR/stale.md"
NO_TOC_MD="$TMPDIR/no-toc.md"
DOCS_DIR="$TMPDIR/docs"

mkdir "$DOCS_DIR"

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

cat > "$NO_TOC_MD" <<'EOF'
# No TOC Here

## Intro
EOF

cp "$GOOD_MD" "$DOCS_DIR/good.md"
cp "$STALE_MD" "$DOCS_DIR/stale.md"
cp "$NO_TOC_MD" "$DOCS_DIR/no-toc.md"

# ------------------------------------------------------------
# --help
# ------------------------------------------------------------

echo "→ --help prints usage and exits 0"

OUTPUT="$(cd "$ROOT" && node "$CLI" --help)"
STATUS=$?

if [[ "$STATUS" -ne 0 ]]; then
  echo "ERROR: --help did not exit 0"
  exit 1
fi

if ! echo "$OUTPUT" | grep -q "update-readme-toc \[options\]"; then
  echo "ERROR: --help output missing usage text"
  exit 1
fi

echo "✔ --help works"
echo

# ------------------------------------------------------------
# Unknown flag
# ------------------------------------------------------------

echo "→ unknown flag errors"

set +e
OUTPUT="$(cd "$ROOT" && node "$CLI" --not-a-real-flag 2>&1)"
STATUS=$?
set -e

if [[ "$STATUS" -eq 0 ]]; then
  echo "ERROR: unknown flag should fail"
  exit 1
fi

echo "✔ unknown flag rejected"
echo

# ------------------------------------------------------------
# --check requires explicit target
# ------------------------------------------------------------

echo "→ --check requires a file or --recursive"

set +e
OUTPUT="$(cd "$ROOT" && node "$CLI" --check 2>&1)"
STATUS=$?
set -e

if [[ "$STATUS" -eq 0 ]]; then
  echo "ERROR: --check without target should fail"
  exit 1
fi

echo "✔ --check requires explicit target"
echo

# ------------------------------------------------------------
# --check success / failure (exit code only)
# ------------------------------------------------------------

echo "→ --check passes for correct TOC"
(cd "$ROOT" && node "$CLI" --check "$GOOD_MD")
echo "✔ correct TOC passed"
echo

echo "→ --check fails for stale TOC"

set +e
(cd "$ROOT" && node "$CLI" --check "$STALE_MD")
STATUS=$?
set -e

if [[ "$STATUS" -eq 0 ]]; then
  echo "ERROR: stale TOC not detected"
  exit 1
fi

echo "✔ stale TOC detected"
echo

# ------------------------------------------------------------
# NEW: --check + --verbose output tests
# ------------------------------------------------------------

echo "→ --check -v reports Stale and exits 1"

set +e
OUTPUT="$(cd "$ROOT" && node "$CLI" --check --verbose "$STALE_MD")"
STATUS=$?
set -e

if [[ "$STATUS" -ne 1 ]]; then
  echo "ERROR: expected exit code 1 for stale TOC"
  exit 1
fi

if [[ "$OUTPUT" != "Stale: $STALE_MD"$'\n' ]]; then
  echo "ERROR: unexpected output"
  echo "Expected: Stale: $STALE_MD"
  echo "Actual:"
  echo "$OUTPUT"
  exit 1
fi

echo "✔ stale file reported correctly"
echo

echo "→ --check -v reports Up-to-date and exits 0"

OUTPUT="$(cd "$ROOT" && node "$CLI" --check --verbose "$GOOD_MD")"
STATUS=$?

if [[ "$STATUS" -ne 0 ]]; then
  echo "ERROR: expected exit code 0 for clean TOC"
  exit 1
fi

if [[ "$OUTPUT" != "Up-to-date: $GOOD_MD"$'\n' ]]; then
  echo "ERROR: unexpected output"
  echo "Expected: Up-to-date: $GOOD_MD"
  echo "Actual:"
  echo "$OUTPUT"
  exit 1
fi

echo "✔ clean file reported correctly"
echo

# ------------------------------------------------------------
# NEW: --check + --quiet suppresses all output
# ------------------------------------------------------------

echo "→ --check -q suppresses output"

set +e
OUTPUT="$(cd "$ROOT" && node "$CLI" --check --quiet "$STALE_MD")"
STATUS=$?
set -e

if [[ "$STATUS" -ne 1 ]]; then
  echo "ERROR: expected exit code 1 for stale TOC"
  exit 1
fi

if [[ -n "$OUTPUT" ]]; then
  echo "ERROR: --quiet produced output"
  exit 1
fi

echo "✔ --quiet suppressed output"
echo

# ------------------------------------------------------------
# NEW: Guard test — no Updated: in --check output
# ------------------------------------------------------------

echo "→ guard: --check never emits 'Updated:'"

OUTPUT="$(cd "$ROOT" && node "$CLI" --check --verbose "$STALE_MD" 2>&1)"

if echo "$OUTPUT" | grep -q "Updated:"; then
  echo "ERROR: 'Updated:' appeared in --check output"
  echo "$OUTPUT"
  exit 1
fi

echo "✔ guard passed"
echo

# ------------------------------------------------------------
# --recursive validation (missing dir)
# ------------------------------------------------------------

echo "→ --recursive requires existing directory"

set +e
(cd "$ROOT" && node "$CLI" --recursive "$TMPDIR/does-not-exist")
STATUS=$?
set -e

if [[ "$STATUS" -eq 0 ]]; then
  echo "ERROR: --recursive should fail for missing dir"
  exit 1
fi

echo "✔ --recursive path validated"
echo

# ------------------------------------------------------------
# --recursive validation (file instead of directory)
# ------------------------------------------------------------

echo "→ --recursive rejects file path"

set +e
(cd "$ROOT" && node "$CLI" --recursive "$GOOD_MD")
STATUS=$?
set -e

if [[ "$STATUS" -eq 0 ]]; then
  echo "ERROR: --recursive should fail when given a file"
  exit 1
fi

echo "✔ --recursive correctly rejected file path"
echo

echo "========================================"
echo " ✅ CLI CONTRACT TESTS PASSED
echo "========================================"

