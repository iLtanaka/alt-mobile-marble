#!/bin/bash
# build-alt-rootfs.sh: assemble an ALT Mobile base rootfs for marble.
#
# This produces only the distribution part of the root filesystem. The kernel,
# its modules, the Device Tree and the firmware are device specific and are
# copied from the running postmarketOS system at install time (see
# scripts/install-on-phone.sh) - a generic ALT image must never boot its own
# sdm845 kernel on this phone.
#
# Requires: wget, tar (GNU), xz, zstd, make, gcc (or fakeroot/proot when not
# running as root). marble-device-support has to be checked out next to this
# repository.

set -euo pipefail

ALT_ROOTFS_URL="https://beta.altlinux.org/mobile/sisyphus/latest/alt-mobile-phosh-sdm845-latest-aarch64.tar.xz"
BASE_DIR=$(cd "$(dirname "$0")/.." && pwd)
WORKDIR="$BASE_DIR/build-rootfs"
OUTDIR="$BASE_DIR/out"
ROOTFS_TAR="alt-mobile-base.tar.xz"
OVERLAY="../marble-device-support"

echo "[1/5] Fetching the ALT Mobile base rootfs"
cd "$BASE_DIR"
[ -f "$ROOTFS_TAR" ] || wget -c "$ALT_ROOTFS_URL" -O "$ROOTFS_TAR"

echo "[2/5] Unpacking"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR" "$OUTDIR"
tar -xpf "$ROOTFS_TAR" -C "$WORKDIR" --numeric-owner

echo "[3/5] Installing the marble device support layer"
if [ -d "$OVERLAY" ]; then
	# The layer contains one C program (marble-touchboost). Building it with the
	# host compiler would put an x86_64 binary into an aarch64 root filesystem.
	case $(uname -m) in
	aarch64|arm64) MAKE_ARGS="CFLAGS=-O2 -Wall -Wextra LDFLAGS=-static" ;;
	*)             MAKE_ARGS="CC=aarch64-linux-gnu-gcc CFLAGS=-O2\ -Wall\ -Wextra LDFLAGS=-static" ;;
	esac
	# shellcheck disable=SC2086
	make -C "$OVERLAY" DESTDIR="$WORKDIR" PREFIX=/usr $MAKE_ARGS install
else
	echo "error: $OVERLAY not found. Clone marble-device-support next to this" >&2
	echo "       repository; the phone needs its units, udev rules and UCM files." >&2
	exit 1
fi

echo "[4/5] Basic target configuration"
mkdir -p "$WORKDIR/etc/marble"
echo "phoc phosh" > "$WORKDIR/etc/marble/compositors"
echo "xiaomi-marble-alt" > "$WORKDIR/etc/hostname"
# pacman-style sandboxing is irrelevant here, but apt in ALT reads sources.list
# from the phone's network at install time; nothing to preseed.

echo "[5/5] Packing"
tar --xattrs --xattrs-include='*' --acls --numeric-owner -cpf - -C "$WORKDIR" . \
	| zstd -T0 -19 -o "$OUTDIR/alt-mobile-marble-rootfs.tar.zst"

echo
echo "Root filesystem: $OUTDIR/alt-mobile-marble-rootfs.tar.zst"
echo
echo "It contains no kernel, modules or firmware. Copy the tarball to the phone"
echo "(which has to be running postmarketOS) and run, as root:"
echo
echo "    ./scripts/install-on-phone.sh /path/to/alt-mobile-marble-rootfs.tar.zst"
