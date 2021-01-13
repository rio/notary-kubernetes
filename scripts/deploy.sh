#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

GLOBAL_TIMEOUT=5m

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

    if [ -z "${USE_HELM_OPERATOR:-}" ]; then
        printf "USE_HELM_OPERATOR not set to 'yes' checking for the helm binary.\n"
        if ! command -v helm > /dev/null ; then
            printf "The helm binary cannot be found.\n"
            fail="true"
        fi
    fi

    if $fail = "true" ; then
        printf "Check that the required tools are installed in your PATH.\n"
        printf "You can use the 'download-tools.sh' script in the scripts directory to download any missing tools.\n"
        exit 1
    fi

    printf "All required binaries found.\n\n"
}

preflight_check

printf "### Installing cert-manager"
kustomize build deploy/dependencies/cert-manager | kubectl apply -f -

if [ "${USE_HELM_OPERATOR:-}" = "yes" ]; then
    echo -e "\n### Installing traefik using HelmChart resources"
    kubectl apply -f deploy/dependencies/traefik.yaml

    echo -e "\n### Installing mariadb using HelmChart resources"
    kubectl apply -f deploy/dependencies/mariadb.yaml

    echo -e "\n#### Waiting for helm charts to deploy"
    kubectl wait --for=condition=Complete  jobs --all --namespace traefik-system --timeout=${GLOBAL_TIMEOUT}
    kubectl wait --for=condition=Complete  jobs --all --namespace mariadb        --timeout=${GLOBAL_TIMEOUT}

    echo -e "\n#### Waiting for traefik to report ready"
    kubectl wait --for=condition=Available deployments --all --namespace traefik-system --timeout=${GLOBAL_TIMEOUT}

else
    echo -e "\n### Adding required helm repos"
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add traefik https://helm.traefik.io/traefik
    helm repo update

    echo -e "\n#### Installing traefik using helm cli"
    helm upgrade --install --namespace traefik-system --create-namespace traefik traefik/traefik --version 9.12.3

    cat > mariadb-values.yaml <<EOF
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

    echo -e "\n#### Installing mariadb using helm cli"
    helm upgrade --install --namespace mariadb --create-namespace mariadb bitnami/mariadb --version 9.2.2 --values mariadb-values.yaml
fi

echo -e "\n### Waiting for cert-manager to report ready"
kubectl wait --for=condition=Available deployments --all --namespace cert-manager   --timeout=${GLOBAL_TIMEOUT}

echo -e "\n### Deploying notary and registry"
kustomize build deploy/notary-registry | kubectl apply -f -

echo -e "\n### Waiting for migration job to complete"
kubectl wait --for=condition=Complete  jobs        --all --namespace notary --timeout=${GLOBAL_TIMEOUT}

echo -e "\n### Waiting for deployments to report ready"
kubectl wait --for=condition=Available deployments --all --namespace notary --timeout=${GLOBAL_TIMEOUT}