#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

GLOBAL_TIMEOUT=5m

if [ -d ./bin ]; then
    printf "Found bin directory in repository root, appending it to the PATH.\n"
    PATH=$PATH:$PWD/bin
fi

function preflight_check() {
    fail="false"

    printf "Checking if kubectl is installed.\n"
    if ! command -v kubectl > /dev/null ; then
        printf "The kubectl binary cannot be found.\n"
        fail="true"
    fi

    printf "Checking if kustomize is installed.\n"
    if ! command -v kustomize > /dev/null ; then
        printf "The kustomize binary cannot be found.\n"
        fail="true"
    fi

    printf "Checking if helm is installed.\n"
    if ! command -v helm > /dev/null ; then
        printf "The helm binary cannot be found.\n"
        fail="true"
    fi

    if $fail = "true" ; then
        printf "Check that the required tools are installed in your PATH.\n"
        printf "You can use the 'download-tools.sh' script in the scripts directory to download any missing tools.\n"
        exit 1
    fi

    printf "All required binaries found.\n\n"
}

preflight_check

printf "### Installing cert-manager\n"
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml

printf "#### Installing traefik using helm cli\n"
helm upgrade --install --namespace traefik-system --create-namespace traefik --repo https://helm.traefik.io/traefik traefik --version 9.12.3

echo -e "\n#### Installing mariadb using helm cli"
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

echo -e "\n### Waiting for traefik to report ready"
kubectl wait --for=condition=Available deployments --all --namespace traefik-system  --timeout=${GLOBAL_TIMEOUT}

echo -e "\n### Waiting for mariadb to report ready"
kubectl wait --for=condition=Ready pods mariadb-0 --namespace mariadb  --timeout=${GLOBAL_TIMEOUT}

echo -e "\n### Deploying notary and registry"
kustomize build deploy | kubectl apply -f -

echo -e "\n### Waiting for migration job to complete"
kubectl wait --for=condition=Complete  jobs        --all --namespace notary --timeout=${GLOBAL_TIMEOUT}

echo -e "\n### Waiting for deployments to report ready"
kubectl wait --for=condition=Available deployments --all --namespace notary --timeout=${GLOBAL_TIMEOUT}