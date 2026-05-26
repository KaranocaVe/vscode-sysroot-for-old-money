Vendored from `microsoft/vscode-linux-build-agent` commit
`f401367ecd1ebd9edef4a9cfcd433691f3c634d8`.

Included files:

- `x86_64-gcc-10.5.0-glibc-2.28.config`
- `aarch64-gcc-10.5.0-glibc-2.28.config`
- `sysroot-scripts/sysroot-creator.sh`
- `sysroot-scripts/merge-package-lists.py`
- `sysroot-scripts/keyring.gpg`
- `sysroot-scripts/generated_package_lists/bullseye.amd64`
- `sysroot-scripts/generated_package_lists/bullseye.arm64`

These files are pinned locally so GitHub Actions does not depend on the upstream
`main` branch at build time.
