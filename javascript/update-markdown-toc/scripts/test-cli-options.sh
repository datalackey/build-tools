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

if ! echo "$OUTPUT" | grep -q "update-readme-toc [options]"; then
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
# --check success / failure
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
# --check does not write or change timestamps
# ------------------------------------------------------------

echo "→ --check does not modify file"

ORIG_CONTENT="$(cat "$GOOD_MD")"
ORIG_MTIME="$(stat -c %Y "$GOOD_MD")"

(cd "$ROOT" && node "$CLI" --check "$GOOD_MD")

AFTER_CONTENT="$(cat "$GOOD_MD")"
AFTER_MTIME="$(stat -c %Y "$GOOD_MD")"

if [[ "$ORIG_CONTENT" != "$AFTER_CONTENT" ]]; then
  echo "ERROR: --check modified file contents"
  exit 1
fi

if [[ "$ORIG_MTIME" != "$AFTER_MTIME" ]]; then
  echo "ERROR: --check modified file timestamp"
  exit 1
fi

echo "✔ --check left file unchanged"
echo

# ------------------------------------------------------------
# --quiet suppresses output
# ------------------------------------------------------------

echo "→ --quiet suppresses output"

OUTPUT="$(cd "$ROOT" && node "$CLI" --check --quiet "$GOOD_MD")"

if [[ -n "$OUTPUT" ]]; then
  echo "ERROR: --quiet produced output"
  exit 1
fi

echo "✔ --quiet suppressed output"
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
echo " ✅ CLI CONTRACT TESTS PASSED"
echo "========================================"

