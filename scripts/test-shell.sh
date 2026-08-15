#!/bin/bash
set -e

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

sh -n startup.sh healthcheck.sh
bash -n scripts/compare-versions.sh scripts/notify.sh

assert_compare() {
  actual=$(scripts/compare-versions.sh "$1" "$2")
  expected="$1 $3 $2"
  if [ "$actual" != "$expected" ]; then
    echo "Expected '$expected', got '$actual'" >&2
    exit 1
  fi
}

assert_compare 1.16.3 1.16.2 '>'
assert_compare 1.16 1.16.0 '='
assert_compare 0001.016.000 1.16 '='
assert_compare 18446744073709551616 1 '>'

if scripts/compare-versions.sh '1 2' 1.0 >/dev/null 2>&1; then
  echo "Invalid version was accepted" >&2
  exit 1
fi

echo "Shell checks passed."
