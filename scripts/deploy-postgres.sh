#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

printf "\n### Deploying postgres\n\n"
helm upgrade --install --namespace notary --create-namespace notary --repo https://charts.bitnami.com/bitnami postgresql --version 10.2.4 --values - > /dev/null <<EOF
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
    create_signer_database.sql: |
        CREATE USER signer;
        CREATE DATABASE notarysigner WITH OWNER signer;
        GRANT ALL ON notarysigner TO signer;

        CREATE USER server;
        CREATE DATABASE notaryserver WITH OWNER server;
        GRANT ALL ON notaryserver TO server;
EOF

printf "\n"
helm list --namespace notary
