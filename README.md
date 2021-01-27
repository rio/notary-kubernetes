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

0.  Clone this repository and cd into it.

    ```
    ~ # git clone https://github.com/Rio/notary-kubernetes.git
    ...snip...

    ~ # cd notary-kubernetes
    ```

1.  Run the `scripts/download-tools.sh` script to pull in all tools required.
    The script will create a `bin` folder at the root of the repo and then
    downloads and verifies them before making them executable. If you want the
    scripts to use these tools automatically you'll have to add the `bin` folder
    to your path as well. This change to your PATH will only be valid in this
    terminal.

    ```
    ~/rp1-docker-notary # ./scripts/download-tools.sh
    ## Downloading binaries
    kubectl         ✓
    kustomize       ✓
    helm            ✓
    k3d             ✓
    notary          ✓

    ## Validating binaries
    kubectl         ✓
    kustomize       ✓
    helm            ✓
    k3d             ✓
    notary          ✓

    Do not forget to add the /root/rp1-docker-notary/bin directory to your path so other
    scripts can use these binaries. Run the following command in the root of
    this repository to enable the bin folder for this terminal.

        export PATH=$PATH:$PWD/bin

    ~/rp1-docker-notary # export PATH=$PATH:$PWD/bin
    ```
2.  Run the `scripts/create-k3d-cluster.sh` to start a kubernetes cluster in docker.
    It will forward ports 80 and 443 from the container to localhost. This will
    enable us to just use `localhost` to reach our Notary and registry installations
    from within this container.

    ```
    ~/rp1-docker-notary # ./scripts/create-k3d-cluster.sh
    + k3d cluster create --k3s-server-arg=--disable=traefik --port 80:80@loadbalancer --port 443:443@loadbalancer
    INFO[0000] Created network 'k3d-k3s-default'
    INFO[0000] Created volume 'k3d-k3s-default-images'
    INFO[0001] Creating node 'k3d-k3s-default-server-0'
    INFO[0005] Creating LoadBalancer 'k3d-k3s-default-serverlb'
    INFO[0006] (Optional) Trying to get IP of the docker host and inject it into the cluster as 'host.k3d.internal' for easy access
    INFO[0009] Successfully added host record to /etc/hosts in 2/2 nodes and to the CoreDNS ConfigMap
    INFO[0009] Cluster 'k3s-default' created successfully!
    INFO[0009] You can now use it like this:
    kubectl cluster-info
    ```

3.  Run `scripts/preflight-check.sh` to determine if your system is ready for
    deployment. If everything checks out it should look like this and you can
    continue to step 4 to deploy everything.

    ```
    ~/rp1-docker-notary # ./scripts/preflight-check.sh
    Looking for required binaries

    kubectl installed       ✓       (version: Client Version: v1.20.0                       path: /root/rp1-docker-notary/bin/kubectl)
    kustomize installed     ✓       (version: {kustomize/v3.8.9  2020-12-29T15:49:08Z  }    path: /root/rp1-docker-notary/bin/kustomize)
    helm installed          ✓       (version: v3.4.2+g23dd3af                               path: /root/rp1-docker-notary/bin/helm)

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

    ```
    ~/rp1-docker-notary # ./scripts/deploy.sh
    # Deploying dependencies

    ## Timeout when deploying dependencies: 5m

    ### Deploying cert-manager

    customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io created
    customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io created
    ...snip...
    deployment.apps/cert-manager-webhook created
    mutatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook created
    validatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook created

    ### Deploying traefik

    NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
    traefik traefik-system  1               2021-01-19 14:13:04.63592068 +0000 UTC  deployed        traefik-9.12.3  2.3.6
    ### Deploying mariadb

    NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
    mariadb mariadb         1               2021-01-19 14:13:12.570800813 +0000 UTC deployed        mariadb-9.2.2   10.5.8
    ### Waiting for traefik to report ready

    deployment.apps/traefik condition met

    ### Waiting for mariadb to report ready

    Waiting for 1 pods to be ready...
    statefulset rolling update complete 1 pods at revision mariadb-d766ccf4f...

    ## Deploying dependencies complete

    # Deploying Notary and the registry

    ## Timeout when deploying Notary and the registry: 5m

    ### Deploying notary and registry

    namespace/notary created
    configmap/notaryserver-9g226fhg7t created
    configmap/notarysigner-hc4767dmg9 created
    configmap/scripts-k7fkbhf5gh created
    secret/notary-ca created
    secret/notaryserver-82f9bt4cct created
    secret/notarysigner-td6hb4gbht created
    service/notaryserver created
    service/notarysigner created
    service/registry created
    deployment.apps/notaryserver created
    deployment.apps/notarysigner created
    deployment.apps/registry created
    job.batch/migrate created
    certificate.cert-manager.io/notaryserver-tls created
    certificate.cert-manager.io/notarysigner-tls created
    certificate.cert-manager.io/registry-tls created
    issuer.cert-manager.io/notary-ca created
    ingress.networking.k8s.io/notary created

    ### Waiting for migration job to complete

    job.batch/migrate condition met

    ### Waiting for deployments to report ready

    deployment.apps/registry condition met
    deployment.apps/notaryserver condition met
    deployment.apps/notarysigner condition met

    ## Deploying notary and registry complete

    # Deployment complete
    ```

5.  Validate that we can reach the registry and that Notary is functioning as expected.
    We will run `scripts/verify.sh` which is loosly based on the [Docker Trust Content guide](https://docs.docker.com/engine/security/trust/)
    that Docker provides.

    It will:
    - Pull in an image.
    - Tag the image so we can push it to our own registry.
    - Generate a role with a private/public key pair on our machine for signing.
    - Add that key as a signer for our image repository. This will generate a new root key and repository key.
    - Sign our image with our private key. This will also trigger a push to the registry.
    - Verify if Docker fails a pull on an unsigned image and succeeds with a signed image.

    ```
    ~/rp1-docker-notary # ./scripts/verify.sh
    # Exercising registry

    ## Pulling alpine:3.13 image

    3.13: Pulling from library/alpine
    596ba82af5aa: Pull complete
    Digest: sha256:d9a7354e3845ea8466bb00b22224d9116b183e594527fb5b6c3d30bc01a20378
    Status: Downloaded newer image for alpine:3.13
    docker.io/library/alpine:3.13

    ## Tagging alpine:3.13 as localhost/library/alpine:unsigned

    + docker tag alpine:3.13 localhost/library/alpine:unsigned

    ## Pushing localhost/library/alpine:unsigned image

    The push refers to repository [localhost/library/alpine]
    c04d1437198b: Pushed
    unsigned: digest: sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515 size: 528

    # Registry functional

    # Exercising Notary

    ## Generating local trust keys for 60ca58ba8378 with passphrase 'repo-passphrase'

    Generating key for 60ca58ba8378...
    Successfully generated and loaded private key. Corresponding public key available: /root/rp1-docker-notary/60ca58ba8378.pub

    ## Adding 60ca58ba8378.pub as signer for localhost/library/alpine root passphrase 'root-passphrase' and repository passphrase 'repo-passphrase'

    Adding signer "60ca58ba8378" to localhost/library/alpine...
    Initializing signed repository for localhost/library/alpine...
    Successfully initialized "localhost/library/alpine"
    Successfully added signer: 60ca58ba8378 to localhost/library/alpine

    ## Tagging alpine:3.13 as localhost/library/alpine:signed

    + docker tag alpine:3.13 localhost/library/alpine:signed

    ## Signing and pushing localhost/library/alpine:signed

    Signing and pushing trust data for local image localhost/library/alpine:signed, may overwrite remote trust data
    The push refers to repository [localhost/library/alpine]
    c04d1437198b: Layer already exists
    signed: digest: sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515 size: 528
    Signing and pushing trust metadata
    Successfully signed localhost/library/alpine:signed

    # Notary functional

    # Exercising Docker Content Trust

    ## Deleting signed and unsigned tags

    Untagged: localhost/library/alpine:unsigned
    Untagged: localhost/library/alpine:signed
    Untagged: localhost/library/alpine@sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515

    ## Verifying Docker fails to validate localhost/library/alpine:unsigned

    No valid trust data for unsigned

    ## Verifying Docker succeeds to validate localhost/library/alpine:signed

    Pull (1 of 1): localhost/library/alpine:signed@sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515
    localhost/library/alpine@sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515: Pulling from library/alpine
    Digest: sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515
    Status: Downloaded newer image for localhost/library/alpine@sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515
    Tagging localhost/library/alpine@sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515 as localhost/library/alpine:signed
    localhost/library/alpine:signed

    ## Inspecting signatures

    Signatures for localhost/library/alpine:signed

    SIGNED TAG   DIGEST                                                             SIGNERS
    signed       d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515   60ca58ba8378

    List of signers and their keys for localhost/library/alpine:signed

    SIGNER         KEYS
    60ca58ba8378   580a8f7c43b4

    Administrative keys for localhost/library/alpine:signed

    Repository Key:       2916820f4eb14565ca259d53003565b655dec5db63dc75389c1e2f8b5a51f47b
    Root Key:     f4fbf87b64240e388c0a258c1b53e85ce76855984f9e13bbf46f6dedad3d9d2f

    # Docker Content Trust functional

    # Verification complete
    ```
