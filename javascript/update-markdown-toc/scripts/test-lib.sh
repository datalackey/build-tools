#!/usr/bin/env bash
set -Eeuo pipefail

# ------------------------------------------------------------
# Test-harness flags
# ------------------------------------------------------------

# TEST_TRACE controls whether the exact command being executed
# is printed before it runs. This must NEVER affect CLI behavior.
TEST_TRACE=false

for arg in "$@"; do
  case "$arg" in
    --trace|--show-run)
      TEST_TRACE=true
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

  if $TEST_TRACE; then
    echo "[run] $*" >&2
  fi

  "$@"
}

run_expect_fail() {
  # Record the command exactly like run/run_capture
  LAST_RUN_CMD="$*"

  if $TEST_TRACE; then
    echo "[run] $*" >&2
  fi

  # Temporarily disable ERR trap and -e
  trap - ERR
  set +e

  "$@"
  local status=$?

  # Restore strictness
  set -e
  trap on_error ERR

  return $status
}

# Run a command and capture stdout *without* losing diagnostics
run_capture() {
  LAST_RUN_CMD="$*"

  if $TEST_TRACE; then
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


make_tmpdir() {
  local dir
  dir="$(mktemp -d)"

  if ! $TEST_TRACE; then
    trap "rm -rf '$dir'" EXIT
  else
    echo "[trace] preserving temp dir: $dir" >&2
  fi

  echo "$dir"
}

