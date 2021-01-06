#!/bin/sh

set +eux

cd "$(dirname $0)/.."

docker stack up -c docker-compose.yaml notary