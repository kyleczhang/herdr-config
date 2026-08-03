#!/usr/bin/env bash
#
# Local installer for this Herdr config.
#
# Installs config.toml from this repo (the file sitting next to this script)
# into Herdr's config directory, backing up any existing config first, then
# hot-reloads a running Herdr server. Use this instead of install.sh when you
# have the repo checked out locally and want to install your working copy.
#
#   ./install-local.sh
#
set -euo pipefail

# Directory this script lives in, so it works from any cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SRC_CONFIG="$SCRIPT_DIR/config.toml"

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

bold "Herdr config installer (local)"
info "Source: $SCRIPT_DIR"
info "Target: $CONFIG_FILE"

# --- prerequisites: source file must exist --------------------------------
if [ ! -f "$SRC_CONFIG" ]; then
  err "Missing source file: $SRC_CONFIG"
  exit 1
fi

# --- validate the source config before touching the live one --------------
if command -v herdr >/dev/null 2>&1; then
  info "Validating config ..."
  if ! HERDR_CONFIG_PATH="$SRC_CONFIG" herdr config check; then
    err "Source config failed validation; leaving your current config untouched."
    exit 1
  fi
fi

# --- create config dir ----------------------------------------------------
mkdir -p "$CONFIG_DIR"

# --- back up an existing config -------------------------------------------
if [ -f "$CONFIG_FILE" ]; then
  BACKUP="$CONFIG_FILE.backup.$(date +%Y%m%d%H%M%S)"
  cp "$CONFIG_FILE" "$BACKUP"
  info "Backed up existing config to $BACKUP"
fi

# --- install file ---------------------------------------------------------
cp "$SRC_CONFIG" "$CONFIG_FILE"
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
