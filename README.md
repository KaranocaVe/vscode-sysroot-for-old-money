# vscode-sysroot-for-old-money

给旧版 glibc Linux 主机使用的 VS Code Remote-SSH sysroot。

这个仓库对应 [vscode-remote-faq.md](./vscode-remote-faq.md) 里“旧版 glibc
主机通过自备 sysroot 继续运行新版 VS Code Server”的 workaround。每当
`microsoft/vscode` 发布新的 stable 版，这个仓库的 GitHub Actions 会自动构建
对应的 sysroot，并发布到本仓库的 GitHub Release。

## 这是什么

从 VS Code `1.99` 开始，官方预编译的 Linux server 只支持 `glibc >= 2.28`
的发行版。老机器如果还是更低版本的 glibc，可以通过下面三个环境变量让
Remote-SSH 在安装 server 时用你提供的 sysroot 来打补丁：

- `VSCODE_SERVER_CUSTOM_GLIBC_LINKER`
- `VSCODE_SERVER_CUSTOM_GLIBC_PATH`
- `VSCODE_SERVER_PATCHELF_PATH`

这个仓库发布的就是配套 sysroot。

## Release 里有什么

每个 release 都按 VS Code 版本命名：

- tag 形如 `vscode-1.121.0`

每个 release 默认包含：

- `x86_64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz`
- `aarch64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz`
- `SHA256SUMS`

注意：

- `x86_64` 给远端 Linux 是 `x86_64 / amd64` 的机器用
- `aarch64` 给远端 Linux 是 `arm64 / aarch64` 的机器用
- 这里打包的是完整的 Crosstool-NG 输出目录，不只是单独一个 `sysroot/`

## 使用前准备

远端主机需要：

1. 已安装 `patchelf >= 0.18`
2. 能把 sysroot 解压到一个固定目录
3. 在 Remote-SSH 启动 VS Code Server 前，让 shell 环境里带上那三个
   `VSCODE_SERVER_*` 变量

如果你不确定远端机器架构，可以先在远端执行：

```sh
uname -m
```

常见结果：

- `x86_64`：走下面的 `x86_64 / amd64` 配置
- `aarch64`：走下面的 `arm64 / aarch64` 配置

## x86_64 / amd64 远端主机

下载 release 里的这个文件：

- `x86_64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz`

示例步骤：

```sh
mkdir -p /opt/vscode-sysroots
cd /opt/vscode-sysroots

tar -xzf x86_64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz
```

解压后目录应类似：

```sh
/opt/vscode-sysroots/x86_64-linux-gnu/
```

然后在远端 shell 配置里加入：

```sh
export VSCODE_SERVER_PATCHELF_PATH=/usr/local/bin/patchelf

export VSCODE_SYSROOT_ROOT=/opt/vscode-sysroots/x86_64-linux-gnu

export VSCODE_SERVER_CUSTOM_GLIBC_LINKER="$VSCODE_SYSROOT_ROOT/x86_64-linux-gnu/sysroot/lib64/ld-linux-x86-64.so.2"

export VSCODE_SERVER_CUSTOM_GLIBC_PATH="$VSCODE_SYSROOT_ROOT/x86_64-linux-gnu/sysroot/lib64:$VSCODE_SYSROOT_ROOT/x86_64-linux-gnu/sysroot/lib/x86_64-linux-gnu:$VSCODE_SYSROOT_ROOT/x86_64-linux-gnu/sysroot/usr/lib/x86_64-linux-gnu"
```

可选检查：

```sh
test -x "$VSCODE_SERVER_PATCHELF_PATH"
test -f "$VSCODE_SERVER_CUSTOM_GLIBC_LINKER"
printf '%s\n' "$VSCODE_SERVER_CUSTOM_GLIBC_PATH" | tr ':' '\n'
```

## arm64 / aarch64 远端主机

下载 release 里的这个文件：

- `aarch64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz`

示例步骤：

```sh
mkdir -p /opt/vscode-sysroots
cd /opt/vscode-sysroots

tar -xzf aarch64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz
```

解压后目录应类似：

```sh
/opt/vscode-sysroots/aarch64-linux-gnu/
```

然后在远端 shell 配置里加入：

```sh
export VSCODE_SERVER_PATCHELF_PATH=/usr/local/bin/patchelf

export VSCODE_SYSROOT_ROOT=/opt/vscode-sysroots/aarch64-linux-gnu

export VSCODE_SERVER_CUSTOM_GLIBC_LINKER="$VSCODE_SYSROOT_ROOT/aarch64-linux-gnu/sysroot/lib/ld-linux-aarch64.so.1"

export VSCODE_SERVER_CUSTOM_GLIBC_PATH="$VSCODE_SYSROOT_ROOT/aarch64-linux-gnu/sysroot/lib:$VSCODE_SYSROOT_ROOT/aarch64-linux-gnu/sysroot/lib/aarch64-linux-gnu:$VSCODE_SYSROOT_ROOT/aarch64-linux-gnu/sysroot/usr/lib/aarch64-linux-gnu"
```

可选检查：

```sh
test -x "$VSCODE_SERVER_PATCHELF_PATH"
test -f "$VSCODE_SERVER_CUSTOM_GLIBC_LINKER"
printf '%s\n' "$VSCODE_SERVER_CUSTOM_GLIBC_PATH" | tr ':' '\n'
```

## 变量分别是干什么的

- `VSCODE_SERVER_CUSTOM_GLIBC_LINKER`
  Remote-SSH 会把它传给 `patchelf --set-interpreter`
- `VSCODE_SERVER_CUSTOM_GLIBC_PATH`
  Remote-SSH 会把它传给 `patchelf --set-rpath`
- `VSCODE_SERVER_PATCHELF_PATH`
  指向远端机器上的 `patchelf`

如果这三个变量没有在 Remote-SSH 启动 server 时生效，VS Code 还是会按默认
方式检查 glibc，然后继续报不满足要求。

## 自动构建

workflow 在：

- [.github/workflows/build-sysroot-on-vscode-release.yml](.github/workflows/build-sysroot-on-vscode-release.yml)

行为：

- 定时轮询 `microsoft/vscode` 最新 stable release
- 如果本仓库还没有对应的 `vscode-<version>` release，就启动构建
- 也支持 `workflow_dispatch` 手动补跑

## 构建来源

构建过程 vendoring 了 `microsoft/vscode-linux-build-agent` 的一小部分文件，
并固定到提交：

- `f401367ecd1ebd9edef4a9cfcd433691f3c634d8`

文件放在：

- [third_party/vscode-linux-build-agent](./third_party/vscode-linux-build-agent)

这样可以避免 GitHub Actions 在运行时依赖上游 `main` 分支，保证构建更可复现。
