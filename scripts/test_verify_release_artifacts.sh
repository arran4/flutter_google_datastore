#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

src="$tmp/downloaded"
dst="$tmp/publish"
mkdir -p "$src/0.1.44"

for suffix in \
  android.aab android.apk \
  linux.AppImage linux.deb linux.pacman linux.rpm linux.zip \
  macos.dmg macos.pkg macos.zip \
  web.zip windows-setup.exe windows.msix windows.zip; do
  printf 'fixture-%s\n' "$suffix" > "$src/0.1.44/flutter_google_datastore-0.1.44-$suffix"
done

bash "$script_dir/verify_release_artifacts.sh" v0.1.44 "$src" "$dst" >/dev/null
test "$(find "$dst" -maxdepth 1 -type f | wc -l)" -eq 14

rm "$src/0.1.44/flutter_google_datastore-0.1.44-android.apk"
if bash "$script_dir/verify_release_artifacts.sh" v0.1.44 "$src" "$tmp/missing" >/dev/null 2>&1; then
  echo "Missing Android APK was accepted" >&2
  exit 1
fi

printf 'other\n' > "$src/0.1.44/flutter_google_datastore-0.1.44-android.apk"
mkdir -p "$src/duplicate"
cp "$src/0.1.44/flutter_google_datastore-0.1.44-linux.deb" "$src/duplicate/"
if bash "$script_dir/verify_release_artifacts.sh" v0.1.44 "$src" "$tmp/duplicate" >/dev/null 2>&1; then
  echo "Duplicate Linux DEB was accepted" >&2
  exit 1
fi
rm "$src/duplicate/flutter_google_datastore-0.1.44-linux.deb"

: > "$src/0.1.44/flutter_google_datastore-0.1.44-web.zip"
if bash "$script_dir/verify_release_artifacts.sh" v0.1.44 "$src" "$tmp/empty" >/dev/null 2>&1; then
  echo "Zero-byte web artifact was accepted" >&2
  exit 1
fi

echo "Release asset verifier tests passed"
