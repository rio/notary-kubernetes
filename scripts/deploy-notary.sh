#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

GLOBAL_TIMEOUT=5m

printf "## Timeout when deploying Notary and the registry: ${GLOBAL_TIMEOUT}\n\n"

printf "### Deploying notary and registry\n\n"
kustomize build deploy | kubectl apply -f -

printf "\n### Waiting for deployments to report ready\n\n"
kubectl wait --for=condition=Available deployments --all --namespace notary --timeout=${GLOBAL_TIMEOUT}

printf "\n## Deploying notary and registry complete\n\n"