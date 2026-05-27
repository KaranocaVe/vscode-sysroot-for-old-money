# vscode-sysroot-for-old-money

给旧版 glibc Linux 主机使用的固定规格 VS Code Remote-SSH sysroot。  
Fixed VS Code Remote-SSH sysroots for older glibc-based Linux hosts.

这个仓库对应 [Remote Development FAQ](https://code.visualstudio.com/docs/remote/faq)
里“旧版 glibc 主机通过自备 sysroot 继续运行新版 VS Code Server”的 workaround。  
This repository follows the workaround described in the
[Remote Development FAQ](https://code.visualstudio.com/docs/remote/faq) for
running newer VS Code Server builds on older glibc-based Linux hosts with a
custom sysroot.

## 这是什么 / What This Is

从 VS Code `1.99` 开始，官方预编译的 Linux server 只支持 `glibc >= 2.28`
的发行版。老机器如果还是更低版本的 glibc，可以通过下面三个环境变量让
Remote-SSH 在安装 server 时用你提供的 sysroot 来打补丁：  
Starting with VS Code `1.99`, the official prebuilt Linux server only supports
distributions with `glibc >= 2.28`. Older remote machines can still use
Remote-SSH by providing a custom sysroot through these variables:

- `VSCODE_SERVER_CUSTOM_GLIBC_LINKER`
- `VSCODE_SERVER_CUSTOM_GLIBC_PATH`
- `VSCODE_SERVER_PATCHELF_PATH`

这个仓库发布的就是配套 sysroot。  
This repository publishes those sysroots.

## 重要说明 / Important Note

这里的构建产物是**固定规格的 sysroot**，不是“按每个 VS Code 版本重新定制”
的产物。  
The artifacts here are **fixed sysroot builds**, not custom sysroots rebuilt for
every individual VS Code version.

当前仓库支持“固定 profile 集合”，不是只支持唯一一套产物。  
This repository supports fixed profile sets, not just one single output.

也就是说：  
That means:

- release 对应的是一组明确的 sysroot profile
- 它和某个具体 VS Code patch 版本没有一一绑定关系
- 只要需求没变，就不需要反复重建

## Release 里有什么 / What The Release Contains

当前内建 profile 集合：  
Built-in profile sets:

- `default`
  - `x86_64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz`
  - `aarch64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz`
- `arm64-kernel-4.18`
  - `aarch64-linux-gnu-glibc-2.28-gcc-8.5.0-kernel-4.18.0.tar.gz`

默认 release tag：  
Default release tag:

- `glibc-2.28-gcc-10.5.0`

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
If you are not sure about the remote CPU architecture, run this first:

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

下载这个文件：  
Download this asset:

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

根据你的远端主机要求选择对应文件。  
Choose the asset that matches your remote host requirements.

常规 arm64：  
Default arm64:

- `aarch64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz`

较低内核基线 arm64：  
Lower-kernel-baseline arm64:

- `aarch64-linux-gnu-glibc-2.28-gcc-8.5.0-kernel-4.18.0.tar.gz`

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

## 自动构建 / Build Automation

workflow 在：  
The workflow lives at:

- [.github/workflows/build-sysroot.yml](.github/workflows/build-sysroot.yml)

行为：  
Behavior:

- 默认不再轮询每个 VS Code 版本  
  It no longer polls every VS Code version
- 只在 workflow 手动触发或构建定义本身变更时运行  
  It runs only on manual dispatch or when the build definition itself changes
- 可以通过 `profile_set` 选择要构建的 sysroot 集合  
  You can choose which sysroot set to build through `profile_set`
- 可以通过 `release_tag` 指定发布 tag  
  You can set the published release tag through `release_tag`
- 如果你更新了 toolchain、glibc 基线、最低内核、目标架构或上游脚本，再改
  profile 和 release tag 重新发布  
  If you change the toolchain, glibc baseline, minimum kernel, target
  architectures, or vendored upstream scripts, publish a new profile set and
  release tag

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
