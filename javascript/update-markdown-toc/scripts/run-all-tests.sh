#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$ROOT/scripts"

# ------------------------------------------------------------
# Parse driver-level tracing
# ------------------------------------------------------------

# TEST_TRACE controls whether executed commands are printed.
# It must never alter CLI behavior.
TEST_TRACE_FLAG=""

for arg in "$@"; do
  case "$arg" in
    --trace|--show-run)
      TEST_TRACE_FLAG="--trace"
      ;;
  esac
done

echo "========================================"
echo " Running update-markdown-toc test suite"
echo "========================================"
echo

echo "→ Running fixture tests"
bash "$SCRIPTS/with-fixtures-test.sh" $TEST_TRACE_FLAG
echo

echo "→ Running CLI contract tests"
bash "$SCRIPTS/cli-options-test.sh" $TEST_TRACE_FLAG
echo

echo "→ Running recursive traversal tests"
bash "$SCRIPTS/recursive-traversal-test.sh" $TEST_TRACE_FLAG
echo

echo "→ Running recursive leniency & continuation tests"
bash "$SCRIPTS/recursive-leniency-and-continuation.test.sh" $TEST_TRACE_FLAG
echo

echo "→ Running recursive output matrix tests"
bash "$SCRIPTS/recursive-output-matrix.test.sh" $TEST_TRACE_FLAG
echo

echo "→ Running CRLF line ending tests"
bash "$SCRIPTS/crlf-line-endings.test.sh" $TEST_TRACE_FLAG
echo

echo "========================================"
echo " ✅ ALL TESTS PASSED"
echo "========================================"

