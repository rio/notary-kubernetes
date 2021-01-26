#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

GLOBAL_TIMEOUT=5m

printf "## Deploying certificates\n\n"
kustomize build deploy/certificates | kubectl apply -f -

printf "\n### Waiting for certificates to report ready\n\n"
kubectl wait --for=condition=Ready certificates --all -n notary --timeout ${GLOBAL_TIMEOUT}