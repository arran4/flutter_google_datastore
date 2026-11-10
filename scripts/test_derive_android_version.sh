#!/usr/bin/env bash
set -euo pipefail
helper="$(cd "$(dirname "$0")" && pwd)/derive_android_version.sh"

assert_version() {
  local actual
  actual=$(bash "$helper" "$1")
  if [[ $actual != "$2" ]]; then
    echo "Expected $1 -> $2, got $actual" >&2
    exit 1
  fi
}

assert_invalid() {
  if bash "$helper" "$1" >/dev/null 2>&1; then
    echo "Unexpectedly accepted invalid version: $1" >&2
    exit 1
  fi
}

assert_version 0.1.42 0.1.42+1042999
assert_version 0.2.0 0.2.0+2000999
assert_version 1.0.0 1.0.0+100000999
assert_version 0.1.43-alpha.1 0.1.43-alpha.1+1043001
assert_version 0.1.43-test.1 0.1.43-test.1+1043301
assert_version 0.1.43-beta.1 0.1.43-beta.1+1043501
assert_version 0.1.43-rc.1 0.1.43-rc.1+1043701
assert_version 0.1.43 0.1.43+1043999
assert_version 1.0.0+1 1.0.0+1
assert_invalid '0.1.42+abc'
assert_invalid 0.1.42-rc.300
assert_invalid 0.1.1000
assert_invalid 21.0.0
assert_version 0.0.0-rc 0.0.0-rc+700
assert_invalid 0.0.0-alpha
assert_invalid 1.0.0+0
echo "Android release version tests passed"
