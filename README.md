# ALT Mobile for Xiaomi Poco F5 / Redmi Note 12 Turbo (marble)

Port of **ALT Mobile Sisyphus (Phosh / glibc / systemd)** for the **Xiaomi Poco F5 / Redmi Note 12 Turbo** (`xiaomi-marble`, Qualcomm Snapdragon 7+ Gen 2 / SM7475).

Based on mainline Linux kernel 7.2.8 (`linux-marble`), U-Boot chainloaded via ABL, and the `marble-device-support` hardware layer.

---

## Hardware Status

All core hardware components are tested and functional:

| Subsystem | Status | Details |
|---|---|---|
| **Display** | Working | 1080x2400 AMOLED @ 120 Hz, MIPI DSI command mode |
| **Touchscreen** | Working | Goodix GT9916 @ 120 Hz with `marble-touchboost` |
| **GPU & Compositor** | Working | Adreno 725 (Freedreno), Phoc/Phosh with `uclamp.min` (512) |
| **Audio** | Working | Stereo AW88263S speakers, WCD9385 microphones |
| **Cellular Modem** | Working | LTE data, SMS, signal reporting via IPA v5.1 |
| **GNSS / GPS** | Working | Qualcomm LOC engine active via patched ModemManager |
| **Sensors** | Working | Qualcomm SSC/SLPI: accelerometer, proximity, light, compass |
| **Wi-Fi** | Working | QCA6490 (2.4 GHz & 5 GHz) |
| **Bluetooth** | Working | WCN6855 HCI |
| **Battery & Charging** | Working | Capacity reporting, deep suspend, fast charging |

### Hardware Test Suite Verification

Verified live on hardware (0 failed):

```text
PASS os           ALT Mobile Sisyphus 2026.09 (phoenix) (altlinux), kernel 7.2.8
PASS dsp          slpi running
PASS dsp          adsp running
PASS dsp          modem running
PASS units        no failed units
PASS panel        DSI-1 connected, backlight 160
PASS compositor   phoc uclamp min: 512
PASS touch        Goodix Berlin present
PASS haptics      spmi_haptics input device
PASS wifi         wlp1s0 Cudy5G 5180 MHz
PASS wifi5        3 networks seen on 5 GHz
PASS bt           hci0 present, powered=yes
PASS modem        state=registered operator=MTS RUS signal=88%
PASS gps          GNSS engine started
PASS sensor       accelerometer
PASS sensor       proximity
PASS sensor       light
PASS sensor       compass
PASS audio        sound card registered
PASS battery      Charging, current 484 mA
PASS suspend      deep sleep selected
PASS firmware     no missing firmware
SUMMARY: 0 failed
```

---

## Boot Architecture

1. **Firmware / ABL**: Loads U-Boot from `boot_b`.
2. **U-Boot**: Interactive bootloader with countdown menu, USB serial console, and extlinux support.
3. **Storage Layout**:
   * ESP partition (`/dev/sda34`): Holds kernel `/alt/vmlinuz`, DTB `/alt/sm8475-xiaomi-marble.dtb`, and extlinux config `/extlinux/alt.conf`.
   * Rootfs partition (`/dev/sda36`, label `rootfs2`): Btrfs or ext4 filesystem holding the ALT Mobile rootfs.

---

## Installation

The phone boots ALT from the spare GPT partition using postmarketOS's kernel.
Kernel, modules, Device Tree and firmware are device specific and always come
from the postmarketOS installation on the same phone; only the root filesystem
is ALT. Installation therefore happens **on the phone, while it runs
postmarketOS**.

### Prerequisites
* Xiaomi Poco F5 with unlocked bootloader.
* U-Boot flashed to `boot_b` ([u-boot-marble](https://github.com/iLtanaka/u-boot-marble)). Without it the boot chain cannot start a second system.
* A spare partition for the ALT root filesystem. The tested device uses the GPT partition labelled `rootfs2` (16 GiB). It is erased by the installation.
* postmarketOS running, `root` access, network access, and about 2 GB of free space for the archive.
* The ALT root filesystem archive: either build it with `scripts/build-alt-rootfs.sh` or take one from the releases.

### 1. Building the root filesystem (on a PC)

`marble-device-support` has to be checked out next to this repository; the
script installs it into the image:

```bash
git clone https://github.com/iLtanaka/marble-device-support.git
./scripts/build-alt-rootfs.sh
```

The result is `out/alt-mobile-marble-rootfs.tar.zst`. Copy it to the phone.

### 2. Installing (on the phone, in postmarketOS)

```bash
sudo ./scripts/install-on-phone.sh /path/to/alt-mobile-marble-rootfs.tar.zst
```

The script:
* copies `vmlinuz` and `sm8475-xiaomi-marble.dtb` from `/boot` into `/alt/` on the esp and writes `/boot/extlinux/alt.conf`;
* regenerates `/boot/extlinux/others.env`, the file U-Boot reads for its "Other systems..." menu;
* formats the target partition as btrfs, unpacks the archive and writes `/etc/fstab`;
* copies `/lib/modules/$(uname -r)`, all firmware into `/usr/lib/firmware/updates/` and the sensor registry into `/usr/share/qcom`;
* runs the target setup in a chroot: SSH server, sudo, login user, masked units, enabled marble units.

`MP_USER` and `MP_PASS` override the login user (default `alt`/`alt`), and
`TOUCHBOOST=/path/to/static/marble-touchboost` installs a static build of the
touch daemon (postmarketOS ships a musl binary that ALT cannot run).

### 3. Booting

Reboot and hold **Volume Down** while U-Boot starts, then:

```text
Other systems... -> ALT Mobile Sisyphus
```

Without a key press U-Boot boots postmarketOS after 5 seconds, so the phone is
never stuck in the other system. The screen stays dark for a second or two
while `marble-panel-on.service` cycles the framebuffer; this is expected on a
direct boot without an initramfs.

### 4. Optional: the debug USB network

If Wi-Fi is not configured, the phone is reachable over USB at `172.16.42.1`
once the gadget is started:

```bash
sudo systemctl start marble-usb-net
```

Keep it stopped while charging over USB: a bound gadget makes the charger look
like a standard downstream port and caps charging at 5 V / 1 A.

## Troubleshooting

**The "Other systems..." entry says `no /extlinux/others.env on the esp`.**
U-Boot shows that message when the file is absent; the menu is generated from
`/boot/extlinux/*.conf` and nothing creates it on a normal installation. Re-run
`scripts/install-on-phone.sh`, or write it by hand:

```bash
cat > /boot/extlinux/others.env <<'EOF'
bootmenu_0=ALT Mobile Sisyphus=part number scsi 0 esp p; sysboot scsi 0:${p} any ${pxefile_addr_r} /extlinux/alt.conf; pause
bootmenu_1=Back=reset
EOF
```

**Black screen after selecting ALT.**
1. The entry must boot `/alt/vmlinuz` (the copy from postmarketOS), never the `vmlinuz-*-qualcomm-sdm845-*` that ships inside ALT's own image. That kernel has no marble support and cannot work on this phone regardless of the modules.
2. The modules in the ALT root filesystem must match that kernel version exactly; `uname -r` in the running system and `ls /usr/lib/modules` have to agree.
3. Check the panel cycle ran: `systemctl status marble-panel-on`. If the binary is missing the unit fails with status 203/EXEC, and the panel stays dark.
4. Pressing power on a dark screen must not power the phone off; `50-marble-powerkey.conf` sets `HandlePowerKey=ignore`.

**Input lag.** The compositor needs a CPU floor of `uclamp.min 512` (`marble-compositor-boost.service`) and `marble-touchboost`. A musl build of the daemon does not run on ALT; use the static one.

**No 5 GHz Wi-Fi.** ath11k prefers a generic `board-2.bin` over our `board.bin`, and that generic file has no marble board id. The installation script renames the WCN6855 `hw2.1/board-2.bin`, but a `linux-firmware` update restores it.

**No sensors.** They are behind the SLPI: ALT needs `libssc` and an `iio-sensor-proxy` built with SSC support. Stock ALT ships neither, so `iio-sensor-proxy` never starts. GPS additionally needs the patched `libqmi` and `ModemManager`.

---

## Related Repositories

* [linux-marble](https://github.com/iLtanaka/linux-marble) — Mainline Linux kernel tree for Poco F5.
* [u-boot-marble](https://github.com/iLtanaka/u-boot-marble) — U-Boot port for Poco F5.
* [marble-device-support](https://github.com/iLtanaka/marble-device-support) — Hardware enablement layer (UCM, udev, daemons).

---

## License

GPL-2.0-or-later / MIT.
