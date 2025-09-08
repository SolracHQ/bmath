#!/usr/bin/env bash
# Simple fail-fast test runner for bmath tests
# Usage: ./run_tests.sh  (run from this folder or call the script directly)

set -u

# Resolve script directory (so paths work when invoked from anywhere)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BM_BIN="$SCRIPT_DIR/../bin/bm"

ensure_bm() {
  if [ -x "$BM_BIN" ]; then
    return 0
  fi

  echo "Executable $BM_BIN not found. Attempting to build with nimble..."
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  (cd "$PROJECT_ROOT" && nimble build bm) || {
    echo "nimble build failed. Ensure nimble is installed and the project builds." >&2
    return 1
  }

  if [ ! -x "$BM_BIN" ]; then
    echo "Build finished but $BM_BIN still missing or not executable." >&2
    return 2
  fi

  return 0
}

main() {
  if ! ensure_bm; then
    exit 2
  fi

  shopt -s nullglob
  local any=0
  for testfile in "$SCRIPT_DIR"/*.bm; do
    any=1
    echo -e "\n=== Running: $(basename "$testfile") ==="
    "$BM_BIN" -f:"$testfile"
    rc=$?
    if [ $rc -ne 0 ]; then
      echo -e "\nFAIL: $(basename "$testfile") (exit code: $rc)" >&2
      exit $rc
    else
      echo "OK: $(basename "$testfile")"
    fi
  done

  if [ $any -eq 0 ]; then
    echo "No .bm test files found in $SCRIPT_DIR" >&2
    exit 3
  fi

  echo -e "\nAll tests passed."
}

main "$@"
