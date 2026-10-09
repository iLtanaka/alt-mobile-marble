#!/bin/sh
# setup-target.sh: post-install configuration inside ALT Mobile chroot
set -eu

echo "[+] Configuring sudo and user groups..."
apt-get update -q
apt-get install -y -q openssh-server sudo

control sudo wheelonly || true
mkdir -p /etc/sudoers.d
printf 'Defaults lecture=never\n%%wheel ALL=(ALL:ALL) ALL\n' > /etc/sudoers.d/90-marble
chmod 440 /etc/sudoers.d/90-marble

echo "[+] Masking unneeded service units..."
# Units specific to other platforms or dangerous for slot attributes
MASK_UNITS="droid-juicer.service configure-firmware-path.service qbootctl-mark-successful.service goodix-touchscreen.service pd-mapper.service"
for u in $MASK_UNITS; do
	systemctl mask "$u" 2>/dev/null || true
done

echo "[+] Enabling marble hardware services..."
systemctl enable marble-panel-on.service \
	marble-compositor-boost.service \
	marble-hardware-tuning.service \
	marble-touchboost.service \
	sshd.service 2>/dev/null || true

echo "[+] Target setup complete."
