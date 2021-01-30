# Recorded with the doitlive recorder
#doitlive shell: /bin/bash
#doitlive prompt: sorin
#doitlive commentecho: true
#doitlive env: DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE='demo-root'
#doitlive env: DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE='demo-repo'

# Here we're showing the basic key generation and signing flow of docker using
# our deployed Notary and registry instances.
echo "Container image signing with Notary." | figlet | lolcat

#
# Make sure no images are local and pull in an image.
docker system prune --all --force
docker pull alpine:3.12

#
# Tag and push to verify our registry works
docker tag alpine:3.12 localhost/library/alpine:unsigned
docker push localhost/library/alpine:unsigned

#
# Generate a key for this machine to use for signing. 
docker trust key generate demo-signing-role

#
# Add that key and role as a signer for our repository.
docker trust signer add --key demo-signing-role.pub demo-signing-role localhost/library/alpine

#
# Tag a new image, sign and push it.
docker tag alpine:3.12 localhost/library/alpine:signed
docker trust sign localhost/library/alpine:signed

#
# Clean our local system again.
docker system prune --all --force

#
# Turn on Docker Content Trust.
export DOCKER_CONTENT_TRUST=1

# 
# Pulling the unsigned image should fail as there are no signatures available.
docker pull localhost/library/alpine:unsigned

# Pulling the signed image should succeed.
docker pull localhost/library/alpine:signed