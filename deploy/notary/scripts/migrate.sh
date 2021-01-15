#!/bin/sh

set -eux

apk add -q git

git clone --depth 1 --branch v0.6.1 https://github.com/theupdateframework/notary.git

until migrate -path=notary/migrations/server/mysql -database=mysql://${NOTARY_SERVER_STORAGE_DB_URL} up; do
        sleep 1
done

until migrate -path=notary/migrations/signer/mysql -database=mysql://${NOTARY_SIGNER_STORAGE_DB_URL} up; do
        sleep 1
done