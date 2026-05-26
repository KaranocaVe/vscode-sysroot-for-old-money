# vscode-sysroot-for-old-money

Prebuilt GNU sysroots for running newer VS Code Remote-SSH servers on older
glibc-based Linux hosts.

This repository follows the workaround documented in
[vscode-remote-faq.md](./vscode-remote-faq.md): when VS Code stable publishes a
new release, GitHub Actions builds fresh `glibc 2.28` sysroot tarballs for the
supported Linux server architectures and publishes them in a matching GitHub
Release.

## What gets published

Each release in this repository is tagged as `vscode-<version>`, for example
`vscode-1.121.0`.

Release assets:

- `x86_64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz`
- `aarch64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz`
- `SHA256SUMS`

The payload is the full Crosstool-NG output directory for the target tuple. It
includes the sysroot that VS Code patches its remote server against.

## Remote host setup

On the remote host:

1. Install `patchelf >= 0.18`.
2. Download and extract the matching tarball for your remote CPU architecture.
3. Point VS Code Remote-SSH at the extracted sysroot with these environment
   variables:

```sh
export VSCODE_SERVER_PATCHELF_PATH=/usr/local/bin/patchelf

SYSROOT_ROOT=/opt/vscode-sysroots/x86_64-linux-gnu

export VSCODE_SERVER_CUSTOM_GLIBC_LINKER="$(find "$SYSROOT_ROOT" \
  -path '*/sysroot/lib64/ld-linux-x86-64.so.2' -o \
  -path '*/sysroot/lib/ld-linux-aarch64.so.1' | head -n1)"

export VSCODE_SERVER_CUSTOM_GLIBC_PATH="$(
  find "$SYSROOT_ROOT" -type d \( \
    -path '*/sysroot/lib64' -o \
    -path '*/sysroot/lib/x86_64-linux-gnu' -o \
    -path '*/sysroot/lib/aarch64-linux-gnu' -o \
    -path '*/sysroot/usr/lib/x86_64-linux-gnu' -o \
    -path '*/sysroot/usr/lib/aarch64-linux-gnu' \
  \) | paste -sd:
)"
```

For `arm64`, set `SYSROOT_ROOT` to the extracted `aarch64-linux-gnu` directory.

VS Code uses:

- `VSCODE_SERVER_CUSTOM_GLIBC_LINKER` for `patchelf --set-interpreter`
- `VSCODE_SERVER_CUSTOM_GLIBC_PATH` for `patchelf --set-rpath`
- `VSCODE_SERVER_PATCHELF_PATH` to locate the `patchelf` binary

## Automation

The workflow lives at
[.github/workflows/build-sysroot-on-vscode-release.yml](.github/workflows/build-sysroot-on-vscode-release.yml).

Behavior:

- Poll `microsoft/vscode` stable releases on a schedule
- Skip versions that already have a `vscode-<version>` release in this repo
- Support manual backfill or rebuild with `workflow_dispatch`

## Vendored sources

The build uses a pinned snapshot of selected files from
`microsoft/vscode-linux-build-agent` at commit
`f401367ecd1ebd9edef4a9cfcd433691f3c634d8`, stored under
[`third_party/vscode-linux-build-agent`](./third_party/vscode-linux-build-agent).

That keeps builds reproducible instead of tracking the upstream `main` branch at
runtime.
