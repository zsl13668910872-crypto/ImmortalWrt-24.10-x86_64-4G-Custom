#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-$ROOT/.build}"
VERSION="24.10.6"
SRC="$WORK/immortalwrt"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing command: $1" >&2; exit 1; }; }
for c in git make gcc g++ rsync unzip zstd python3; do need "$c"; done

mkdir -p "$WORK"
if [ ! -d "$SRC/.git" ]; then
  git clone --branch "v$VERSION" --depth 1 https://github.com/immortalwrt/immortalwrt.git "$SRC"
else
  git -C "$SRC" fetch --depth 1 origin "v$VERSION"
  git -C "$SRC" checkout -f "v$VERSION"
fi

cp "$ROOT/config/seed.config" "$SRC/.config"
cat "$ROOT/scripts/prepare-feeds.sh" > "$SRC/scripts/prepare-custom-feeds.sh"
chmod +x "$SRC/scripts/prepare-custom-feeds.sh"
cp -a "$ROOT/files" "$SRC/custom-files"

cd "$SRC"
./scripts/prepare-custom-feeds.sh

make defconfig

# Feed/package preflight is intentionally non-fatal here; GitHub Actions will show the exact missing package.
set +e
make package/luci-app-openclash/compile package/luci-app-passwall/compile package/luci-app-passwall2/compile package/luci-app-nikki/compile package/luci-app-homeproxy/compile package/luci-app-mosdns/compile -j"$(nproc)" V=s
RC=$?
set -e
if [ "$RC" -ne 0 ]; then
  echo "Third-party package prebuild returned $RC; continue with full defconfig build to expose the exact failing dependency."
fi

make -j"$(nproc)" download V=s
make -j"$(nproc)" world V=s

mkdir -p "$SRC/files"
rsync -a "$ROOT/files/" "$SRC/files/"

mkdir -p "$ROOT/out"
find "$SRC/bin/targets/x86/64" -maxdepth 1 -type f -printf '%p\n' > "$ROOT/out/file-list.txt"
cp -f "$SRC/bin/targets/x86/64"/* "$ROOT/out/" 2>/dev/null || true
sha256sum "$ROOT/out"/* > "$ROOT/out/sha256sums.txt" 2>/dev/null || true
