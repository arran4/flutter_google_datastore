#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
pubspec="$temp_dir/pubspec.yaml"

printf 'name: smoke_test\nversion: 1.0.0+1\ndescription: example\n' > "$pubspec"
bash "$script_dir/set_pubspec_version.sh" "2.3.4-rc.1+5" "$pubspec"
grep -Fxq 'version: 2.3.4-rc.1+5' "$pubspec"
grep -Fxq 'description: example' "$pubspec"

bash "$script_dir/set_pubspec_version.sh" "1.2.3" "$pubspec"
grep -Fxq 'version: 1.2.3' "$pubspec"

if bash "$script_dir/set_pubspec_version.sh" 'invalid&version' "$pubspec"; then
  echo "Invalid version unexpectedly accepted" >&2
  exit 1
fi
grep -Fxq 'version: 1.2.3' "$pubspec"

printf 'name: smoke_test\n' > "$pubspec"
if bash "$script_dir/set_pubspec_version.sh" '1.2.3' "$pubspec"; then
  echo "Missing version field unexpectedly accepted" >&2
  exit 1
fi
echo "pubspec version helper tests passed"
