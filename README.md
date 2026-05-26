# vscode-sysroot-for-old-money

给旧版 glibc Linux 主机使用的 VS Code Remote-SSH sysroot。  
VS Code Remote-SSH sysroots for older glibc-based Linux hosts.

这个仓库对应 [vscode-remote-faq.md](./vscode-remote-faq.md) 里“旧版 glibc
主机通过自备 sysroot 继续运行新版 VS Code Server”的 workaround。每当
`microsoft/vscode` 发布新的 stable 版，这个仓库的 GitHub Actions 会自动构建
对应的 sysroot，并发布到本仓库的 GitHub Release。  
This repository follows the workaround described in
[vscode-remote-faq.md](./vscode-remote-faq.md): when `microsoft/vscode`
publishes a new stable release, GitHub Actions in this repository builds the
matching sysroots and publishes them as GitHub Releases.

## 这是什么 / What This Is

从 VS Code `1.99` 开始，官方预编译的 Linux server 只支持 `glibc >= 2.28`
的发行版。老机器如果还是更低版本的 glibc，可以通过下面三个环境变量让
Remote-SSH 在安装 server 时用你提供的 sysroot 来打补丁：  
Starting with VS Code `1.99`, the official prebuilt Linux server only supports
distributions with `glibc >= 2.28`. If your remote machine is older, you can
still use Remote-SSH by providing a custom sysroot through these three
environment variables:

- `VSCODE_SERVER_CUSTOM_GLIBC_LINKER`
- `VSCODE_SERVER_CUSTOM_GLIBC_PATH`
- `VSCODE_SERVER_PATCHELF_PATH`

这个仓库发布的就是配套 sysroot。  
This repository publishes those sysroots.

## Release 里有什么 / What Each Release Contains

每个 release 都按 VS Code 版本命名：  
Each release is named after a VS Code version:

- tag 形如 / tag format: `vscode-1.121.0`

每个 release 默认包含：  
Each release normally includes:

- `x86_64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz`
- `aarch64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz`
- `SHA256SUMS`

注意：  
Notes:

- `x86_64` 给远端 Linux 是 `x86_64 / amd64` 的机器用  
  `x86_64` is for remote Linux hosts with `x86_64 / amd64` CPUs
- `aarch64` 给远端 Linux 是 `arm64 / aarch64` 的机器用  
  `aarch64` is for remote Linux hosts with `arm64 / aarch64` CPUs
- 这里打包的是完整的 Crosstool-NG 输出目录，不只是单独一个 `sysroot/`  
  The archive contains the full Crosstool-NG output directory, not only the
  `sysroot/` subtree

## 使用前准备 / Prerequisites

远端主机需要：  
The remote host needs:

1. 已安装 `patchelf >= 0.18`  
   `patchelf >= 0.18` installed
2. 能把 sysroot 解压到一个固定目录  
   A fixed location where the sysroot can be extracted
3. 在 Remote-SSH 启动 VS Code Server 前，让 shell 环境里带上那三个
   `VSCODE_SERVER_*` 变量  
   The three `VSCODE_SERVER_*` variables available in the shell environment
   before Remote-SSH starts VS Code Server

如果你不确定远端机器架构，可以先在远端执行：  
If you are not sure about the remote CPU architecture, run this on the remote
host first:

```sh
uname -m
```

常见结果：  
Common results:

- `x86_64`：走下面的 `x86_64 / amd64` 配置  
  `x86_64`: use the `x86_64 / amd64` section below
- `aarch64`：走下面的 `arm64 / aarch64` 配置  
  `aarch64`: use the `arm64 / aarch64` section below

## x86_64 / amd64 远端主机 / x86_64 or amd64 Remote Host

下载 release 里的这个文件：  
Download this asset from the release:

- `x86_64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz`

示例步骤：  
Example:

```sh
mkdir -p /opt/vscode-sysroots
cd /opt/vscode-sysroots

tar -xzf x86_64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz
```

解压后目录应类似：  
After extraction, the directory should look like:

```sh
/opt/vscode-sysroots/x86_64-linux-gnu/
```

然后在远端 shell 配置里加入：  
Then add the following to the remote shell profile:

```sh
export VSCODE_SERVER_PATCHELF_PATH=/usr/local/bin/patchelf

export VSCODE_SYSROOT_ROOT=/opt/vscode-sysroots/x86_64-linux-gnu

export VSCODE_SERVER_CUSTOM_GLIBC_LINKER="$VSCODE_SYSROOT_ROOT/x86_64-linux-gnu/sysroot/lib64/ld-linux-x86-64.so.2"

export VSCODE_SERVER_CUSTOM_GLIBC_PATH="$VSCODE_SYSROOT_ROOT/x86_64-linux-gnu/sysroot/lib64:$VSCODE_SYSROOT_ROOT/x86_64-linux-gnu/sysroot/lib/x86_64-linux-gnu:$VSCODE_SYSROOT_ROOT/x86_64-linux-gnu/sysroot/usr/lib/x86_64-linux-gnu"
```

可选检查：  
Optional checks:

```sh
test -x "$VSCODE_SERVER_PATCHELF_PATH"
test -f "$VSCODE_SERVER_CUSTOM_GLIBC_LINKER"
printf '%s\n' "$VSCODE_SERVER_CUSTOM_GLIBC_PATH" | tr ':' '\n'
```

## arm64 / aarch64 远端主机 / arm64 or aarch64 Remote Host

下载 release 里的这个文件：  
Download this asset from the release:

- `aarch64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz`

示例步骤：  
Example:

```sh
mkdir -p /opt/vscode-sysroots
cd /opt/vscode-sysroots

tar -xzf aarch64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz
```

解压后目录应类似：  
After extraction, the directory should look like:

```sh
/opt/vscode-sysroots/aarch64-linux-gnu/
```

然后在远端 shell 配置里加入：  
Then add the following to the remote shell profile:

```sh
export VSCODE_SERVER_PATCHELF_PATH=/usr/local/bin/patchelf

export VSCODE_SYSROOT_ROOT=/opt/vscode-sysroots/aarch64-linux-gnu

export VSCODE_SERVER_CUSTOM_GLIBC_LINKER="$VSCODE_SYSROOT_ROOT/aarch64-linux-gnu/sysroot/lib/ld-linux-aarch64.so.1"

export VSCODE_SERVER_CUSTOM_GLIBC_PATH="$VSCODE_SYSROOT_ROOT/aarch64-linux-gnu/sysroot/lib:$VSCODE_SYSROOT_ROOT/aarch64-linux-gnu/sysroot/lib/aarch64-linux-gnu:$VSCODE_SYSROOT_ROOT/aarch64-linux-gnu/sysroot/usr/lib/aarch64-linux-gnu"
```

可选检查：  
Optional checks:

```sh
test -x "$VSCODE_SERVER_PATCHELF_PATH"
test -f "$VSCODE_SERVER_CUSTOM_GLIBC_LINKER"
printf '%s\n' "$VSCODE_SERVER_CUSTOM_GLIBC_PATH" | tr ':' '\n'
```

## 变量分别是干什么的 / What The Variables Do

- `VSCODE_SERVER_CUSTOM_GLIBC_LINKER`  
  Remote-SSH 会把它传给 `patchelf --set-interpreter`  
  Remote-SSH passes this to `patchelf --set-interpreter`

- `VSCODE_SERVER_CUSTOM_GLIBC_PATH`  
  Remote-SSH 会把它传给 `patchelf --set-rpath`  
  Remote-SSH passes this to `patchelf --set-rpath`

- `VSCODE_SERVER_PATCHELF_PATH`  
  指向远端机器上的 `patchelf`  
  Points to the `patchelf` binary on the remote host

如果这三个变量没有在 Remote-SSH 启动 server 时生效，VS Code 还是会按默认
方式检查 glibc，然后继续报不满足要求。  
If these variables are not visible when Remote-SSH starts the server, VS Code
will still perform the default glibc check and continue to fail on older
systems.

## 自动构建 / Automated Builds

workflow 在：  
The workflow lives at:

- [.github/workflows/build-sysroot-on-vscode-release.yml](.github/workflows/build-sysroot-on-vscode-release.yml)

行为：  
Behavior:

- 定时轮询 `microsoft/vscode` 最新 stable release  
  Poll the latest stable release from `microsoft/vscode`
- 如果本仓库还没有对应的 `vscode-<version>` release，就启动构建  
  Build when this repository does not yet have a matching `vscode-<version>`
  release
- 也支持 `workflow_dispatch` 手动补跑  
  Also supports manual backfills through `workflow_dispatch`

## 构建来源 / Build Inputs

构建过程 vendoring 了 `microsoft/vscode-linux-build-agent` 的一小部分文件，
并固定到提交：  
The build vendors a small subset of files from
`microsoft/vscode-linux-build-agent`, pinned to:

- `f401367ecd1ebd9edef4a9cfcd433691f3c634d8`

文件放在：  
The files live under:

- [third_party/vscode-linux-build-agent](./third_party/vscode-linux-build-agent)

这样可以避免 GitHub Actions 在运行时依赖上游 `main` 分支，保证构建更可复现。  
This avoids depending on the upstream `main` branch at runtime and makes builds
more reproducible.
