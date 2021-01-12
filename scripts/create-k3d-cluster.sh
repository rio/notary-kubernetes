#!/bin/sh

set -eux

k3d cluster create --k3s-server-arg="--disable=traefik" --port "80:80@loadbalancer" --port "443:443@loadbalancer"