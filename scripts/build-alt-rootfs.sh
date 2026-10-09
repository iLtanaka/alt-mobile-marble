#!/bin/bash
# build-alt-rootfs.sh: Assemble ALT Mobile rootfs for Xiaomi Poco F5 (marble)
# Requires: root privileges or fakeroot/proot, wget, tar, zstd
set -euo pipefail

ALT_ROOTFS_URL="https://beta.altlinux.org/mobile/sisyphus/latest/alt-mobile-phosh-sdm845-latest-aarch64.tar.xz"
WORKDIR="$(pwd)/build-rootfs"
OUTDIR="$(pwd)/out"
ROOTFS_TAR="alt-mobile-base.tar.xz"

echo "[1/4] Downloading official ALT Mobile Sisyphus rootfs..."
if [ ! -f "$ROOTFS_TAR" ]; then
    wget -c "$ALT_ROOTFS_URL" -O "$ROOTFS_TAR"
fi

echo "[2/4] Unpacking base rootfs..."
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR" "$OUTDIR"
tar -xpf "$ROOTFS_TAR" -C "$WORKDIR" --numeric-owner

echo "[3/4] Installing marble-device-support overlay..."
if [ -d "../marble-device-support" ]; then
    make -C "../marble-device-support" install DESTDIR="$WORKDIR" PREFIX=/usr
else
    echo "Warning: marble-device-support not found adjacent to this repository. Clone it to ../marble-device-support"
fi

echo "[4/4] Finalizing rootfs archive..."
mkdir -p "$WORKDIR/etc/marble"
echo "phoc phosh" > "$WORKDIR/etc/marble/compositors"
echo "xiaomi-marble-alt" > "$WORKDIR/etc/hostname"

echo "Done. The prepared rootfs is in $WORKDIR."
