#!/bin/sh

set -eux

if [ "$OSTYPE" = "linux-gnu" ]; then
    HELM_URL=https://get.helm.sh/helm-v3.4.2-linux-amd64.tar.gz
    BINARY_PATH=linux-amd64/helm
    SHASUM=d14d54d59558caebe234500f541fc2064b08d725ed8aa76f957f91c8d6a0fc46

elif [ "$OSTYPE" = "darwin" ]; then
    HELM_URL=https://get.helm.sh/helm-v3.4.2-darwin-amd64.tar.gz
    BINARY_PATH=darwin-amd64/helm
    SHASUM=71eae390246b1c6f4244d04aa7354d3a4d86e0c4e81ed5c967eb0bab47619870
fi

wget -qO- ${HELM_URL} | tar xzOf - ${BINARY_PATH} > helm
echo "${SHASUM}  helm" | sha256sum -c -
chmod +x helm
