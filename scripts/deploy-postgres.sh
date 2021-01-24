#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

# work around to make this script idempotent. The helm chart doesn't allow
# running an upgrade without providing it the root password.
if kubectl get secret notary-postgresql --namespace notary > /dev/null 2>&1 ; then
    printf "Found postgresql secret, reusing root password\n"
    POSTGRESS_PASSWORD_BLOCK="postgresqlPassword: $(kubectl get secret --namespace notary notary-postgresql -o jsonpath="{.data.postgresql-password}" | base64 -d)"
fi

printf "\n### Deploying postgres\n\n"
helm upgrade --install --namespace notary --create-namespace notary --repo https://charts.bitnami.com/bitnami postgresql --version 10.2.4 --values - > /dev/null <<EOF
${POSTGRESS_PASSWORD_BLOCK:-}

persistence:
  enabled: false
volumePermissions:
  enabled: true
tls:
  enabled: true
  certificatesSecret: postgres-tls
  certFilename: tls.crt
  certKeyFilename: tls.key
  certCAFilename: ca.crt
initdbScripts:
    create_databases.sql: |
        CREATE USER signer;
        CREATE DATABASE notarysigner WITH OWNER signer;
        GRANT ALL ON notarysigner TO signer;

        CREATE USER server;
        CREATE DATABASE notaryserver WITH OWNER server;
        GRANT ALL ON notaryserver TO server;
EOF

printf "\n"
helm list --namespace notary
