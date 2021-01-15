#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

if [ -d ./bin ]; then
    printf "Found bin directory in repository root, appending it to the PATH.\n"
    PATH=$PATH:$PWD/bin
fi

if ! command -v k3d > /dev/null ; then
    printf "k3d binary not found in path.\n"
    exit 1
fi

k3d cluster create --k3s-server-arg="--disable=traefik" --port "80:80@loadbalancer" --port "443:443@loadbalancer"