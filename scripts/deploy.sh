#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

GLOBAL_TIMEOUT=5m

printf "## Global timeout: ${GLOBAL_TIMEOUT}\n\n"

printf "### Installing cert-manager\n\n"
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml

printf "\n#### Installing traefik\n\n"
helm upgrade --install --namespace traefik-system --create-namespace traefik --repo https://helm.traefik.io/traefik traefik --version 9.12.3

printf "\n#### Installing mariadb\n\n"
helm upgrade --install --namespace mariadb --create-namespace mariadb --repo https://charts.bitnami.com/bitnami mariadb --version 9.2.2 --values - <<EOF
auth:
    rootPassword: root

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

printf "\n### Waiting for traefik to report ready\n\n"
kubectl wait --for=condition=Available deployments --all --namespace traefik-system  --timeout=${GLOBAL_TIMEOUT}

printf "\n### Waiting for mariadb to report ready\n\n"
kubectl rollout status statefulsets/mariadb --namespace mariadb --timeout=${GLOBAL_TIMEOUT}

printf "\n### Deploying notary and registry\n\n"
kustomize build deploy | kubectl apply -f -

printf "\n### Waiting for migration job to complete\n\n"
kubectl wait --for=condition=Complete  jobs        --all --namespace notary --timeout=${GLOBAL_TIMEOUT}

printf "\n### Waiting for deployments to report ready\n\n"
kubectl wait --for=condition=Available deployments --all --namespace notary --timeout=${GLOBAL_TIMEOUT}