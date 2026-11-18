#!/usr/bin/env bash
# tap-up: create a TAP network interface inside the container so the
# simulated Ethernet MAC can exchange real frames with scripts on this
# machine (Step 6).
#
# Usage: tap-up [interface] [host-address/prefix]
# Defaults: tap0 and 192.168.1.100/24 (LiteX simulation's default host address).
# Needs the container started with --cap-add=NET_ADMIN --device=/dev/net/tun
# (already set in .devcontainer/devcontainer.json).

set -euo pipefail

IFACE=${1:-tap0}
ADDR=${2:-192.168.1.100/24}

if [ ! -c /dev/net/tun ]; then
  echo "error: /dev/net/tun is missing." >&2
  echo "Start the container with --cap-add=NET_ADMIN --device=/dev/net/tun." >&2
  exit 1
fi

if ip link show "$IFACE" >/dev/null 2>&1; then
  echo "$IFACE already exists"
else
  sudo ip tuntap add dev "$IFACE" mode tap user "$(id -un)"
fi
sudo ip addr replace "$ADDR" dev "$IFACE"
sudo ip link set "$IFACE" up
ip addr show "$IFACE"
