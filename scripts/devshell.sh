#!/usr/bin/env bash
# Open a shell in the verification container without VS Code
# (for terminal-only or JetBrains users). Run it from anywhere in the repo.
#
#   scripts/devshell.sh                 interactive shell
#   scripts/devshell.sh make -C tests/hello    run one command
#
# Set SEMITO_IMAGE to use another image, for example one you built locally:
#   SEMITO_IMAGE=semitov-verif:local scripts/devshell.sh

set -euo pipefail

IMAGE=${SEMITO_IMAGE:-ghcr.io/filippobrogi00/semitov-verif-env:latest}
REPO=$(cd "$(dirname "$0")/.." && pwd)

tty_flags=()
if [ -t 0 ] && [ -t 1 ]; then tty_flags=(-it); fi

user_flags=()
if [ "$(uname -s)" = "Linux" ] && [ "$(id -u)" != "1000" ]; then
  # Linux only: run as your own UID so files you create stay yours.
  # (Docker Desktop on macOS and Windows maps ownership by itself.)
  # In this mode `tap-up` won't work: use VS Code Dev Containers for Step 6.
  user_flags=(--user "$(id -u):$(id -g)" -e HOME=/tmp -e CCACHE_DIR=/tmp/ccache)
fi

# The ${arr[@]+...} form keeps macOS's old bash 3.2 happy with empty arrays.
exec docker run --rm ${tty_flags[@]+"${tty_flags[@]}"} ${user_flags[@]+"${user_flags[@]}"} \
  --cap-add=NET_ADMIN --device=/dev/net/tun \
  -v "$REPO":/work -w /work \
  "$IMAGE" "${@:-bash}"
