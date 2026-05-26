#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THIRD_PARTY_DIR="$ROOT_DIR/third_party/vscode-linux-build-agent"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/.work}"
BUILD_DIR="$WORK_DIR/build"
DIST_DIR="$WORK_DIR/dist"
CTNG_VERSION="${CTNG_VERSION:-1.26.0}"
CTNG_ARCHIVE="crosstool-ng-${CTNG_VERSION}.tar.xz"
CTNG_URL="${CTNG_URL:-https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-${CTNG_VERSION}/${CTNG_ARCHIVE}}"
CTNG_SHA512="${CTNG_SHA512:-7834184ae5792fd347455f9f48fee826248dcb82d271954ed4304b1a18f63995ff8a2c3b817564dcf147ac7e16e02d779195b26d97eb57db27f1118a1837002a}"
CTNG_SRC_DIR="$BUILD_DIR/crosstool-ng-${CTNG_VERSION}"
CTNG_PREFIX="$BUILD_DIR/crosstool-ng"

usage() {
  cat <<'EOF'
Usage: build-sysroot.sh <target>

Targets:
  x64    Build x86_64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz
  arm64  Build aarch64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz
EOF
}

log() {
  printf '==> %s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

install_ctng() {
  if [ -x "$CTNG_PREFIX/bin/ct-ng" ]; then
    return
  fi

  mkdir -p "$BUILD_DIR"
  cd "$BUILD_DIR"

  if [ ! -f "$CTNG_ARCHIVE" ]; then
    log "Downloading ${CTNG_ARCHIVE}"
    curl -fsSL "$CTNG_URL" -o "$CTNG_ARCHIVE"
  fi

  log "Verifying ${CTNG_ARCHIVE}"
  printf '%s  %s\n' "$CTNG_SHA512" "$CTNG_ARCHIVE" | sha512sum -c -

  if [ ! -d "$CTNG_SRC_DIR" ]; then
    log "Extracting ${CTNG_ARCHIVE}"
    tar -xJf "$CTNG_ARCHIVE"
  fi

  log "Building Crosstool-NG ${CTNG_VERSION}"
  cd "$CTNG_SRC_DIR"
  ./configure --prefix="$CTNG_PREFIX"
  make -j"$(nproc)"
  make install
}

target_config() {
  case "$1" in
    x64)
      echo "config=$THIRD_PARTY_DIR/x86_64-gcc-10.5.0-glibc-2.28.config"
      echo "tuple=x86_64-linux-gnu"
      echo "sysroot_arch=amd64"
      echo "archive=x86_64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz"
      ;;
    arm64)
      echo "config=$THIRD_PARTY_DIR/aarch64-gcc-10.5.0-glibc-2.28.config"
      echo "tuple=aarch64-linux-gnu"
      echo "sysroot_arch=arm64"
      echo "archive=aarch64-linux-gnu-glibc-2.28-gcc-10.5.0.tar.gz"
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
}

main() {
  if [ "$#" -ne 1 ]; then
    usage >&2
    exit 1
  fi

  require_cmd curl
  require_cmd sha512sum
  require_cmd tar
  require_cmd nproc

  eval "$(target_config "$1")"

  install_ctng

  export PATH="$CTNG_PREFIX/bin:$PATH"
  require_cmd ct-ng

  local build_root="$BUILD_DIR/$tuple"
  rm -rf "$build_root"
  mkdir -p "$build_root"
  mkdir -p "$DIST_DIR"

  log "Preparing ${tuple}"
  cp "$config" "$build_root/.config"

  log "Running ct-ng build for ${tuple}"
  (
    cd "$build_root"
    ct-ng build
  )

  log "Adding Debian sysroot packages for ${tuple}"
  (
    cd "$THIRD_PARTY_DIR/sysroot-scripts"
    chmod 0755 -R "$build_root/$tuple"
    ./sysroot-creator.sh build \
      "$sysroot_arch" \
      "$build_root/$tuple/$tuple/sysroot"
  )

  log "Packaging ${archive}"
  (
    cd "$build_root"
    tar -czf "$DIST_DIR/$archive" "$tuple"
  )

  log "Created $DIST_DIR/$archive"
}

main "$@"
