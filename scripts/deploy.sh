#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

printf "# Deploying dependencies\n\n"

./scripts/deploy-dependencies.sh

printf "# Deploying Notary and the registry\n\n"

./scripts/deploy-notary.sh

printf "# Deployment complete\n"