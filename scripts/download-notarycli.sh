#!/bin/sh

set -eux

if [ "$OSTYPE" = "linux-gnu" ]; then
    NOTARY_URL=https://github.com/theupdateframework/notary/releases/download/v0.6.1/notary-Linux-amd64
    SHASUM=73353b2b4b85604c738a6800465133cb3a828dff0aa26f3c0926dd9a73e19879

elif [ "$OSTYPE" = "darwin" ]; then
    NOTARY_URL=https://github.com/theupdateframework/notary/releases/download/v0.6.1/notary-Darwin-amd64
    SHASUM=9593cc0a341e7fe1d01e6834e9964558318a8679c058b6da755b8608dbeac3de

fi

wget -qO notary ${NOTARY_URL}
echo "${SHASUM}  notary" | sha256sum -c -
chmod +x notary
