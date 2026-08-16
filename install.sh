#!/usr/bin/env bash
#
# Install this Herdr config from GitHub: validate, copy it into place, and
# hot-reload a running server.
#
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/kyleczhang/herdr-config/main/install.sh)"
#
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/kyleczhang/herdr-config/main"
dest="${HERDR_CONFIG_PATH:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr/config.toml}"

die() { echo "herdr-config: $*" >&2; exit 1; }

command -v curl >/dev/null 2>&1 || die "curl is required"

src="$(mktemp)"
trap 'rm -f "$src"' EXIT

curl -fsSL "$REPO_RAW/config.toml" -o "$src" || die "download failed: $REPO_RAW/config.toml"
[ -s "$src" ] || die "downloaded config is empty"

# Validate against the live binary before touching the real config.
# Skipped when herdr isn't installed.
if command -v herdr >/dev/null 2>&1; then
  if ! out="$(HERDR_CONFIG_PATH="$src" herdr config check 2>&1)"; then
    printf '%s\n' "$out" >&2
    die "config failed validation"
  fi
fi

mkdir -p "$(dirname "$dest")"

cp "$src" "$dest"
echo "installed -> $dest"

if command -v herdr >/dev/null 2>&1 && herdr server reload-config >/dev/null 2>&1; then
  echo "reloaded running herdr server"
fi
