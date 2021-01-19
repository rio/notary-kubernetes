#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

printf "# Exercising registry\n\n"

printf "## Pulling alpine:3.13 image\n\n"

docker pull alpine:3.13

printf "\n## Tagging alpine:3.13 as localhost/library/alpine:unsigned\n\n"

(set -x; docker tag alpine:3.13 localhost/library/alpine:unsigned )

printf "\n## Pushing localhost/library/alpine:unsigned image\n\n"

docker push localhost/library/alpine:unsigned

printf "\n# Registry functional\n\n"

printf "# Exercising Notary\n\n"

export DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE='root-passphrase'
export DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE='repo-passphrase'

if [ -f $(hostname).pub ]; then
    printf "## Reusing $(hostname).pub public key.\n"
    printf "## If this is undesireable then delete this file.\n"
else
    printf "## Generating local trust keys for $(hostname) with passphrase '${DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE}'\n\n"

    docker trust key generate $(hostname)
fi

    printf "\n## Adding $(hostname).pub as signer for localhost/library/alpine root passphrase '${DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE}' and repository passphrase '${DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE}'\n\n"

docker trust signer add --key $(hostname).pub $(hostname) localhost/library/alpine

printf "\n## Tagging alpine:3.13 as localhost/library/alpine:signed\n\n"

(set -x; docker tag alpine:3.13 localhost/library/alpine:signed)

printf "\n## Signing and pushing localhost/library/alpine:signed\n\n"

docker trust sign localhost/library/alpine:signed

printf "\n# Notary functional\n\n"

printf "# Exercising Docker Content Trust\n\n"

printf "## Deleting signed and unsigned tags\n\n" 

docker image rm localhost/library/alpine:unsigned localhost/library/alpine:signed

export DOCKER_CONTENT_TRUST=1

printf "\n## Verifying Docker fails to validate localhost/library/alpine:unsigned\n\n"

if docker pull localhost/library/alpine:unsigned ; then
    printf "### Docker should have failed pulling and validating this image."
    exit 1
fi

printf "\n## Verifying Docker succeeds to validate localhost/library/alpine:signed\n\n"

docker pull localhost/library/alpine:signed

printf "\n## Inspecting signatures\n"

docker trust inspect --pretty localhost/library/alpine:signed

printf "\n# Docker Content Trust functional\n\n"

printf "# Verification complete\n"