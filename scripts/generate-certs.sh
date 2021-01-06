#!/bin/sh

set -eux

cd "$(dirname $0)/.."

if ! [[ -d certs ]] ; then
  mkdir -p certs/{server,signer}
fi

cd certs


step certificate create root-ca root-ca.crt root-ca.key --profile root-ca --insecure --no-password
step certificate create notaryserver server/notary-server.crt server/notary-server.key --no-password --profile=leaf --not-after=8760h --ca root-ca.crt --ca-key root-ca.key  --insecure --san lb.rio.wtf
step certificate create notarysigner signer/notary-signer.crt signer/notary-signer.key --no-password --profile=leaf --not-after=8760h --ca root-ca.crt --ca-key root-ca.key  --insecure

cp -v root-ca.crt server
cp -v root-ca.crt signer
cp -v server/notary-server.crt signer
