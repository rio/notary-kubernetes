#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

HOSTNAME=$(hostname)

REGISTRY_HOST=localhost
REPOSITORY_NAME=library/alpine

IMAGE_NAME=${REGISTRY_HOST}/${REPOSITORY_NAME}

UNSIGNED=${REGISTRY_HOST}/${REPOSITORY_NAME}:unsigned
SIGNED=${REGISTRY_HOST}/${REPOSITORY_NAME}:signed

export DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE='root'
export DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE='repo'

printf "# Exercising registry\n\n"

printf "## Pulling alpine:3.12 image\n\n"

docker pull alpine:3.12

printf "\n## Tagging alpine:3.12 as ${UNSIGNED}\n\n"

(set -x; docker tag alpine:3.12 ${UNSIGNED} )

printf "\n## Pushing ${UNSIGNED} image\n\n"

docker push ${UNSIGNED}

printf "\n# Registry functional\n\n"

printf "# Exercising Notary\n\n"

if [ -f ${HOSTNAME,,}.pub ]; then
    printf "## Reusing ${HOSTNAME,,}.pub public key.\n"
    printf "## If this is undesireable then delete this file.\n"
else
    printf "## Generating local trust keys for ${HOSTNAME,,} with passphrase '${DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE}'\n\n"

    docker trust key generate ${HOSTNAME,,}
fi

    printf "\n## Adding ${HOSTNAME,,}.pub as signer for ${IMAGE_NAME} root passphrase '${DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE}' and repository passphrase '${DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE}'\n\n"

docker trust signer add --key ${HOSTNAME,,}.pub ${HOSTNAME,,}  ${IMAGE_NAME}

printf "\n## Tagging alpine:3.12 as ${SIGNED}\n\n"

(set -x; docker tag alpine:3.12 ${SIGNED})

printf "\n## Signing and pushing ${SIGNED}\n\n"

docker trust sign ${SIGNED}

printf "\n# Notary functional\n\n"

printf "# Exercising Docker Content Trust\n\n"

printf "## Deleting signed and unsigned tags\n\n" 

docker image rm ${UNSIGNED} ${SIGNED}

export DOCKER_CONTENT_TRUST=1

printf "\n## Verifying Docker fails to validate ${UNSIGNED}\n\n"

if docker pull ${UNSIGNED} ; then
    printf "### Docker should have failed pulling and validating this image."
    exit 1
fi

printf "\n## Verifying Docker succeeds to validate ${SIGNED}\n\n"

docker pull ${SIGNED}

printf "\n## Inspecting signatures\n"

docker trust inspect --pretty ${SIGNED}

printf "\n# Docker Content Trust functional\n\n"

printf "# Verification complete\n"
