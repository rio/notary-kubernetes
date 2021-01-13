#!/usr/bin/env bash

set -euo pipefail

function usage() {
    cat <<EOF
download-tools (all|helm|kustomize|k3d|notary)

This script will download and verify a number of tools for you
into the current directory. It is tested for linux and mac.
EOF

    exit 1
}

curl_found="false"
wget_found="false"

function detect_download_tool() {
    if command -v curl > /dev/null ; then
        curl_found="true"

    elif command -v wget > /dev/null ; then
        wget_found="true"

    else
        printf "curl or wget not found.\n"
        exit 1
    fi
}

detect_download_tool


if [ "$OSTYPE" = "linux-gnu" ]; then
    NOTARY_URL=https://github.com/theupdateframework/notary/releases/download/v0.6.1/notary-Linux-amd64
    NOTARY_SHASUM=73353b2b4b85604c738a6800465133cb3a828dff0aa26f3c0926dd9a73e19879

    KUSTOMIZE_URL=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.8.9/kustomize_v3.8.9_linux_amd64.tar.gz
    KUSTOMIZE_SHASUM=eb81252cc5dca85660639b224da34c118308435f53f4d74a5094d88dfcb185ac

    K3D_URL=https://github.com/rancher/k3d/releases/download/v3.4.0/k3d-linux-amd64
    K3D_SHASUM=1c961f1161d7b7fb55658ee32081b250a0da6d5f81e40c307a0300e3e130d19f

    KIND_URL=https://github.com/kubernetes-sigs/kind/releases/download/v0.9.0/kind-linux-amd64
    KIND_SHASUM=35a640e0ca479192d86a51b6fd31c657403d2cf7338368d62223938771500dc8

    HELM_URL=https://get.helm.sh/helm-v3.4.2-linux-amd64.tar.gz
    HELM_BINARY_PATH=linux-amd64/helm
    HELM_SHASUM=d14d54d59558caebe234500f541fc2064b08d725ed8aa76f957f91c8d6a0fc46

elif [ "$OSTYPE" = "darwin" ]; then
    NOTARY_URL=https://github.com/theupdateframework/notary/releases/download/v0.6.1/notary-Darwin-amd64
    NOTARY_SHASUM=9593cc0a341e7fe1d01e6834e9964558318a8679c058b6da755b8608dbeac3de

    KUSTOMIZE_URL=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.8.9/kustomize_v3.8.9_darwin_amd64.tar.gz
    KUSTOMIZE_SHASUM=08fc96342720c1c438175888f0555f9bb4cca197829c699057a86607dc383564

    K3D_URL=https://github.com/rancher/k3d/releases/download/v3.4.0/k3d-darwin-amd64
    K3D_SHASUM=54b9b855eddcc3408fbd4f16eaafa6fffd54b17b7224ebe469ce0b2afe9e674c

    KIND_URL=https://github.com/kubernetes-sigs/kind/releases/download/v0.9.0/kind-darwin-amd64
    KIND_SHASUM=849034ffaea8a0e50f9153078890318d5863bafe01495418ea0ad037b518de90

    HELM_URL=https://get.helm.sh/helm-v3.4.2-darwin-amd64.tar.gz
    HELM_BINARY_PATH=darwin-amd64/helm
    HELM_SHASUM=71eae390246b1c6f4244d04aa7354d3a4d86e0c4e81ed5c967eb0bab47619870
fi

function validate_binary() {
    echo "$1  $2" | sha256sum -c -
    chmod +x $2
}

function download_notary() {
    printf "Downloading and validating Notary\n"

    if $wget_found = "true"; then
        wget -qO notary $NOTARY_URL
    elif $curl_found = "true"; then
        curl -sSfLo notary $NOTARY_URL
    fi

    validate_binary $NOTARY_SHASUM notary
}

function download_k3d() {
    printf "Downloading and validating k3d\n"

    if $wget_found = "true"; then
        wget -qO k3d $K3D_URL
    elif $curl_found = "true"; then
        curl -sSfLo k3d $K3D_URL
    fi

    validate_binary $K3D_SHASUM k3d
}

function download_kind() {
    printf "Downloading and validating kind\n"

    if $wget_found = "true"; then
        wget -qO kind $KIND_URL
    elif $curl_found = "true"; then
        curl -sSfLo kind $KIND_URL
    fi

    validate_binary $KIND_SHASUM kind
}

function download_kustomize() {
    printf "Downloading and validating Kustomize\n"

    if $wget_found = "true"; then
        wget -qO - $KUSTOMIZE_URL | tar xz
    elif $curl_found = "true"; then
        curl -sSfL $KUSTOMIZE_URL | tar xz
    fi

    validate_binary $KUSTOMIZE_SHASUM kustomize
}

function download_helm() {
    printf "Downloading and validating Helm\n"

    if $wget_found = "true"; then
        wget -qO - $HELM_URL | tar xzOf - ${HELM_BINARY_PATH} > helm
    elif $curl_found = "true"; then
        curl -sSfL $HELM_URL | tar xzOf - ${HELM_BINARY_PATH} > helm
    fi

    validate_binary $HELM_SHASUM helm
}


case "${1-}" in
    "all") 
        download_helm
        download_kustomize
        download_notary
        download_k3d
        download_kind
    ;;

    "helm")
        download_helm
    ;;

    "kustomize")
        download_kustomize
    ;;

    "notary")
        download_notary
    ;;

    "k3d")
        download_k3d
    ;;

    "kind")
        download_kind
    ;;

    *)
        usage
    ;;
esac