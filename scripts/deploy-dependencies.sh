#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

GLOBAL_TIMEOUT=5m

printf "## Timeout when deploying dependencies: ${GLOBAL_TIMEOUT}\n\n"

scripts/deploy-cert-manager.sh
scripts/deploy-traefik.sh
scripts/deploy-postgres.sh

printf "\n### Waiting for dependencies to report ready\n"
kubectl wait --for=condition=Available deployments --all --namespace cert-manager  --timeout=${GLOBAL_TIMEOUT}
kubectl wait --for=condition=Available deployments --all --namespace traefik-system  --timeout=${GLOBAL_TIMEOUT}

printf "\n### Creating certificates\n\n"
kustomize build deploy/certificates | kubectl apply -f -

printf "\n## Deploying dependencies complete\n\n"