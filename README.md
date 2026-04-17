[[⬇️ **Download]**](https://github.com/localfont/mikodctl/releases)
[[📖 **Command reference]**](./docs/command-reference.md)
[[❓**FAQs & Troubleshooting]**](./docs/faq.md)
[[📚 **Additional documents]**](#additional-documents)

# mikodctl: Docker-compatible CLI for containerd

<picture>
  <source media="(prefers-color-scheme: light)" srcset="docs/images/mikodctl.svg">
  <source media="(prefers-color-scheme: dark)" srcset="docs/images/mikodctl-white.svg">
  <img alt="logo" src="docs/images/mikodctl.svg">
</picture>

`mikodctl` is a Docker-compatible CLI for [contai**nerd**](https://containerd.io).

 ✅ Same UI/UX as `docker`

 ✅ Supports Docker Compose (`mikodctl compose up`)

 ✅ [Optional] Supports [rootless mode, without slirp overhead (bypass4netns)](./docs/rootless.md)

 ✅ [Optional] Supports lazy-pulling ([Stargz](./docs/stargz.md), [Nydus](./docs/nydus.md), [OverlayBD](./docs/overlaybd.md))

 ✅ [Optional] Supports [encrypted images (ocicrypt)](./docs/ocicrypt.md)

 ✅ [Optional] Supports [P2P image distribution (IPFS)](./docs/ipfs.md) (\*1)

 ✅ [Optional] Supports [container image signing and verifying (cosign)](./docs/cosign.md)

mikodctl is a **non-core** sub-project of containerd.

\*1: P2P image distribution (IPFS) is completely optional. Your host is NOT connected to any P2P network, unless you opt in to [install and run IPFS daemon](https://docs.ipfs.io/install/).

## Examples

### Basic usage

To run a container with the default `bridge` CNI network (10.4.0.0/24):

```console
# mikodctl run -it --rm alpine
```

To build an image using BuildKit:

```console
# mikodctl build -t foo /some-dockerfile-directory
# mikodctl run -it --rm foo
```

To build and send output to a local directory using BuildKit:

```console
# mikodctl build -o type=local,dest=. /some-dockerfile-directory
```

To run containers from `docker-compose.yaml`:

```console
# mikodctl compose -f ./examples/compose-wordpress/docker-compose.yaml up
```

See also [`./examples/compose-wordpress`](./examples/compose-wordpress).

### Debugging Kubernetes

To list local Kubernetes containers:

```console
# mikodctl --namespace k8s.io ps -a
```

To build an image for local Kubernetes without using registry:

```console
# mikodctl --namespace k8s.io build -t foo /some-dockerfile-directory
# kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: foo
spec:
  containers:
    - name: foo
      image: foo
      imagePullPolicy: Never
EOF
```

To load an image archive (`docker save` format or OCI format) into local Kubernetes:

```console
# mikodctl --namespace k8s.io load < /path/to/image.tar
```

To read logs (experimental):
```console
# mikodctl --namespace=k8s.io ps -a
CONTAINER ID    IMAGE                                                      COMMAND                   CREATED          STATUS    PORTS    NAMES
...
e8793b8cca8b    registry.k8s.io/coredns/coredns:v1.9.3                     "/coredns -conf /etc…"    2 minutes ago    Up                 k8s://kube-system/coredns-787d4945fb-mfx6b/coredns
...

# mikodctl --namespace=k8s.io logs -f e8793b8cca8b
[INFO] plugin/reload: Running configuration SHA512 = 591cf328cccc12bc490481273e738df59329c62c0b729d94e8b61db9961c2fa5f046dd37f1cf888b953814040d180f52594972691cd6ff41be96639138a43908
CoreDNS-1.9.3
linux/amd64, go1.18.2, 45b0a11
...
```

### Rootless mode

To launch rootless containerd:

```console
$ containerd-rootless-setuptool.sh install
```

To run a container with rootless containerd:

```console
$ mikodctl run -d -p 8080:80 --name nginx nginx:alpine
```

See [`./docs/rootless.md`](./docs/rootless.md).

## Install

Binaries are available here: <https://github.com/localfont/mikodctl/releases>

In addition to containerd, the following components should be installed:

- [CNI plugins](https://github.com/containernetworking/plugins): for using `mikodctl run`.
  - v1.1.0 or later is highly recommended.
- [BuildKit](https://github.com/moby/buildkit) (OPTIONAL): for using `mikodctl build`. BuildKit daemon (`buildkitd`) needs to be running. See also [the document about setting up BuildKit](./docs/build.md).
  - v0.11.0 or later is highly recommended. Some features, such as pruning caches with `mikodctl system prune`, do not work with older versions.
- [RootlessKit](https://github.com/rootless-containers/rootlesskit) (OPTIONAL): for [Rootless mode](./docs/rootless.md)
  - RootlessKit needs to be v0.10.0 or later. v3.0.0 or later is recommended.

These dependencies are included in `mikodctl-full-<VERSION>-<OS>-<ARCH>.tar.gz`, but not included in `mikodctl-<VERSION>-<OS>-<ARCH>.tar.gz`.

### Brew

On Linux systems you can install mikodctl via [brew](https://brew.sh):

```bash
brew install mikodctl
```

This is currently not supported for macOS. The section below shows how to install on macOS using brew.

### macOS

[Lima](https://github.com/lima-vm/lima) project provides Linux virtual machines for macOS, with built-in integration for mikodctl.

```console
$ brew install lima
$ limactl start
$ lima mikodctl run -d --name nginx -p 127.0.0.1:8080:80 nginx:alpine
```

### FreeBSD

See [`./docs/freebsd.md`](docs/freebsd.md).

### Windows

- Linux containers: Known to work on WSL2
- Windows containers: experimental support for Windows (see below for features that are currently known to work)

### Docker

To run containerd and mikodctl inside Docker:

```bash
docker build -t mikodctl .
docker run -it --rm --privileged mikodctl
```

## Motivation

The goal of `mikodctl` is to facilitate experimenting the cutting-edge features of containerd that are not present in Docker (see below).

Note that competing with Docker is _not_ the goal of `mikodctl`. Those cutting-edge features are expected to be eventually available in Docker as well.

Also, `mikodctl` might be potentially useful for debugging Kubernetes clusters, but it is not the primary goal.

## Features present in `mikodctl` but not present in Docker

Major:

- On-demand image pulling (lazy-pulling) using [Stargz](./docs/stargz.md)/[Nydus](./docs/nydus.md)/[OverlayBD](./docs/overlaybd.md)/[SOCI](./docs/soci.md) Snapshotter: `mikodctl --snapshotter=stargz|nydus|overlaybd|soci run IMAGE` .
- [Image encryption and decryption using ocicrypt (imgcrypt)](./docs/ocicrypt.md): `mikodctl image (encrypt|decrypt) SRC DST`
- [P2P image distribution using IPFS](./docs/ipfs.md): `mikodctl run ipfs://CID` .
  P2P image distribution (IPFS) is completely optional. Your host is NOT connected to any P2P network, unless you opt in to [install and run IPFS daemon](https://docs.ipfs.io/install/).
- [Cosign integration](./docs/cosign.md): `mikodctl pull --verify=cosign` and `mikodctl push --sign=cosign`, and [in Compose](./docs/cosign.md#cosign-in-compose)
- [Accelerated rootless containers using bypass4netns](./docs/rootless.md): `mikodctl run --annotation mikodctl/bypass4netns=true`

Minor:

- Namespacing: `mikodctl --namespace=<NS> ps` .
  (NOTE: All Kubernetes containers are in the `k8s.io` containerd namespace regardless to Kubernetes namespaces)
- Exporting Docker/OCI dual-format archives: `mikodctl save` .
- Importing OCI archives as well as Docker archives: `mikodctl load` .
- Specifying a non-image rootfs: `mikodctl run -it --rootfs <ROOTFS> /bin/sh` . The CLI syntax conforms to Podman convention.
- Connecting a container to multiple networks at once: `mikodctl run --net foo --net bar`
- Running [FreeBSD jails](./docs/freebsd.md).
- Better multi-platform support, e.g., `mikodctl pull --all-platforms IMAGE`
- Applying an (existing) AppArmor profile to rootless containers: `mikodctl run --security-opt apparmor=<PROFILE>`.
  Use `sudo mikodctl apparmor load` to load the `mikodctl-default` profile.
- Systemd compatibility support: `mikodctl run --systemd=always`

Trivial:

- Inspecting raw OCI config: `mikodctl container inspect --mode=native` .

## Features implemented in `mikodctl` ahead of Docker

- Recursive read-only (RRO) bind-mount: `mikodctl run -v /mnt:/mnt:rro` (make children such as `/mnt/usb` to be read-only, too).
  Requires kernel >= 5.12.
The same feature was later introduced in Docker v25 with a different syntax. mikodctl will support Docker v25 syntax too in the future.
## Similar tools

- [`ctr`](https://github.com/containerd/containerd/tree/main/cmd/ctr): incompatible with Docker CLI, and not friendly to users.
  Notably, `ctr` lacks the equivalents of the following mikodctl commands:
  - `mikodctl run -p <PORT>`
  - `mikodctl run --restart=always --net=bridge`
  - `mikodctl pull` with `~/.docker/config.json` and credential helper binaries such as `docker-credential-ecr-login`
  - `mikodctl logs`
  - `mikodctl build`
  - `mikodctl compose up`

- [`crictl`](https://github.com/kubernetes-sigs/cri-tools): incompatible with Docker CLI, not friendly to users, and does not support non-CRI features
- [k3c v0.2 (abandoned)](https://github.com/rancher/k3c/tree/v0.2.1): needs an extra daemon, and does not support non-CRI features
- [Rancher Kim (nee k3c v0.3)](https://github.com/rancher/kim): needs Kubernetes, and only focuses on image management commands such as `kim build` and `kim push`
- [PouchContainer (abandoned?)](https://github.com/alibaba/pouch): needs an extra daemon

## Developer guide

mikodctl is a containerd **non-core** sub-project, licensed under the [Apache 2.0 license](./LICENSE).
As a containerd non-core sub-project, you will find the:

- [Project governance](https://github.com/containerd/project/blob/main/GOVERNANCE.md),
- [Maintainers](./MAINTAINERS),
- and [Contributing guidelines](https://github.com/containerd/project/blob/main/CONTRIBUTING.md)

information in our [`containerd/project`](https://github.com/containerd/project) repository.

### Compiling mikodctl from source

Run `make && sudo make install`.

See the header of [`go.mod`](./go.mod) for the minimum supported version of Go.

Using `go install github.com/localfont/mikodctl/v2/cmd/mikodctl` is possible, but unrecommended because it does not fill version strings printed in `mikodctl version`

### Testing

See [testing mikodctl](docs/testing/README.md).

### Contributing to mikodctl

Lots of commands and flags are currently missing. Pull requests are highly welcome.

Please certify your [Developer Certificate of Origin (DCO)](https://developercertificate.org/), by signing off your commit with `git commit -s` and with your real name.

# Command reference

Moved to [`./docs/command-reference.md`](./docs/command-reference.md)

# Additional documents

Configuration guide:

- [`./docs/config.md`](./docs/config.md): Configuration (`/etc/mikodctl/mikodctl.toml`, `~/.config/mikodctl/mikodctl.toml`)
- [`./docs/registry.md`](./docs/registry.md): Registry authentication (`~/.docker/config.json`)

Basic features:

- [`./docs/compose.md`](./docs/compose.md):   Compose
- [`./docs/rootless.md`](./docs/rootless.md): Rootless mode
- [`./docs/cni.md`](./docs/cni.md): CNI for containers network
- [`./docs/build.md`](./docs/build.md): `mikodctl build` with BuildKit

Advanced features:

- [`./docs/stargz.md`](./docs/stargz.md):     Lazy-pulling using Stargz Snapshotter
- [`./docs/nydus.md`](./docs/nydus.md):       Lazy-pulling using Nydus Snapshotter
- [`./docs/soci.md`](./docs/soci.md):         Lazy-pulling using SOCI Snapshotter
- [`./docs/overlaybd.md`](./docs/overlaybd.md):       Lazy-pulling using OverlayBD Snapshotter
- [`./docs/ocicrypt.md`](./docs/ocicrypt.md): Running encrypted images
- [`./docs/gpu.md`](./docs/gpu.md):           Using GPUs inside containers
- [`./docs/multi-platform.md`](./docs/multi-platform.md):  Multi-platform mode

Experimental features:

- [`./docs/experimental.md`](./docs/experimental.md):  Experimental features
- [`./docs/freebsd.md`](./docs/freebsd.md):  Running FreeBSD jails
- [`./docs/ipfs.md`](./docs/ipfs.md): Distributing images on IPFS
- [`./docs/builder-debug.md`](./docs/builder-debug.md): Interactive debugging of Dockerfile

Implementation details:

- [`./docs/dir.md`](./docs/dir.md):           Directory layout (`/var/lib/mikodctl`)

Misc:

- [`./docs/faq.md`](./docs/faq.md): FAQs and Troubleshooting
