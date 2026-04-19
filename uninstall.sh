#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="/var/lib/mbp11-4-bcm43602-wifi-fix"

TARGET_NVRAM="/lib/firmware/brcm/brcmfmac43602-pcie.Apple Inc.-MacBookPro11,4.txt"
WL_BLACKLIST_DST="/etc/modprobe.d/blacklist-wl.conf"
FEATURE_DST="/etc/modprobe.d/brcmfmac-feature-disable.conf"
MODULES_LOAD_DST="/etc/modules-load.d/brcmfmac.conf"

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "Run as root: sudo ./uninstall.sh" >&2
    exit 1
  fi
}

backup_path_for() {
  local target="$1"
  printf '%s%s' "$STATE_DIR" "$target"
}

restore_or_remove() {
  local target="$1"
  local backup

  backup="$(backup_path_for "$target")"
  if [[ -e "$backup" ]]; then
    mkdir -p "$(dirname "$target")"
    cp -a "$backup" "$target"
    echo "Restored $target from backup."
  else
    rm -f "$target"
    echo "Removed $target."
  fi
}

reload_modules() {
  modprobe -r brcmfmac_wcc brcmfmac brcmutil 2>/dev/null || true
  modprobe -r wl 2>/dev/null || true
  modprobe brcmfmac 2>/dev/null || true
}

main() {
  require_root

  restore_or_remove "$WL_BLACKLIST_DST"
  restore_or_remove "$FEATURE_DST"
  restore_or_remove "$MODULES_LOAD_DST"
  restore_or_remove "$TARGET_NVRAM"
  reload_modules

  cat <<'EOF'
Uninstall complete.

If Wi-Fi does not recover to the previous state immediately, reboot once.
Backups were left under /var/lib/mbp11-4-bcm43602-wifi-fix/.
EOF
}

main "$@"
