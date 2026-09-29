#!/bin/sh
set -eu

cat >> feeds.conf.default <<'EOF_FEEDS'
# Third-party LuCI proxy apps for OpenWrt/ImmortalWrt 24.10
src-git openclash https://github.com/vernesong/OpenClash.git
src-git passwall https://github.com/Openwrt-Passwall/openwrt-passwall.git
src-git passwall2 https://github.com/Openwrt-Passwall/openwrt-passwall2.git
src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git
src-git mosdns https://github.com/sbwml/luci-app-mosdns.git
src-git homeproxy https://github.com/immortalwrt/homeproxy.git
EOF_FEEDS

./scripts/feeds update -a
./scripts/feeds install -a
