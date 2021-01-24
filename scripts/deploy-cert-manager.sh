#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

GLOBAL_TIMEOUT=5m

printf "### Deploying cert-manager\n\n"
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml