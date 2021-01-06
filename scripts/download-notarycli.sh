#!/bin/sh

set -eux

echo "downloading binary"
wget -q -O notary https://github.com/theupdateframework/notary/releases/download/v0.6.1/notary-Linux-amd64

echo "verifying integrity"
echo "73353b2b4b85604c738a6800465133cb3a828dff0aa26f3c0926dd9a73e19879  notary" | sha256sum -c -

echo "making executable" 
chmod +x notary
