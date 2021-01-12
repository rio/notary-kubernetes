#!/bin/sh

set -eux

if [ "$OSTYPE" = "linux-gnu" ]; then
    K3D_URL=https://github.com/rancher/k3d/releases/download/v3.4.0/k3d-linux-amd64
    SHASUM=1c961f1161d7b7fb55658ee32081b250a0da6d5f81e40c307a0300e3e130d19f

elif [ "$OSTYPE" = "darwin" ]; then
    K3D_URL=https://github.com/rancher/k3d/releases/download/v3.4.0/k3d-darwin-amd64
    SHASUM=54b9b855eddcc3408fbd4f16eaafa6fffd54b17b7224ebe469ce0b2afe9e674c

fi

wget -qO k3d "${K3D_URL}"
echo "${SHASUM}  k3d" | sha256sum -c -
chmod +x k3d
