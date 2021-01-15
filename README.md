# rp1-docker-notary

## Requirements

- Docker installed and running.
- Either curl or wget when using scripts/download-tools.sh to download other
  required binaries.

## Quick Start

1.  Run the `scripts/download-tools.sh` script to pull in any tools required.
    The script will create a `bin` folder at the root of the repo and then
    downloads and verifies them before making them executable. If you want the
    scripts to use these tools automatically you'll have to add the `bin` folder
    to your path as well. This change to your PATH will only be valid in this
    terminal.

    ```bash
    $ ./scripts/download-tools.sh all
    Downloading and validating kubectl
    kubectl: OK
    Downloading and validating Helm
    helm: OK
    Downloading and validating Kustomize
    kustomize: OK
    Downloading and validating Notary
    notary: OK
    Downloading and validating k3d
    k3d: OK

    $ kubectl version
    kubectl: command not found...

    $ export PATH=$PATH:$PWD/bin

    $ kubectl version
    Client Version: version.Info{Major:"1", Minor:"20", GitVersion:"v1.20.0", GitCommit:"af46c47ce925f4c4ad5cc8d1fca46c7b77d13b38", GitTreeState:"clean", BuildDate:"2020-12-08T17:59:43Z", GoVersion:"go1.15.5", Compiler:"gc", Platform:"linux/amd64"}
    Server Version: version.Info{Major:"1", Minor:"19", GitVersion:"v1.19.4+k3s1", GitCommit:"2532c10faad43e2b6e728fdcc01662dc13d37764", GitTreeState:"clean", BuildDate:"2020-11-18T22:11:18Z", GoVersion:"go1.15.2", Compiler:"gc", Platform:"linux/amd64"}
    ```

2.  Verify that docker is running and reachable.

    ```bash
    $ docker info
    Client:
    Debug Mode: false

    Server:
    Containers: 0
    Running: 0
    Paused: 0
    Stopped: 0
    Images: 5
    Server Version: 19.03.11
    Storage Driver: overlay2
    Backing Filesystem: extfs
    Supports d_type: true
    Native Overlay Diff: true
    Logging Driver: journald
    Cgroup Driver: systemd
    Plugins:
    Volume: local
    Network: bridge host ipvlan macvlan null overlay
    Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
    Swarm: inactive
    Runtimes: runc
    Default Runtime: runc
    Init Binary: /usr/libexec/docker/docker-init
    containerd version:
    runc version:
    init version:
    Security Options:
    seccomp
    Profile: default
    selinux
    Kernel Version: 5.9.16-100.fc32.x86_64
    Operating System: Fedora 32 (Workstation Edition)
    OSType: linux
    Architecture: x86_64
    CPUs: 8
    Total Memory: 15.34GiB
    Name: starscream
    ID: JIH4:4C4B:SKSS:IMSX:QD3U:QTBH:RPK3:C2BI:GTD6:JGDK:YDRU:JFRN
    Docker Root Dir: /var/lib/docker
    Debug Mode: false
    Registry: https://index.docker.io/v1/
    Labels:
    Experimental: false
    Insecure Registries:
    127.0.0.0/8
    Live Restore Enabled: true
    ```

3.  Run the `scripts/create-k3d-cluster.sh` to start a kubernetes cluster in docker.
    It will forward ports 80 and 443 from the container to localhost. This will
    enable us to just use `localhost` to reach our Notary and registry installations.

    ```bash
    $ ./scripts/create-k3d-cluster.sh
    + k3d cluster create --k3s-server-arg=--disable=traefik --port 80:80@loadbalancer --port 443:443@loadbalancer
    INFO[0000] Created network 'k3d-k3s-default'
    INFO[0000] Created volume 'k3d-k3s-default-images'
    INFO[0001] Creating node 'k3d-k3s-default-server-0'
    INFO[0006] Creating LoadBalancer 'k3d-k3s-default-serverlb'
    INFO[0006] (Optional) Trying to get IP of the docker host and inject it into the cluster as 'host.k3d.internal' for easy access
    INFO[0009] Successfully added host record to /etc/hosts in 2/2 nodes and to the CoreDNS ConfigMap
    INFO[0009] Cluster 'k3s-default' created successfully!
    INFO[0010] You can now use it like this:
    kubectl cluster-info
    ```

4.  Verify that the cluster is reachable using the kubectl command.

    ```bash
    $ kubectl get nodes
    NAME                       STATUS   ROLES    AGE   VERSION
    k3d-k3s-default-server-0   Ready    master   37s   v1.19.4+k3s1
    ```

5.  Deploy all services using the `scripts/deploy.sh` script. The commands
    executed by the script are idempotent. If anything goes wrong during installation
    like a timeout is reached because of a slow or disconnected internet connection
    you can just rerun the script.

    ```bash
    Checking if kubectl is installed.
    Checking if kustomize is installed.
    Checking if helm is installed.
    All required binaries found.

    ### Installing cert-manager
    customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io created
    customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io created
    customresourcedefinition.apiextensions.k8s.io/challenges.acme.cert-manager.io created
    customresourcedefinition.apiextensions.k8s.io/clusterissuers.cert-manager.io created

    # ... snip lots of output ...

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
    deployment.apps/notarysigner condition met
    deployment.apps/registry condition met
    deployment.apps/notaryserver condition met
    ```

6.  Validate that we can reach the registry by retagging an image and pushing it.

    ```bash
    $ docker pull alpine:3.13
    3.13: Pulling from library/alpine
    596ba82af5aa: Pull complete
    Digest: sha256:d9a7354e3845ea8466bb00b22224d9116b183e594527fb5b6c3d30bc01a20378
    Status: Downloaded newer image for alpine:3.13
    docker.io/library/alpine:3.13

    $ docker tag alpine:3.13 localhost/library/alpine:3.13
    $ docker push localhost/library/alpine:3.13
    The push refers to repository [localhost/library/alpine]
    c04d1437198b: Pushed
    3.13: digest: sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515 size: 528
    ```

7.  Generate a key that we can use for signing images using the `docker trust` commands.

    ```bash
    $ docker trust key generate my-signing-role
    Generating key for my-signing-role...
    Enter passphrase for new my-signing-role key with ID e4a96c7:
    Repeat passphrase for new my-signing-role key with ID e4a96c7:
    Successfully generated and loaded private key. Corresponding public key available: /home/user/rp1-docker-notary/my-signing-role.pub
    ```

8.  Add the previously generated key as a singer for this image repository. This
    will generate a root key for this repository and a repository key.

    ```bash
    $ docker trust signer add --key my-signing-role.pub my-signing-role localhost/library/alpine
    Adding signer "my-signing-role" to localhost/library/alpine...
    Initializing signed repository for localhost/library/alpine...
    You are about to create a new root signing key passphrase. This passphrase
    will be used to protect the most sensitive key in your signing system. Please
    choose a long, complex passphrase and be careful to keep the password and the
    key file itself secure and backed up. It is highly recommended that you use a
    password manager to generate the passphrase and keep it safe. There will be no
    way to recover this key. You can find the key in your config directory.
    Enter passphrase for new root key with ID d19e454:
    Repeat passphrase for new root key with ID d19e454:
    Enter passphrase for new repository key with ID 72a332e:
    Repeat passphrase for new repository key with ID 72a332e:
    Successfully initialized "localhost/library/alpine"
    Successfully added signer: my-signing-role to localhost/library/alpine
    ```

9.  Tag and sign a new image using your newly generated keys. This will automatically
    trigger a push.

    ```bash
    $ docker tag alpine:3.13 localhost/library/alpine:signed
    $ docker trust sign localhost/library/alpine:signed
    Signing and pushing trust data for local image localhost/library/alpine:signed, may overwrite remote trust data
    The push refers to repository [localhost/library/alpine]
    c04d1437198b: Layer already exists
    signed: digest: sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515 size: 528
    Signing and pushing trust metadata
    Enter passphrase for my-signing-role key with ID e4a96c7:
    Successfully signed localhost/library/alpine:signed
    ```

10. Remove both the signed and unsigned image to validate that docker will allow
    the signed image to be pulled and the unsigned image will be blocked. We enable
    this on `docker pull` and `docker push` commands by setting the `DOCKER_CONTENT_TRUST=1`
    environment variable.

    ```bash
    $ docker image rm localhost/library/alpine:3.13 localhost/library/alpine:signed
    Untagged: localhost/library/alpine:3.13
    Untagged: localhost/library/alpine:signed
    Untagged: localhost/library/alpine@sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515

    $ DOCKER_CONTENT_TRUST=1 docker pull localhost/library/alpine:3.13
    No valid trust data for 3.13

    $ DOCKER_CONTENT_TRUST=1 docker pull localhost/library/alpine:signed
    Pull (1 of 1): localhost/library/alpine:signed@sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515
    sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515: Pulling from library/alpine
    Digest: sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515
    Status: Downloaded newer image for localhost/library/alpine@sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515
    Tagging localhost/library/alpine@sha256:d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515 as localhost/library/alpine:signed
    localhost/library/alpine:signed
    ```

11. Finally you can inspect the images using the `docker trust inspect` command.
    Notice the missing signatures on the unsigned image.

    ```bash
    $ docker trust inspect --pretty localhost/library/alpine:3.13

    No signatures for localhost/library/alpine:3.13


    List of signers and their keys for localhost/library/alpine:3.13

    SIGNER              KEYS
    my-signing-role     e4a96c72eb57

    Administrative keys for localhost/library/alpine:3.13

    Repository Key:       72a332ebbb5c0f77777f6713548101f9fbf0bd577cffebab3efd0ce27fb856e2
    Root Key:     e9a66b42524e4a9cefa003aa56f673766cf17aeb7cf277bb6a188c20dc63b653

    $ docker trust inspect --pretty localhost/library/alpine:signed

    Signatures for localhost/library/alpine:signed

    SIGNED TAG          DIGEST                                                             SIGNERS
    signed              d0710affa17fad5f466a70159cc458227bd25d4afb39514ef662ead3e6c99515   my-signing-role

    List of signers and their keys for localhost/library/alpine:signed

    SIGNER              KEYS
    my-signing-role     e4a96c72eb57

    Administrative keys for localhost/library/alpine:signed

    Repository Key:       72a332ebbb5c0f77777f6713548101f9fbf0bd577cffebab3efd0ce27fb856e2
    Root Key:     e9a66b42524e4a9cefa003aa56f673766cf17aeb7cf277bb6a188c20dc63b653
    ```