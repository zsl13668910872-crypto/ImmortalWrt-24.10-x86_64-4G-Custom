#!/bin/sh
# Install the latest Open-Box release using the project's official main installer.
# Designed to run only when the user explicitly requests Open-Box.
set -eu

TMP=/tmp/openbox-install-latest.sh
BASES="https://gh-proxy.org/https://raw.githubusercontent.com https://gh-proxy.com/raw.githubusercontent.com https://ghproxy.net/https://raw.githubusercontent.com https://ghfast.top/raw.githubusercontent.com https://gh.llkk.cc/raw.githubusercontent.com"

ok=0
for base in $BASES; do
    url="$base/liandu2024/Open-Box/main/scripts/install.sh"
    echo "[Open-Box] 获取最新官方安装器：$url"
    rm -f "$TMP"
    if curl -L --fail --connect-timeout 10 --max-time 300 --retry 5 --retry-delay 3 --retry-all-errors "$url" -o "$TMP"; then
        if head -n 1 "$TMP" | grep -q '^#!/bin/sh$' && \
           grep -q 'REPO="liandu2024/Open-Box"' "$TMP" && \
           grep -q 'releases/latest/download' "$TMP"; then
            ok=1
            break
        fi
    fi
done

[ "$ok" -eq 1 ] || { echo '[Open-Box] 获取最新安装器失败。' >&2; exit 1; }
chmod 700 "$TMP"
sh "$TMP" --mirror --port 3036

for svc in /etc/init.d/openbox /etc/init.d/open-box; do
    if [ -x "$svc" ]; then
        "$svc" stop >/dev/null 2>&1 || true
        "$svc" disable >/dev/null 2>&1 || true
    fi
done

if [ -f /opt/open-box/meta.json ]; then
    ver=$(sed -n 's/.*"version" *: *"\([^"]*\)".*/\1/p' /opt/open-box/meta.json | head -n1 || true)
    echo "[Open-Box] 已安装最新 release：${ver:-unknown}；当前保持 disabled。"
else
    echo '[Open-Box] 安装完成，但未读取到 meta.json 版本。'
fi
