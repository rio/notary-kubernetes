#!/bin/sh

set -eu

cd "$(dirname $0)/.."

export GLOBAL_TIMEOUT=5m

echo "### Installing cert-manager"
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
    echo -e "\n ### Adding required helm repos"
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo add traefik https://helm.traefik.io/traefik
    helm repo update

    echo -e "\n #### Installing traefik using helm cli"
    helm upgrade --install --namespace traefik-system --create-namespace --wait traefik traefik/traefik --version 9.12.3

    cat > mariadb-values.yaml <<EOF
auth:
    rootPassword: root

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

    echo -e "\n #### Installing mariadb using helm cli"
    helm upgrade --install --namespace mariadb --create-namespace --wait mariadb bitnami/mariadb --version 9.2.2 --values mariadb-values.yaml
fi

echo -e "\n### Waiting for cert-manager to report ready"
kubectl wait --for=condition=Available deployments --all --namespace cert-manager   --timeout=${GLOBAL_TIMEOUT}

echo -e "\n### Deploying notary and registry"
kustomize build deploy/notary-registry | kubectl apply -f -

echo -e "\n### Waiting for migration job to complete"
kubectl wait --for=condition=Complete  jobs        --all --namespace notary --timeout=${GLOBAL_TIMEOUT}

echo -e "\n### Waiting for deployments to report ready"
kubectl wait --for=condition=Available deployments --all --namespace notary --timeout=${GLOBAL_TIMEOUT}