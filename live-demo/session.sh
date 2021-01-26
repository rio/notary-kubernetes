# Recorded with the doitlive recorder
#doitlive shell: /bin/bash
#doitlive prompt: sorin
#doitlive commentecho: true

# This demo runs locally on k3s witin a docker container.
kubectl version --short
kubectl config current-context
docker version -f '{{.Server.Version}}'

#
# All our dependencies and services have already been deployed.
# - cert-manager provisions all of our certificates.
# - Traefik handles HTTPS Ingress Routing.
# - PostgreSQL is our database backing Notary.
# - Notary, the registry and have been deployed.
kubectl get namespaces cert-manager traefik-system notary
kubectl get pod,certificates -n notary

#
# Make sure no images are local and pull in an image.
docker system prune --all --force
docker pull alpine:3.12

#
# Tag and push to verify our registry works. Then clean the system and verify
# that pulling an image works.
docker tag alpine:3.12 localhost/library/alpine:unsigned
docker push localhost/library/alpine:unsigned
docker system prune --all --force
docker pull localhost/library/alpine:unsigned

#
# Generate a key for this machine to use for signing and add it as a signer for
# our repository We set some passphrases to help with this demo.
export DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE='demo-root'
export DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE='demo-repo'
docker trust key generate demo-signing-role
docker trust signer add --key demo-signing-role.pub demo-signing-role localhost/library/alpine

#
# Verify that keys root and repository keys are generated and notary is
# informed of the signer delegations.
notary -c config/notary-client.json key list
notary -c config/notary-client.json delegation list localhost/library/alpine

#
# Tag a new image, sign and push it.
docker tag localhost/library/alpine:unsigned localhost/library/alpine:signed
docker trust sign localhost/library/alpine:signed

#
# Clean our local system again.
docker system prune --all --force

#
# Turn on Docker Content Trust so we can verify if pulling and unsigned image
# fails and pulling a signed image succeeds.
export DOCKER_CONTENT_TRUST=1
docker pull localhost/library/alpine:unsigned
docker pull localhost/library/alpine:signed

#
# let's inspect the signature
docker trust inspect --pretty localhost/library/alpine:signed