#!/usr/bin/env bash
# Set Flutter's pubspec version without downloading a YAML tool.
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: bash scripts/set_pubspec_version.sh VERSION [PUBSPEC]" >&2
  exit 64
fi

version=$1
pubspec=${2:-pubspec.yaml}

# Only accept Flutter/Dart-style semantic versions. This also prevents
# characters with special meaning in sed replacement strings.
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
  echo "Invalid Flutter version: $version" >&2
  exit 64
fi

if [[ ! -f "$pubspec" || "$(grep -c '^version: ' "$pubspec" || true)" != 1 ]]; then
  echo "Expected exactly one top-level version field in $pubspec" >&2
  exit 1
fi

temp_file=$(mktemp "${pubspec}.XXXXXX")
trap 'rm -f "$temp_file"' EXIT
sed "s/^version: .*/version: ${version}/" "$pubspec" > "$temp_file"
mv "$temp_file" "$pubspec"
grep -Fxq "version: ${version}" "$pubspec"
