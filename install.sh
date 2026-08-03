#!/usr/bin/env bash
#
# One-line installer for this Herdr config.
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/kyleczhang/herdr-config/main/install.sh)"
#
# It downloads config.toml into Herdr's config directory, backing up any
# existing config first, then hot-reloads a running Herdr server.

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/kyleczhang/herdr-config/main"
SRC_NAME="config.toml"

# Herdr reads its config from $XDG_CONFIG_HOME/herdr/config.toml
# (defaults to ~/.config/herdr/config.toml); HERDR_CONFIG_PATH overrides it.
if [ -n "${HERDR_CONFIG_PATH:-}" ]; then
  CONFIG_FILE="$HERDR_CONFIG_PATH"
else
  CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/herdr/config.toml"
fi
CONFIG_DIR="$(dirname "$CONFIG_FILE")"

# --- pretty output --------------------------------------------------------
bold() { printf '\033[1m%s\033[0m\n' "$1"; }
info() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m==>\033[0m %s\n' "$1"; }
err()  { printf '\033[1;31mError:\033[0m %s\n' "$1" >&2; }

# --- prerequisites --------------------------------------------------------
if ! command -v curl >/dev/null 2>&1; then
  err "curl is required but not found."
  exit 1
fi

bold "Herdr config installer"
info "Target: $CONFIG_FILE"

# --- create config dir ----------------------------------------------------
mkdir -p "$CONFIG_DIR"

# --- download into a temp file, then move into place ----------------------
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

info "Downloading $SRC_NAME ..."
if ! curl -fsSL "$REPO_RAW/$SRC_NAME" -o "$TMP_FILE"; then
  err "Download failed from $REPO_RAW/$SRC_NAME"
  exit 1
fi

# Sanity check: file is non-empty.
if [ ! -s "$TMP_FILE" ]; then
  err "Downloaded file is empty."
  exit 1
fi

# Validate the downloaded config before touching the live one.
if command -v herdr >/dev/null 2>&1; then
  info "Validating config ..."
  if ! HERDR_CONFIG_PATH="$TMP_FILE" herdr config check; then
    err "Downloaded config failed validation; leaving your current config untouched."
    exit 1
  fi
fi

# --- back up an existing config -------------------------------------------
if [ -f "$CONFIG_FILE" ]; then
  BACKUP="$CONFIG_FILE.backup.$(date +%Y%m%d%H%M%S)"
  cp "$CONFIG_FILE" "$BACKUP"
  info "Backed up existing config to $BACKUP"
fi

mv "$TMP_FILE" "$CONFIG_FILE"
trap - EXIT

ok "Installed config to $CONFIG_FILE"

# --- reload a running server ----------------------------------------------
if command -v herdr >/dev/null 2>&1; then
  if herdr server reload-config >/dev/null 2>&1; then
    ok "Reloaded the running Herdr server."
  fi
fi

# --- next steps -----------------------------------------------------------
echo
bold "Done!"
echo "  • Not running yet? Just start Herdr with: herdr"
echo "  • Already running? It was reloaded, or press prefix + Shift+R to reload manually."
