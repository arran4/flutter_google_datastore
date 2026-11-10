#!/usr/bin/env bash
# Convert a release version into a Flutter version with a numeric Android build code.
# A given release tag always produces the same code, including on CI retries.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 VERSION" >&2
  exit 64
fi

version=$1
if [[ ! $version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-([a-z]+)(\.([0-9]+))?)?(\+([0-9]+))?$ ]]; then
  echo "Invalid Flutter release version: $version" >&2
  exit 64
fi

major=${BASH_REMATCH[1]}
minor=${BASH_REMATCH[2]}
patch=${BASH_REMATCH[3]}
channel=${BASH_REMATCH[5]}
sequence=${BASH_REMATCH[7]}
explicit_build=${BASH_REMATCH[9]}

# An explicit pubspec build code (e.g., 1.0.0+1) is already authoritative.
if [[ -n $explicit_build ]]; then
  if [[ ${#explicit_build} -gt 10 ]] || (( 10#$explicit_build < 1 || 10#$explicit_build > 2100000000 )); then
    echo "Android build number must be an integer between 1 and 2100000000" >&2
    exit 64
  fi
  printf '%s\n' "$version"
  exit 0
fi

# Space is reserved for 999 prerelease revisions per patch, with final builds
# greater than alpha/test/beta/rc builds of the same version.
# The ranges keep Android's maximum versionCode (2,100,000,000) intact.
if [[ ${#major} -gt 2 || ${#minor} -gt 2 || ${#patch} -gt 3 ]] ||
   (( 10#$major > 20 || 10#$minor > 99 || 10#$patch > 999 )); then
  echo "Version exceeds Android versionCode encoding limits (20.99.999)" >&2
  exit 64
fi

offset=999
if [[ -n $channel ]]; then
  case $channel in
    alpha) offset=0; max_sequence=299 ;;
    test)  offset=300; max_sequence=199 ;;
    beta)  offset=500; max_sequence=199 ;;
    rc)    offset=700; max_sequence=298 ;;
    *) echo "Unsupported prerelease channel: $channel" >&2; exit 64 ;;
  esac
  sequence=${sequence:-0}
  if [[ ${#sequence} -gt 3 ]] || (( 10#$sequence > max_sequence )); then
    echo "Prerelease sequence exceeds reserved Android versionCode range" >&2
    exit 64
  fi
  offset=$((offset + 10#$sequence))
fi

code=$(( ((10#$major * 100 + 10#$minor) * 1000 + 10#$patch) * 1000 + offset ))
if (( code < 1 || code > 2100000000 )); then
  echo "Android build number out of range: $code" >&2
  exit 64
fi
printf '%s+%s\n' "$version" "$code"
