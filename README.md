# MBP11,4 BCM43602 Wi-Fi Fix

Reusable Wi-Fi fix bundle for Apple `MacBookPro11,4` systems using the Broadcom
`BCM43602` (`14e4:43ba`) chipset on Linux.

This package is based on a working fix applied on `2026-04-19` on CachyOS. It
addresses two separate issues:

- `wl` grabbing the device and failing to create a working Wi-Fi interface
- `brcmfmac` timing out during WPA authentication with `wpa_supplicant 2.11`

## What This Installs

- `blacklist wl` in `/etc/modprobe.d/blacklist-wl.conf`
- `options brcmfmac feature_disable=0x82000` in
  `/etc/modprobe.d/brcmfmac-feature-disable.conf`
- `brcmfmac` in `/etc/modules-load.d/brcmfmac.conf` so the driver loads on boot
- An Apple/Broadcom NVRAM calibration file at
  `/lib/firmware/brcm/brcmfmac43602-pcie.Apple Inc.-MacBookPro11,4.txt`

## License Scope

This repository is MIT licensed for the scripts and documentation included
here.

The Apple/Broadcom calibration file is intentionally **not** bundled in this
repository because its licensing status is unclear. The installer can:

- use a local file you place under `firmware/brcm/`, or
- download a community mirror during installation

If you plan to publish this on GitHub, keeping the calibration file out of the
repo is the safer default.

## Quick Start

```bash
cd mbp11-4-bcm43602-wifi-fix
sudo ./install.sh
./check-status.sh
```

If `wlan0` does not appear immediately, reboot once.

If the local NVRAM file is missing, the installer now warns before downloading a
third-party copy. For unattended installs:

```bash
sudo ./install.sh --yes-download
```

To forbid downloads entirely:

```bash
sudo ./install.sh --skip-download
```

## Files

- `install.sh`: installs the modprobe config and NVRAM file, then reloads
  Broadcom modules
- `uninstall.sh`: restores backups when available or removes files created by
  the installer
- `check-status.sh`: prints quick diagnostics
- `modprobe.d/`: the two config files used by the fix
- `modules-load.d/`: boot-time module loading for `brcmfmac`
- `firmware/README.md`: how to provide your own local NVRAM file

## Local NVRAM Override

If you already have a known-good NVRAM file, place it here before running the
installer:

```text
firmware/brcm/brcmfmac43602-pcie.Apple Inc.-MacBookPro11,4.txt
```

The installer will prefer that local file over downloading anything.

## Notes

- This package does not include NetworkManager connection profiles or passwords.
- The installer stores backups under `/var/lib/mbp11-4-bcm43602-wifi-fix/`.
- The fix is targeted at `MacBookPro11,4` and the exact `BCM43602` device used
  in that machine. Other models may need a different NVRAM file.
