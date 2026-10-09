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

## Installation Guide

### Prerequisites
* Xiaomi Poco F5 with unlocked bootloader.
* U-Boot installed to `boot_b` (see [u-boot-marble](https://github.com/iLtanaka/u-boot-marble)).
* Mainline kernel and DTB (see [linux-marble](https://github.com/iLtanaka/linux-marble)).

### 1. Preparing the rootfs
Run the assembly script:
```bash
./scripts/build-alt-rootfs.sh
```

### 2. Deploying to device partition
From a host with fastboot or an existing mobile Linux environment:
```bash
# Format the target rootfs partition as btrfs
mkfs.btrfs -f -L ALT_ROOT /dev/disk/by-partlabel/rootfs2

# Mount and unpack
mount /dev/disk/by-partlabel/rootfs2 /mnt
tar -xpf out/alt-mobile-marble-rootfs.tar.zst -C /mnt --numeric-owner
umount /mnt
```

### 3. Adding the extlinux boot entry
Copy `boot/alt.conf` to the ESP partition under `/extlinux/alt.conf`, along with `vmlinuz` and `sm8475-xiaomi-marble.dtb` in `/alt/`.

Select **ALT Mobile Sisyphus** in the U-Boot boot menu.

---

## Related Repositories

* [linux-marble](https://github.com/iLtanaka/linux-marble) — Mainline Linux kernel tree for Poco F5.
* [u-boot-marble](https://github.com/iLtanaka/u-boot-marble) — U-Boot port for Poco F5.
* [marble-device-support](https://github.com/iLtanaka/marble-device-support) — Hardware enablement layer (UCM, udev, daemons).

---

## License

GPL-2.0-or-later / MIT.
