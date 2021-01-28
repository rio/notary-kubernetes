# Notary Kubernetes

## Requirements

- Docker installed and running.

## Sandbox

To ensure that this guide has the best chance of succeeding and that any script
doesn't accidentally modify your system we are going to setup what is called docker-in-docker.
It's basically exactly what it sounds like where we run a docker daemon inside of
docker. This means that the moment you stop and delete that container all state
is gone and your system is as clean as when we started. Let's create that container.

```bash
$ docker run -d --name dind --privileged docker:dind
f0953d1a62275cd3f19a38a51bf88cb69162c6935b1781f5786813cb4692ba30

$ docker container ls
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
f0953d1a6227        docker:dind         "dockerd-entrypoint.…"   30 seconds ago      Up 30 seconds       2375-2376/tcp       dind
```

Once that container is up and running exec into it, cd into the root home directory
and install bash, curl and git.

```bash
$ docker exec -ti dind sh
/ $ cd
~ $ apk add bash curl git
fetch http://dl-cdn.alpinelinux.org/alpine/v3.12/main/x86_64/APKINDEX.tar.gz
fetch http://dl-cdn.alpinelinux.org/alpine/v3.12/community/x86_64/APKINDEX.tar.gz
(1/8) Installing readline (8.0.4-r0)
(2/8) Installing bash (5.0.17-r0)
Executing bash-5.0.17-r0.post-install
(3/8) Installing nghttp2-libs (1.41.0-r0)
(4/8) Installing libcurl (7.69.1-r3)
(5/8) Installing curl (7.69.1-r3)
(6/8) Installing expat (2.2.9-r1)
(7/8) Installing pcre2 (10.35-r0)
(8/8) Installing git (2.26.2-r0)
Executing busybox-1.31.1-r19.trigger
OK: 44 MiB in 56 packages
```

You are now ready to clone this repository in this container and start the guide.
To cleanup everything just stop the `dind` container and remove it.

```bash
$ docker container stop dind
dind

$ docker container rm dind
dind
```

## Quick Start

> **NOTE**: All of the following steps assume that they are run inside of the
> sandbox container setup earlier.

0.  Clone this repository and cd into it.

    ```
    ~ # git clone https://github.com/rio/notary-kubernetes.git
    ...snip...

    ~ # cd notary-kubernetes
    ```

1.  Run the `scripts/download-tools.sh` script to pull in all tools required.
    The script will create a `bin` folder at the root of the repo and then
    downloads and verifies them before making them executable. If you want the
    scripts to use these tools automatically you'll have to add the `bin` folder
    to your path as well. This change to your PATH will only be valid in this terminal.
    Or you could move them to a location already your path like `/usr/local/bin`.

    ```
    ~/notary-kubernetes # ./scripts/download-tools.sh
    ## Downloading binaries
    kubectl         DONE
    kustomize       DONE
    helm            DONE
    k3d             DONE
    notary          DONE

    ## Validating binaries
    kubectl: OK
    kustomize: OK
    helm: OK
    k3d: OK
    notary: OK

    Do not forget to add the /root/notary-kubernetes/bin directory to your path so other
    scripts can use these binaries. Run the following command in the root of
    this repository to enable the bin folder for this terminal.

        export PATH=$PATH:$PWD/bin

    ~/notary-kubernetes # export PATH=$PATH:$PWD/bin
    ```
2.  Run the `scripts/create-k3d-cluster.sh` to start a kubernetes cluster in docker.
    It will forward ports 80 and 443 from the container to localhost. This will
    enable us to just use `localhost` to reach our Notary and registry installations
    from within this container.

    ```
    ~/notary-kubernetes # ./scripts/create-k3d-cluster.sh
    + k3d cluster create --k3s-server-arg=--disable=traefik --port 80:80@loadbalancer --port 443:443@loadbalancer
    INFO[0000] Created network 'k3d-k3s-default'
    INFO[0000] Created volume 'k3d-k3s-default-images'
    INFO[0001] Creating node 'k3d-k3s-default-server-0'
    INFO[0002] Pulling image 'docker.io/rancher/k3s:v1.19.4-k3s1'
    INFO[0033] Creating LoadBalancer 'k3d-k3s-default-serverlb'
    INFO[0034] Pulling image 'docker.io/rancher/k3d-proxy:v3.4.0'
    INFO[0044] (Optional) Trying to get IP of the docker host and inject it into the cluster as 'host.k3d.internal' for easy access
    INFO[0047] Successfully added host record to /etc/hosts in 2/2 nodes and to the CoreDNS ConfigMap
    INFO[0047] Cluster 'k3s-default' created successfully!
    INFO[0047] You can now use it like this:
    kubectl cluster-info
    ```

3.  Run `scripts/preflight-check.sh` to determine if your system is ready for
    deployment. If everything checks out it should look like this and you can
    continue to step 4 to deploy everything.

    ```
    ~/notary-kubernetes # ./scripts/preflight-check.sh
    Looking for required binaries

    kubectl installed       ✓       (version: Client Version: v1.20.0                       path: /root/notary-kubernetes/bin/kubectl)
    kustomize installed     ✓       (version: {kustomize/v3.8.9  2020-12-29T15:49:08Z  }    path: /root/notary-kubernetes/bin/kustomize)
    helm installed          ✓       (version: v3.4.2+g23dd3af                               path: /root/notary-kubernetes/bin/helm)

    All required binaries found.

    Looking for required services

    docker:                 ✓       (version: 20.10.2)
    kubernetes:             ✓       (version: ServerVersion:v1.19.4+k3s1    context: k3d-k3s-default        user: admin@k3d-k3s-default)

    All checks passed.
    ```

4.  Deploy all services using the `scripts/deploy.sh` script. The commands
    executed by the script are idempotent. If anything goes wrong during installation
    like a timeout is reached because of a slow or disconnected internet connection
    you can just rerun the script.

    > **WARNING**: It is not recommended to run this script against any production
    > cluster. It will install a number of cluster wide resources like CRDs, Namespaces,
    > ClusterRoles and ClusterRoleBindings. Verify that you're not running this against
    > an unexpected cluster with unexpected privileges by running the `preflight-check.sh`
    > script again.

    ```
    ~/notary-kubernetes # ./scripts/deploy.sh
    # Deploying dependencies

    ## Timeout when deploying dependencies: 5m

    ### Deploying cert-manager

    customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io created
    customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io created
    ... snip ...
    deployment.apps/cert-manager created
    deployment.apps/cert-manager-webhook created
    mutatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook created
    validatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook created

    ### Waiting for cert-manager to report ready
    deployment.apps/cert-manager-cainjector condition met
    deployment.apps/cert-manager-webhook condition met
    deployment.apps/cert-manager condition met

    ### Deploying traefik

    NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
    traefik traefik-system  1               2021-01-28 10:34:44.284035325 +0000 UTC deployed        traefik-9.13.0  2.4.0

    ### Waiting for traefik to report ready
    deployment.apps/traefik condition met

    ### Deploying postgres

    NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
    notary  notary          1               2021-01-28 10:34:51.15701089 +0000 UTC  deployed        postgresql-10.2.4       11.10.0

    ## Deploying dependencies complete

    ## Deploying certificates

    secret/notary-ca created
    secret/notary-ca-cert created
    certificate.cert-manager.io/notaryserver-tls created
    certificate.cert-manager.io/notarysigner-tls created
    certificate.cert-manager.io/postgres-tls created
    certificate.cert-manager.io/registry-tls created
    issuer.cert-manager.io/notary-ca created

    ### Waiting for certificates to report ready
    certificate.cert-manager.io/notarysigner-tls condition met
    certificate.cert-manager.io/postgres-tls condition met
    certificate.cert-manager.io/registry-tls condition met
    certificate.cert-manager.io/notaryserver-tls condition met

    # Deploying Notary and the registry

    ## Timeout when deploying Notary and the registry: 5m

    ### Deploying notary and registry

    namespace/notary configured
    configmap/notaryserver-26cdfcb9c2 created
    configmap/notarysigner-dt77g798g7 created
    configmap/registry-config-2559m92g89 created
    configmap/scripts-d26bg7f288 created
    secret/notarysigner-4g6k44c8c8 created
    service/notary created
    service/registry created
    deployment.apps/notary created
    deployment.apps/registry created
    job.batch/migrate created
    ingressroute.traefik.containo.us/notary created
    ingressroute.traefik.containo.us/registry created
    serverstransport.traefik.containo.us/notary-tls created
    serverstransport.traefik.containo.us/registry-tls created

    ### Waiting for deployments to report ready

    deployment.apps/registry condition met
    deployment.apps/notary condition met

    ## Deploying notary and registry complete

    # Deployment complete
    ```

5.  Validate that we can reach the registry and that Notary is functioning as expected.
    We will run `scripts/verify.sh` which is loosly based on the [Docker Trust Content guide](https://docs.docker.com/engine/security/trust/)
    that Docker provides.

    > **WARNING**: This script will generate keys and change data in `~/.docker/trust`.
    > If you are not running this inside the sandbox container and have data in your
    > `~/.docker/trust` folder that you do not want to lose you should make a backup!

    It will:
    - Pull in an image.
    - Tag the image so we can push it to our own registry.
    - Generate a role with a private/public key pair on our machine for signing.
    - Add that key as a signer for our image repository. This will generate a new root key and repository key.
    - Sign our image with our private key. This will also trigger a push to the registry.
    - Verify if Docker fails a pull on an unsigned image and succeeds with a signed image.

    ```
    ~/notary-kubernetes # ./scripts/verify.sh
    # Exercising registry

    ## Pulling alpine:3.12 image

    3.12: Pulling from library/alpine
    801bfaa63ef2: Pull complete
    Digest: sha256:3c7497bf0c7af93428242d6176e8f7905f2201d8fc5861f45be7a346b5f23436
    Status: Downloaded newer image for alpine:3.12
    docker.io/library/alpine:3.12

    ## Tagging alpine:3.12 as localhost/library/alpine:unsigned

    + docker tag alpine:3.12 localhost/library/alpine:unsigned

    ## Pushing localhost/library/alpine:unsigned image

    The push refers to repository [localhost/library/alpine]
    777b2c648970: Pushed
    unsigned: digest: sha256:074d3636ebda6dd446d0d00304c4454f468237fdacf08fb0eeac90bdbfa1bac7 size: 528

    # Registry functional

    # Exercising Notary

    ## Generating local trust keys for 831d0e07ce16 with passphrase 'repo'

    Generating key for 831d0e07ce16...
    Successfully generated and loaded private key. Corresponding public key available: /root/notary-kubernetes/831d0e07ce16.pub

    ## Adding 831d0e07ce16.pub as signer for localhost/library/alpine root passphrase 'root' and repository passphrase 'repo'

    Adding signer "831d0e07ce16" to localhost/library/alpine...
    Initializing signed repository for localhost/library/alpine...
    Successfully initialized "localhost/library/alpine"
    Successfully added signer: 831d0e07ce16 to localhost/library/alpine

    ## Tagging alpine:3.12 as localhost/library/alpine:signed

    + docker tag alpine:3.12 localhost/library/alpine:signed

    ## Signing and pushing localhost/library/alpine:signed

    Signing and pushing trust data for local image localhost/library/alpine:signed, may overwrite remote trust data
    The push refers to repository [localhost/library/alpine]
    777b2c648970: Layer already exists
    signed: digest: sha256:074d3636ebda6dd446d0d00304c4454f468237fdacf08fb0eeac90bdbfa1bac7 size: 528
    Signing and pushing trust metadata
    Successfully signed localhost/library/alpine:signed

    # Notary functional

    # Exercising Docker Content Trust

    ## Deleting signed and unsigned tags

    Untagged: localhost/library/alpine:unsigned
    Untagged: localhost/library/alpine:signed
    Untagged: localhost/library/alpine@sha256:074d3636ebda6dd446d0d00304c4454f468237fdacf08fb0eeac90bdbfa1bac7

    ## Verifying Docker fails to validate localhost/library/alpine:unsigned

    No valid trust data for unsigned

    ## Verifying Docker succeeds to validate localhost/library/alpine:signed

    Pull (1 of 1): localhost/library/alpine:signed@sha256:074d3636ebda6dd446d0d00304c4454f468237fdacf08fb0eeac90bdbfa1bac7
    localhost/library/alpine@sha256:074d3636ebda6dd446d0d00304c4454f468237fdacf08fb0eeac90bdbfa1bac7: Pulling from library/alpine
    Digest: sha256:074d3636ebda6dd446d0d00304c4454f468237fdacf08fb0eeac90bdbfa1bac7
    Status: Downloaded newer image for localhost/library/alpine@sha256:074d3636ebda6dd446d0d00304c4454f468237fdacf08fb0eeac90bdbfa1bac7
    Tagging localhost/library/alpine@sha256:074d3636ebda6dd446d0d00304c4454f468237fdacf08fb0eeac90bdbfa1bac7 as localhost/library/alpine:signed
    localhost/library/alpine:signed

    ## Inspecting signatures

    Signatures for localhost/library/alpine:signed

    SIGNED TAG   DIGEST                                                             SIGNERS
    signed       074d3636ebda6dd446d0d00304c4454f468237fdacf08fb0eeac90bdbfa1bac7   831d0e07ce16

    List of signers and their keys for localhost/library/alpine:signed

    SIGNER         KEYS
    831d0e07ce16   03c8406788b1

    Administrative keys for localhost/library/alpine:signed

        Repository Key:       012a4c53155b94c30654b50eac03ccf7004827ee56ae55fc7b6356ac3ce72676
        Root Key:     764e4767d02e5880b059c071bdb7e74e9e62684dd296292e23b52743e4d8baf7

    # Docker Content Trust functional

    # Verification complete
    ```

6.  To interact with Notary directly you can use the config file `config/notary-client.json`.
    Let's list our keys that we have locally.

    ```
    ~/notary-kubernetes # notary -c config/notary-client.json key list

    ROLE            GUN                         KEY ID                                                              LOCATION
    ----            ---                         ------                                                              --------
    root                                        1720db1dd5fc5a58168065f8ca780c3b593046c9a8aa4af8e56d10304f9521b7    /root/.docker/trust/private
    831d0e07ce16                                03c8406788b103962b32e0586492b51f0935bbd2b639ec777024779313f18969    /root/.docker/trust/private
    targets         localhost/library/alpine    012a4c53155b94c30654b50eac03ccf7004827ee56ae55fc7b6356ac3ce72676    /root/.docker/trust/private
    ```

    As you can see our root and repository keys reside in `/root/.docker/trust/private`.
    Now let's look at the delegations for `localhost/library/alpine` that are known
    to our Notary instance.

    ```
    ~/notary-kubernetes # notary -c config/notary-client.json delegation list localhost/library/alpine

    ROLE                    PATHS             KEY IDS                                                             THRESHOLD
    ----                    -----             -------                                                             ---------
    targets/831d0e07ce16    "" <all paths>    03c8406788b103962b32e0586492b51f0935bbd2b639ec777024779313f18969    1
    targets/releases        "" <all paths>    03c8406788b103962b32e0586492b51f0935bbd2b639ec777024779313f18969    1
    ```

    Finally let's list the target signature that we just pushed to Notary. This
    should be similar to the output of the `docker trust inspect --pretty localhost/library/alpine`
    command that our `verify.sh` script ran at the end.

    ```
    ~/notary-kubernetes # notary -c config/notary-client.json list localhost/library/alpine
    NAME      DIGEST                                                              SIZE (BYTES)    ROLE
    ----      ------                                                              ------------    ----
    signed    074d3636ebda6dd446d0d00304c4454f468237fdacf08fb0eeac90bdbfa1bac7    528             targets/831d0e07ce16
    ```
