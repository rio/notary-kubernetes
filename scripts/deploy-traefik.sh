#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

GLOBAL_TIMEOUT=5m

printf "\n### Deploying traefik\n\n"
helm upgrade --install --namespace traefik-system --create-namespace traefik --repo https://helm.traefik.io/traefik traefik --version 9.13.0 --values - > /dev/null <<EOF
logs:
    access:
        enabled: true
EOF

printf "\n"
helm list --namespace traefik-system

printf "\n### Waiting for traefik to report ready\n"
kubectl wait --for=condition=Available deployments --all --namespace traefik-system  --timeout=${GLOBAL_TIMEOUT}