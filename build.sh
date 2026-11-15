#!/usr/bin/env bash
# Bygger Claude Debug ISO i en archlinux-container. Resultatet hamnar i out/.
# Kräver Docker (mkarchiso behöver --privileged för loop-enheter och mounts).
set -euo pipefail
cd "$(dirname "$0")"

docker pull -q archlinux:latest >/dev/null
docker run --rm --privileged \
    -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
    -v "$PWD":/src \
    archlinux:latest bash /src/scripts/build-in-container.sh
