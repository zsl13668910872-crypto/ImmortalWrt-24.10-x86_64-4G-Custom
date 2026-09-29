#!/bin/sh
# Optional post-build helper for the user's PVE -> RouterOS -> ImmortalWrt side-router topology.
# This script is interactive on purpose: it will not silently change a LAN IP.
set -eu

LAN_IP="${1:-192.168.1.2}"
GATEWAY="${2:-192.168.1.1}"
MASK="255.255.255.0"

case "$LAN_IP" in
  *.*.*.*) ;;
  *) echo "Invalid LAN IP: $LAN_IP" >&2; exit 1;;
esac

uci set network.lan.proto='static'
uci set network.lan.ipaddr="$LAN_IP"
uci set network.lan.netmask="$MASK"
uci set network.lan.gateway="$GATEWAY"
uci -q delete network.lan.dns || true
uci add_list network.lan.dns="$GATEWAY"
uci add_list network.lan.dns='119.29.29.29'
uci set dhcp.lan.ignore='1'
uci commit network
uci commit dhcp

echo "Applied LAN=$LAN_IP/24 gateway=$GATEWAY. Network restart follows."
/etc/init.d/network restart
