#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# Test-harness flags
# ------------------------------------------------------------

TEST_VERBOSE=false

for arg in "$@"; do
  case "$arg" in
    -v|--verbose)
      TEST_VERBOSE=true
      ;;
  esac
done

# ------------------------------------------------------------
# Harness helpers
# ------------------------------------------------------------

run() {
  if $TEST_VERBOSE; then
    echo "[run] $*"
  fi
  "$@"
}

normalize() {
  if [[ $# -gt 0 ]]; then
    printf '%s' "$1"
  else
    cat
  fi | sed -e ':a' -e '/\n$/{$d;N;ba}'
}

filter_run_lines() {
  grep -v '^\[run\] '
}

strip_status() {
  sed -E 's/^(Updated|Up-to-date|Skipped \(no markers\)|Stale):\s+//'
}

