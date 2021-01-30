#!/usr/bin/env bash

set -euo pipefail

if [ "$OSTYPE" != "linux-gnu" ] || [ "$OSTYPE" != "linux-musl" ]; then
    printf "This script only works on linux but we've detected $OSTYPE.\n"
    exit 1
fi

function detect_download_tool() {
    if ! command -v curl > /dev/null ; then
        printf "curl not found.\n"
        exit 1
    fi
}


function make_bin_and_cd() {
    # move to the repo root
    cd "$(dirname $0)/.."

    if ! [ -d bin ]; then
        mkdir bin
    fi

    cd bin
}

NOTARY_URL=https://github.com/theupdateframework/notary/releases/download/v0.6.1/notary-Linux-amd64
NOTARY_SHASUM=73353b2b4b85604c738a6800465133cb3a828dff0aa26f3c0926dd9a73e19879

KUSTOMIZE_URL=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.8.9/kustomize_v3.8.9_linux_amd64.tar.gz
KUSTOMIZE_SHASUM=eb81252cc5dca85660639b224da34c118308435f53f4d74a5094d88dfcb185ac

K3D_URL=https://github.com/rancher/k3d/releases/download/v3.4.0/k3d-linux-amd64
K3D_SHASUM=1c961f1161d7b7fb55658ee32081b250a0da6d5f81e40c307a0300e3e130d19f

KUBECTL_URL=https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubectl
KUBECTL_SHASUM=a5895007f331f08d2e082eb12458764949559f30bcc5beae26c38f3e2724262c

HELM_URL=https://get.helm.sh/helm-v3.4.2-linux-amd64.tar.gz
HELM_BINARY_PATH=linux-amd64/helm
HELM_SHASUM=d14d54d59558caebe234500f541fc2064b08d725ed8aa76f957f91c8d6a0fc46

function validate_binary() {
    echo "$1  $2" | sha256sum -c -
    chmod +x $2
}

function download_required() {
    printf "## Downloading binaries\n"
    printf "kubectl\t\t"
    curl -sSfLo kubectl $KUBECTL_URL
    printf "DONE\n"

    printf "kustomize\t"
    curl -sSfL $KUSTOMIZE_URL | tar xz
    printf "DONE\n"

    printf "helm\t\t"
    curl -sSfL $HELM_URL | tar xzOf - ${HELM_BINARY_PATH} > helm
    printf "DONE\n"

    printf "k3d\t\t"
    curl -sSfLo k3d $K3D_URL
    printf "DONE\n"

    printf "notary\t\t"
    curl -sSfLo notary $NOTARY_URL
    printf "DONE\n"

    printf "\n## Validating binaries\n"
    validate_binary $KUBECTL_SHASUM kubectl
    validate_binary $KUSTOMIZE_SHASUM kustomize
    validate_binary $HELM_SHASUM helm
    validate_binary $K3D_SHASUM k3d
    validate_binary $NOTARY_SHASUM notary
}

function print_path_message() {
    printf "\nDo not forget to add the $PWD directory to your path so other\n\
scripts can use these binaries. Run the following command in the root of\n\
this repository to enable the bin folder for this terminal.\n\n export PATH=\$PATH:\$PWD/bin\n"
}

detect_download_tool
make_bin_and_cd
download_required
print_path_message