#!/bin/sh

set -eux

echo "downloading binary"
wget -qO k3d https://github.com/rancher/k3d/releases/download/v3.4.0/k3d-linux-amd64

echo "verifying integrity"
echo "1c961f1161d7b7fb55658ee32081b250a0da6d5f81e40c307a0300e3e130d19f  k3d" | sha256sum -c -

echo "making executable" 
chmod +x k3d
