#!/usr/bin/env bash
# Stage the complete release set. Exclude FastForge intermediate AppDirs and files.
set -euo pipefail

if (( $# != 3 )); then
  echo "usage: $0 TAG DOWNLOADED_DIR STAGING_DIR" >&2
  exit 64
fi

tag=$1
src=$2
dst=$3
if [[ ! $tag =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-z0-9]+(\.[0-9]+)?)?$ ]]; then
  echo "Invalid release tag: $tag" >&2
  exit 64
fi
version=${tag#v}

[[ -d $src ]] || { echo "Missing downloaded release artifacts: $src" >&2; exit 1; }
[[ ! -e $dst ]] || { echo "Staging output must not already exist: $dst" >&2; exit 1; }
mkdir -p "$dst"

suffixes=(
  android.aab
  android.apk
  linux.AppImage
  linux.deb
  linux.pacman
  linux.rpm
  linux.zip
  macos.dmg
  macos.pkg
  macos.zip
  web.zip
  windows-setup.exe
  windows.msix
  windows.zip
)

for suffix in "${suffixes[@]}"; do
  filename="flutter_google_datastore-${version}-$suffix"
  mapfile -d '' matches < <(find "$src" -type f -name "$filename" -print0)
  if (( ${#matches[@]} != 1 )); then
    echo "Expected exactly one $filename, found ${#matches[@]}" >&2
    exit 1
  fi
  if [[ ! -s ${matches[0]} ]]; then
    echo "Release asset is empty: ${matches[0]}" >&2
    exit 1
  fi
  cp -- "${matches[0]}" "$dst/$filename"
done

# Print checksums for the exact, flat files that will be uploaded.
(
  cd "$dst"
  sha256sum -- * | sort
)
echo "Staged ${#suffixes[@]} release assets for $tag"
