#!/bin/sh

set -eux

echo "downloading binary"
wget -qO- https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.8.9/kustomize_v3.8.9_linux_amd64.tar.gz | tar xz

echo "verifying integrity"
echo "eb81252cc5dca85660639b224da34c118308435f53f4d74a5094d88dfcb185ac  kustomize" | sha256sum -c -

echo "making executable" 
chmod +x kustomize
