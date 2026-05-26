#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THIRD_PARTY_DIR="$ROOT_DIR/third_party/vscode-linux-build-agent"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/.work}"
BUILD_DIR="$WORK_DIR/build"
DIST_DIR="$WORK_DIR/dist"
LOG_DIR="$WORK_DIR/logs"
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

append_summary() {
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    printf '%s\n' "$*" >>"$GITHUB_STEP_SUMMARY"
  fi
}

show_log_tail() {
  local log_file="$1"

  if [ -f "$log_file" ]; then
    echo "::group::Last 200 lines of $(basename "$log_file")"
    tail -n 200 "$log_file"
    echo "::endgroup::"
  fi
}

run_logged() {
  local label="$1"
  local log_file="$2"
  shift 2

  mkdir -p "$(dirname "$log_file")"

  log "$label"
  printf '# %s\n' "$label" >"$log_file"
  printf 'Started: %s\n\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >>"$log_file"

  if "$@" >>"$log_file" 2>&1; then
    log "Finished ${label}"
    append_summary "- ${label}: success"
  else
    log "Failed ${label}. Full log: ${log_file}"
    append_summary "- ${label}: failed"
    show_log_tail "$log_file"
    return 1
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

build_ctng_impl() {
  local src_dir="$1"
  local prefix="$2"

  cd "$src_dir"
  ./configure --prefix="$prefix"
  make -j"$(nproc)"
  make install
}

ctng_build_impl() {
  local build_root="$1"

  cd "$build_root"
  ct-ng build
}

sysroot_creator_impl() {
  local scripts_dir="$1"
  local build_root="$2"
  local tuple="$3"
  local sysroot_arch="$4"

  cd "$scripts_dir"
  chmod 0755 -R "$build_root/$tuple"
  ./sysroot-creator.sh build \
    "$sysroot_arch" \
    "$build_root/$tuple/$tuple/sysroot"
}

package_impl() {
  local build_root="$1"
  local dist_dir="$2"
  local archive="$3"
  local tuple="$4"

  cd "$build_root"
  tar -czf "$dist_dir/$archive" "$tuple"
}

install_ctng() {
  if [ -x "$CTNG_PREFIX/bin/ct-ng" ]; then
    log "Using cached Crosstool-NG at ${CTNG_PREFIX}"
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

  run_logged \
    "Building Crosstool-NG ${CTNG_VERSION}" \
    "$LOG_DIR/ct-ng-bootstrap.log" \
    build_ctng_impl \
    "$CTNG_SRC_DIR" \
    "$CTNG_PREFIX"
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

  mkdir -p "$BUILD_DIR" "$DIST_DIR" "$LOG_DIR"
  append_summary "## ${tuple}"

  install_ctng

  export PATH="$CTNG_PREFIX/bin:$PATH"
  require_cmd ct-ng

  local build_root="$BUILD_DIR/$tuple"
  rm -rf "$build_root"
  mkdir -p "$build_root"

  log "Preparing ${tuple}"
  cp "$config" "$build_root/.config"
  append_summary "- Log directory: \`$LOG_DIR\`"

  run_logged \
    "Running ct-ng build for ${tuple}" \
    "$LOG_DIR/${tuple}.ct-ng-build.log" \
    ctng_build_impl \
    "$build_root"

  run_logged \
    "Adding Debian sysroot packages for ${tuple}" \
    "$LOG_DIR/${tuple}.sysroot-creator.log" \
    sysroot_creator_impl \
    "$THIRD_PARTY_DIR/sysroot-scripts" \
    "$build_root" \
    "$tuple" \
    "$sysroot_arch"

  run_logged \
    "Packaging ${archive}" \
    "$LOG_DIR/${tuple}.package.log" \
    package_impl \
    "$build_root" \
    "$DIST_DIR" \
    "$archive" \
    "$tuple"

  log "Created $DIST_DIR/$archive"
  append_summary "- Archive: \`$DIST_DIR/$archive\`"
}

main "$@"
