#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

GLOBAL_TIMEOUT=5m

printf "## Timeout when deploying dependencies: ${GLOBAL_TIMEOUT}\n\n"

printf "### Deploying cert-manager\n\n"
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml

printf "\n### Deploying traefik\n\n"
helm upgrade --install --namespace traefik-system --create-namespace traefik --repo https://helm.traefik.io/traefik traefik --version 9.12.3 > /dev/null
printf "\n"
helm list --namespace traefik-system

printf "### Deploying mariadb\n\n"
# work around to make this script idempotent. The helm chart doesn't allow
# running an upgrade without providing it the root password.
if kubectl get secret mariadb --namespace mariadb > /dev/null 2>&1 ; then
    printf "Found mariadb secret, reusing root password\n"
    MARIADB_ROOT_PASSWORD_VALUES_BLOCK="
auth:
    rootPassword: $(kubectl get secret mariadb --namespace mariadb -o jsonpath='{.data.mariadb-root-password}' | base64 -d)
"
fi

helm upgrade --install --namespace mariadb --create-namespace mariadb --repo https://charts.bitnami.com/bitnami mariadb --version 9.2.2 --values - > /dev/null <<EOF
${MARIADB_ROOT_PASSWORD_VALUES_BLOCK:-}

primary:
    persistence:
        enabled: false

initdbScripts:
    create_signer_database.sql: |
        CREATE DATABASE IF NOT EXISTS notarysigner;
        CREATE USER 'signer'@'%' IDENTIFIED BY 'signer';
        GRANT ALL PRIVILEGES ON notarysigner.* TO 'signer'@'%';

    create_server_database.sql: |
        CREATE DATABASE IF NOT EXISTS notaryserver;
        CREATE USER 'server'@'%' IDENTIFIED BY 'server';
        GRANT ALL PRIVILEGES ON notaryserver.* TO 'server'@'%';
EOF

helm list --namespace mariadb

printf "### Waiting for traefik to report ready\n\n"
kubectl wait --for=condition=Available deployments --all --namespace traefik-system  --timeout=${GLOBAL_TIMEOUT}

printf "\n### Waiting for mariadb to report ready\n\n"
kubectl rollout status statefulsets/mariadb --namespace mariadb --timeout=${GLOBAL_TIMEOUT}

printf "\n## Deploying dependencies complete\n\n"