#!/bin/sh

set -eux

if [ "$OSTYPE" = "linux-gnu" ]; then
    KUSTOMIZE_URL=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.8.9/kustomize_v3.8.9_linux_amd64.tar.gz
    SHASUM=eb81252cc5dca85660639b224da34c118308435f53f4d74a5094d88dfcb185ac

elif [ "$OSTYPE" = "darwin" ]; then
    KUSTOMIZE_URL=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.8.9/kustomize_v3.8.9_darwin_amd64.tar.gz
    SHASUM=08fc96342720c1c438175888f0555f9bb4cca197829c699057a86607dc383564
fi

wget -qO- ${KUSTOMIZE_URL} | tar xz
echo "${SHASUM}  kustomize" | sha256sum -c -
chmod +x kustomize
