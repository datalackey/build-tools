#!/usr/bin/env bash
set -Eeuo pipefail

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
# Last-command tracking (for diagnostics)
# ------------------------------------------------------------

LAST_RUN_CMD=""

on_error() {
  echo
  echo "ERROR: test failed"
  if [[ -n "$LAST_RUN_CMD" ]]; then
    echo "Last command executed:"
    echo "  $LAST_RUN_CMD"
  else
    echo "No command was recorded"
  fi
}

trap on_error ERR

# ------------------------------------------------------------
# Harness helpers
# ------------------------------------------------------------

run() {
  LAST_RUN_CMD="$*"

  if $TEST_VERBOSE; then
    echo "[run] $*" >&2
  fi

  "$@"
}

# Run a command and capture stdout *without* losing diagnostics
run_capture() {
  LAST_RUN_CMD="$*"

  if $TEST_VERBOSE; then
    echo "[run] $*" >&2
  fi

  local tmp
  tmp="$(mktemp)"

  "$@" >"$tmp"

  cat "$tmp"
  rm -f "$tmp"
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


