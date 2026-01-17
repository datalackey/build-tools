#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$ROOT/scripts"

# ------------------------------------------------------------
# Parse driver-level verbosity
# ------------------------------------------------------------

TEST_VERBOSE_FLAG=""

for arg in "$@"; do
  case "$arg" in
    -v|--verbose)
      TEST_VERBOSE_FLAG="--verbose"
      ;;
  esac
done

echo "========================================"
echo " Running update-markdown-toc test suite"
echo "========================================"
echo

echo "→ Running fixture tests"
bash "$SCRIPTS/with-fixtures-test.sh" $TEST_VERBOSE_FLAG
echo

echo "→ Running CLI contract tests"
bash "$SCRIPTS/cli-options-test.sh" $TEST_VERBOSE_FLAG
echo

echo "→ Running recursive traversal tests"
bash "$SCRIPTS/recursive-traversal-test.sh" $TEST_VERBOSE_FLAG
echo

echo "→ Running recursive leniency & continuation tests"
bash "$SCRIPTS/recursive-leniency-and-continuation.test.sh" $TEST_VERBOSE_FLAG
echo

echo "========================================"
echo " ✅ ALL TESTS PASSED"
echo "========================================"

