#!/usr/bin/env bash
set -euo pipefail

echo "== Device status =="
nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true
echo

echo "== Wi-Fi radio =="
nmcli radio all 2>/dev/null || true
echo

echo "== Broadcom modules =="
lsmod | grep -E '^(wl|brcmfmac|brcmfmac_wcc|brcmutil)\b' || true
echo

echo "== Config files =="
for path in \
  /etc/modprobe.d/blacklist-wl.conf \
  /etc/modprobe.d/brcmfmac-feature-disable.conf \
  /etc/modprobe.d/broadcom-wl-dkms.conf \
  /etc/modules-load.d/brcmfmac.conf
do
  if [[ -f "$path" ]]; then
    printf '%s:\n' "$path"
    sed -n '1,20p' "$path"
  elif [[ -L "$path" ]]; then
    printf '%s -> %s\n' "$path" "$(readlink "$path")"
  else
    printf '%s: missing\n' "$path"
  fi
  echo
done

echo "== Firmware file =="
ls -l "/lib/firmware/brcm/brcmfmac43602-pcie.Apple Inc.-MacBookPro11,4.txt" 2>/dev/null || true
echo

echo "== Recent kernel log =="
journalctl -b -k --no-pager 2>/dev/null | \
  grep -E 'brcmfmac|wl driver|Authentication with|ASSOC-REJECT' | \
  tail -n 40 || true
