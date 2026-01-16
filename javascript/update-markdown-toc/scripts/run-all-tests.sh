#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$ROOT/scripts"

echo "========================================"
echo " Running update-readme-toc test suite"
echo "========================================"
echo

echo "→ Running fixture tests"
bash "$SCRIPTS/with-fixtures-test.sh"
echo

echo "→ Running CLI contract tests"
bash "$SCRIPTS/cli-options-test.sh"
echo

echo "========================================"
echo " ✅ ALL TESTS PASSED"
echo "========================================"

