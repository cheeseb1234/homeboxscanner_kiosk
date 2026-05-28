#!/usr/bin/env bash
set -euo pipefail
WLAN="wlan0"
PING_TARGET="192.168.1.1"
if ! ip -4 addr show dev "$WLAN" | grep -q "inet "; then
  logger -t wifi-watchdog "wlan0 has no IP - restarting network"
  nmcli dev connect "$WLAN" 2>/dev/null || ifup "$WLAN" 2>/dev/null || true
  logger -t wifi-watchdog "network restart attempted"
  exit 1
fi
if ! ping -c1 -W3 "$PING_TARGET" >/dev/null 2>&1; then
  logger -t wifi-watchdog "gateway $PING_TARGET unreachable - restarting wpa"
  systemctl restart wpa_supplicant || true
  sleep 3
  ifup "$WLAN" 2>/dev/null || true
  exit 1
fi
exit 0
