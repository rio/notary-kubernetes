#!/bin/sh

set -eux

apk add -q git

git clone --depth 1 --branch v0.6.1 https://github.com/theupdateframework/notary.git

NOTARY_SERVER_DB_URL='postgres://server@notary-postgresql:5432/notaryserver?sslmode=verify-full&sslrootcert=/certs/server/ca.crt&sslcert=/certs/server/tls.crt&sslkey=/certs/server/tls.key'
NOTARY_SIGNER_DB_URL='postgres://signer@notary-postgresql:5432/notarysigner?sslmode=verify-full&sslrootcert=/certs/signer/ca.crt&sslcert=/certs/signer/tls.crt&sslkey=/certs/signer/tls.key'

until migrate -path=notary/migrations/server/postgresql -database=${NOTARY_SERVER_DB_URL} up; do
        sleep 1
done

until migrate -path=notary/migrations/signer/postgresql -database=${NOTARY_SIGNER_DB_URL} up; do
        sleep 1
done