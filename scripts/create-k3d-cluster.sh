#!/usr/bin/env bash

set -euo pipefail

if ! command -v k3d > /dev/null ; then
    printf "k3d binary not found in path.\n"
    exit 1
fi

k3d cluster create --k3s-server-arg="--disable=traefik" --port "80:80@loadbalancer" --port "443:443@loadbalancer"