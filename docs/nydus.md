# Lazy-pulling using Nydus Snapshotter

| :zap: Requirement | mikodctl >= 0.22 |
| ----------------- | --------------- |

Nydus snapshotter is a remote snapshotter plugin of containerd for [Nydus](https://github.com/dragonflyoss/image-service) image service which implements a chunk-based content-addressable filesystem that improves the current OCI image specification, in terms of container launching speed, image space, and network bandwidth efficiency, as well as data integrity with several runtime backends: FUSE, virtiofs and in-kernel EROFS (Linux kernel 5.19+).

## Enable lazy-pulling for `mikodctl run`

- Install containerd remote snapshotter plugin (`containerd-nydus-grpc`) from https://github.com/containerd/nydus-snapshotter

- Add the following to `/etc/containerd/config.toml`:
```toml
[proxy_plugins]
  [proxy_plugins.nydus]
    type = "snapshot"
    address = "/run/containerd-nydus-grpc/containerd-nydus-grpc.sock"

# Optional: Configure nydus for image unpacking (allows automatic snapshotter selection)
[[plugins."io.containerd.transfer.v1.local".unpack_config]]
  platform = "linux"
  snapshotter = "nydus"
```

- Launch `containerd` and `containerd-nydus-grpc`

- Run `mikodctl` with `--snapshotter=nydus`
```console
# mikodctl --snapshotter=nydus run -it --rm ghcr.io/dragonflyoss/image-service/ubuntu:nydus-nightly-v5
```

For the list of pre-converted Nydus images, see https://github.com/orgs/dragonflyoss/packages?page=1&repo_name=image-service

## Build Nydus image using `mikodctl image convert`

Nerdctl supports to convert an OCI image or docker format v2 image to Nydus image by using the `mikodctl image convert` command.

Before the conversion, you should have the `nydus-image` binary installed, which is contained in the ["nydus static package"](https://github.com/dragonflyoss/image-service/releases). You can run the command like `mikodctl image convert --nydus --oci --nydus-builder-path <the_path_of_nydus_image_binary> <source_image> <target_image>` to convert the `<source_image>` to a Nydus image whose tag is `<target_image>`.

By now, the converted Nydus image cannot be run directly. It shoud be unpacked to nydus snapshotter before `mikodctl run`, which is a part of the processing flow of `mikodctl image pull`. So you need to push the converted image to a registry after the conversion and use `mikodctl --snapshotter nydus image pull` to unpack it to the nydus snapshotter before running the image.

Optionally, you can use the nydusify conversion tool to check if the format of the converted Nydus image is valid. For more details about the Nydus image validation and how to build Nydus image, please refer to [nydusify](https://github.com/dragonflyoss/image-service/blob/master/docs/nydusify.md) and [acceld](https://github.com/goharbor/acceleration-service).
