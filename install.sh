#!/usr/bin/env bash
# Installs the latest Stampede release (macOS, Apple Silicon).
#
# The program is a folder (it starts in under a second; a single-file build takes about 8),
# kept in ~/.local/share/stampede, with a link to it in ~/.local/bin.
set -euo pipefail

REPO="josejmorales/stampede-releases"

if [ "$(uname -s)-$(uname -m)" != "Darwin-arm64" ]; then
  echo "This installer supports macOS on Apple Silicon only (found $(uname -s) $(uname -m))." >&2
  exit 1
fi

asset="stampede-macos-arm64.tar.gz"
dir="${STAMPEDE_INSTALL_DIR:-$HOME/.local/bin}"          # where the `stampede` command goes
app="${STAMPEDE_APP_DIR:-$HOME/.local/share/stampede}"   # where the program's files go
base="${STAMPEDE_RELEASE_BASE:-https://github.com/$REPO/releases/latest/download}"   # override for testing
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Downloading stampede..."
curl -fsSL "$base/$asset" -o "$tmp/$asset"
curl -fsSL "$base/SHA256SUMS" -o "$tmp/SHA256SUMS"

expected="$(awk -v a="$asset" '$2 == a { print $1 }' "$tmp/SHA256SUMS")"
actual="$(shasum -a 256 "$tmp/$asset" | awk '{ print $1 }')"
if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
  echo "Checksum mismatch, not installing." >&2
  exit 1
fi

mkdir -p "$tmp/unpacked"
tar -xzf "$tmp/$asset" -C "$tmp/unpacked"
if [ ! -x "$tmp/unpacked/stampede/stampede" ]; then
  echo "The download doesn't contain the program, not installing." >&2
  exit 1
fi

mkdir -p "$(dirname "$app")" "$dir"
rm -rf "$app.new"
mv "$tmp/unpacked/stampede" "$app.new"
rm -rf "$app"
mv "$app.new" "$app"
rm -f "$dir/stampede"      # an older install left a single file here; the link replaces it
ln -s "$app/stampede" "$dir/stampede"
echo "Installed stampede to $app (linked from $dir/stampede)"

# macOS doesn't put ~/.local/bin on the PATH, so add it to the shell's startup file.
case ":$PATH:" in
  *":$dir:"*) ;;
  *)
    case "$(basename "${SHELL:-/bin/zsh}")" in
      zsh)  rc="$HOME/.zshrc" ;;
      bash) rc="$HOME/.bash_profile" ;;
      *)    rc="" ;;
    esac
    line="export PATH=\"$dir:\$PATH\"  # added by the stampede installer"
    if [ -z "$rc" ]; then
      echo
      echo "Add $dir to your PATH to run 'stampede' from anywhere:"
      echo "  export PATH=\"$dir:\$PATH\""
    else
      if grep -qF "added by the stampede installer" "$rc" 2>/dev/null; then
        echo "$dir is already set up in $rc."
      else
        printf '\n%s\n' "$line" >> "$rc"
        echo "Added $dir to your PATH in $rc."
      fi
      echo "Open a NEW Terminal window (or run: source $rc) before using it."
    fi
    ;;
esac

echo
echo "Then type: stampede"
