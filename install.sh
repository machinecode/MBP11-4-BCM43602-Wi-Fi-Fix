#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="/var/lib/mbp11-4-bcm43602-wifi-fix"

YES_DOWNLOAD=0
SKIP_DOWNLOAD=0

MODEL_FILE="brcmfmac43602-pcie.Apple Inc.-MacBookPro11,4.txt"
LOCAL_NVRAM="$SCRIPT_DIR/firmware/brcm/$MODEL_FILE"
TARGET_NVRAM="/lib/firmware/brcm/$MODEL_FILE"

WL_BLACKLIST_SRC="$SCRIPT_DIR/modprobe.d/blacklist-wl.conf"
WL_BLACKLIST_DST="/etc/modprobe.d/blacklist-wl.conf"

FEATURE_SRC="$SCRIPT_DIR/modprobe.d/brcmfmac-feature-disable.conf"
FEATURE_DST="/etc/modprobe.d/brcmfmac-feature-disable.conf"

NVRAM_URL="${NVRAM_URL:-https://gist.githubusercontent.com/cristianmiranda/ba9d64b4324f0803d9422d765de62252/raw/fa8c3db4ece70e21b9619d918a5e5bfb6a28d72b/brcmfmac43602-pcie.txt}"

usage() {
  cat <<'EOF'
Usage:
  sudo ./install.sh [--yes-download] [--skip-download] [--help]

Options:
  --yes-download  Skip the interactive confirmation before downloading the
                  third-party NVRAM file.
  --skip-download Never download the NVRAM file. Use only a local repo copy or
                  an already-installed system copy.
  --help          Show this help text.
EOF
}

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "Run as root: sudo ./install.sh" >&2
    exit 1
  fi
}

backup_path_for() {
  local target="$1"
  printf '%s%s' "$STATE_DIR" "$target"
}

backup_if_needed() {
  local target="$1"
  local backup

  backup="$(backup_path_for "$target")"
  if [[ -e "$target" && ! -e "$backup" ]]; then
    mkdir -p "$(dirname "$backup")"
    cp -a "$target" "$backup"
  fi
}

install_config() {
  local src="$1"
  local dst="$2"

  backup_if_needed "$dst"
  install -Dm0644 "$src" "$dst"
}

confirm_download() {
  local reply

  if [[ "$YES_DOWNLOAD" -eq 1 ]]; then
    return 0
  fi

  cat <<EOF
No local NVRAM calibration file was found in:
  $LOCAL_NVRAM

The installer can download a third-party community mirror and install it to:
  $TARGET_NVRAM

Warning:
  - this file is not covered by this repository's MIT license
  - it comes from a community mirror
  - you should review and redistribute it separately if you plan to publish
    this repository
EOF

  if [[ ! -t 0 ]]; then
    echo "Refusing to download without confirmation in a non-interactive shell." >&2
    echo "Use --yes-download to allow the download, or place the file locally." >&2
    return 1
  fi

  read -r -p "Download the NVRAM file now? [y/N] " reply
  case "$reply" in
    y|Y|yes|YES)
      return 0
      ;;
    *)
      echo "Download cancelled. Provide a local NVRAM file and rerun the installer." >&2
      return 1
      ;;
  esac
}

download_nvram() {
  local tmp_file
  tmp_file="$(mktemp)"
  trap 'rm -f "$tmp_file"' RETURN

  confirm_download

  echo "Downloading community NVRAM file..."
  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --show-error --silent "$NVRAM_URL" -o "$tmp_file"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$tmp_file" "$NVRAM_URL"
  else
    echo "Neither curl nor wget is available." >&2
    return 1
  fi

  if ! grep -q '^boardrev=' "$tmp_file"; then
    echo "Downloaded file does not look like a Broadcom NVRAM file." >&2
    return 1
  fi

  backup_if_needed "$TARGET_NVRAM"
  install -Dm0644 "$tmp_file" "$TARGET_NVRAM"
}

install_nvram() {
  if [[ -f "$LOCAL_NVRAM" ]]; then
    echo "Installing local NVRAM file from repository."
    backup_if_needed "$TARGET_NVRAM"
    install -Dm0644 "$LOCAL_NVRAM" "$TARGET_NVRAM"
    return
  fi

  if [[ -f "$TARGET_NVRAM" ]]; then
    echo "Keeping existing NVRAM file at $TARGET_NVRAM"
    return
  fi

  if [[ "$SKIP_DOWNLOAD" -eq 1 ]]; then
    echo "Skipping download as requested and no NVRAM file is available." >&2
    echo "Place the file at $LOCAL_NVRAM and rerun the installer." >&2
    return 1
  fi

  download_nvram
}

reload_modules() {
  modprobe -r brcmfmac_wcc brcmfmac brcmutil 2>/dev/null || true
  modprobe -r wl 2>/dev/null || true
  modprobe brcmfmac feature_disable=0x82000 || true
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes-download)
        YES_DOWNLOAD=1
        ;;
      --skip-download)
        SKIP_DOWNLOAD=1
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done
}

main() {
  parse_args "$@"
  require_root
  mkdir -p "$STATE_DIR"

  install_config "$WL_BLACKLIST_SRC" "$WL_BLACKLIST_DST"
  install_config "$FEATURE_SRC" "$FEATURE_DST"
  install_nvram
  reload_modules

  cat <<'EOF'
Install complete.

Applied:
  - /etc/modprobe.d/blacklist-wl.conf
  - /etc/modprobe.d/brcmfmac-feature-disable.conf
  - /lib/firmware/brcm/brcmfmac43602-pcie.Apple Inc.-MacBookPro11,4.txt

Next steps:
  - Run ./check-status.sh
  - Reboot once if wlan0 does not appear immediately
EOF
}

main "$@"
