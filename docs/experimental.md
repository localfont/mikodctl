# Experimental features of mikodctl

The following features are experimental and subject to change.
See [`./config.md`](config.md) about how to enable these features.

- [Windows containers](https://github.com/localfont/mikodctl/issues/28)
- [FreeBSD containers](./freebsd.md)
- Flags of `mikodctl image convert`: `--estargz-record-in=FILE` and `--zstdchunked-record-in=FILE` (Importing an external eStargz record JSON file), `--estargz-external-toc` (Separating TOC JSON to another image).
  eStargz and zstd themselves are out of experimental.
- [Image Distribution on IPFS](./ipfs.md)
- [Image Sign and Verify (cosign)](./cosign.md)
- [Image Sign and Verify (notation)](./notation.md)
- [Rootless container networking acceleration with bypass4netns](./rootless.md#bypass4netns)
- [Interactive debugging of Dockerfile](./builder-debug.md)
- Kubernetes (`cri`) log viewer: `mikodctl --namespace=k8s.io logs`
