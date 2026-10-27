#!/bin/sh
# setup-target.sh: post-install configuration inside the ALT Mobile chroot.
# Runs from install-on-phone.sh with /proc, /sys and /dev bind-mounted and
# working DNS. Env: MP_USER, MP_PASS, MP_TOUCHBOOST.
set -eu

USER_NAME=${MP_USER:-alt}
USER_PASS=${MP_PASS:-alt}

echo "[+] SSH server and sudo"
apt-get update -q
apt-get install -y -q openssh-server sudo
control sudo wheelonly || true
mkdir -p /etc/sudoers.d
printf 'Defaults lecture=never\n%%wheel ALL=(ALL:ALL) ALL\n' > /etc/sudoers.d/90-marble
chmod 440 /etc/sudoers.d/90-marble

echo "[+] Login user $USER_NAME"
id "$USER_NAME" >/dev/null 2>&1 || useradd -m -s /bin/bash "$USER_NAME"
for g in wheel audio video input render users dialout plugdev netdev; do
	getent group "$g" >/dev/null && usermod -aG "$g" "$USER_NAME" || true
done
echo "$USER_NAME:$USER_PASS" | chpasswd

echo "[+] Masking units that must not run on marble"
# qbootctl writes the GPT A/B slot bits (forbidden on this phone), droid-juicer
# extracts firmware out of Android partitions and redirects the firmware path,
# goodix-touchscreen belongs to an sdm845 phone, and the kernel ships
# qcom_pd_mapper so the userspace pd-mapper cannot bind the qrtr port.
for u in droid-juicer.service configure-firmware-path.service \
	qbootctl-mark-successful.service goodix-touchscreen.service pd-mapper.service; do
	systemctl mask "$u" >/dev/null 2>&1 || true
done

echo "[+] Enabling the marble units"
for u in marble-panel-on.service marble-compositor-boost.service \
	marble-hardware-tuning.service marble-touchboost.service sshd.service; do
	systemctl enable "$u" >/dev/null 2>&1 || echo "  warning: could not enable $u"
done

echo "[+] Target setup complete."
