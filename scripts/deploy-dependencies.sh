#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

GLOBAL_TIMEOUT=5m

printf "## Timeout when deploying dependencies: ${GLOBAL_TIMEOUT}\n\n"

scripts/deploy-cert-manager.sh
scripts/deploy-traefik.sh
scripts/deploy-postgres.sh

printf "\n## Deploying dependencies complete\n\n"

scripts/deploy-certificates.sh