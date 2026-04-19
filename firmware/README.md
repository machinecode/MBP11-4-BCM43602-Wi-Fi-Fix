This directory is intentionally empty in the public package.

If you have redistribution rights for a known-good calibration file, place it
here before running `install.sh`:

`firmware/brcm/brcmfmac43602-pcie.Apple Inc.-MacBookPro11,4.txt`

Why it is not bundled:

- the scripts and docs in this repository are MIT licensed
- the Apple/Broadcom NVRAM calibration file is third-party material with
  unclear licensing

By default, `install.sh` will try to download a community mirror when the file
is not provided locally.
