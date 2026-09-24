#!/bin/sh
# Installs the latest arranger release:
#   curl -fsSL https://arranger.dev/install.sh | sh
# Installs to ~/.local/bin (no sudo). Set ARRANGER_VERSION=v0.3.0 to pin a version,
# INSTALL_DIR to choose where it goes.
set -eu
repo=arranger-dev/arranger

# colors only on a terminal, and never with NO_COLOR set
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  dim=$(printf '\033[2m') green=$(printf '\033[32m') red=$(printf '\033[31m') bold=$(printf '\033[1m') off=$(printf '\033[0m')
else
  dim='' green='' red='' bold='' off=''
fi
step() { printf ' %s›%s %s\n' "$dim" "$off" "$*"; }
fail() { printf ' %s✗%s %s\n' "$red" "$off" "$*" >&2; exit 1; }

os=$(uname -s | tr '[:upper:]' '[:lower:]')
case $(uname -m) in
  x86_64 | amd64) arch=amd64 ;;
  arm64 | aarch64) arch=arm64 ;;
  *) fail "unsupported CPU: $(uname -m)" ;;
esac
case $os in darwin | linux) ;; *) fail "unsupported OS: $os" ;; esac

if [ -n "${ARRANGER_VERSION:-}" ]; then
  tag=$ARRANGER_VERSION
  step "Using $repo $tag ($os/$arch)..."
else
  step "Detecting latest release for $repo ($os/$arch)..."
  # releases/latest redirects to .../releases/tag/<latest>; no API call, so no rate limit
  latest=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest") ||
    fail "couldn't reach GitHub to find the latest release"
  tag=${latest##*/}
  case $tag in v*) ;; *) fail "no releases found for $repo" ;; esac
fi

file=arranger_${os}_${arch}.tar.gz
url=https://github.com/$repo/releases/download/$tag
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

step "Downloading arranger $tag ($file)..."
curl -fsL "$url/$file" -o "$tmp/$file" || fail "download failed: $url/$file"
curl -fsL "$url/checksums.txt" -o "$tmp/checksums.txt" || fail "download failed: $url/checksums.txt"

step "Verifying checksum..."
(cd "$tmp" && grep " $file\$" checksums.txt | { sha256sum -c - 2>/dev/null || shasum -a 256 -c -; }) >/dev/null 2>&1 ||
  fail "checksum mismatch for $file"
tar xzf "$tmp/$file" -C "$tmp"

dir=${INSTALL_DIR:-$HOME/.local/bin}
step "Installing to $dir/arranger..."
{ mkdir -p "$dir" && [ -w "$dir" ]; } 2>/dev/null || fail "can't write to $dir; choose a folder you own with INSTALL_DIR=..."
mv "$tmp/arranger" "$dir/arranger"
printf ' %s✓%s %sarranger %s installed successfully!%s\n' "$green" "$off" "$bold" "$tag" "$off"

# ~/.local/bin often isn't on PATH yet: say exactly what to add, for the user's shell
case ":$PATH:" in
  *":$dir:"*) ;;
  *)
    case ${SHELL:-} in
      */zsh) rc="~/.zshrc" ;;
      */bash) rc="~/.bashrc" ;;
      *) rc="your shell's startup file" ;;
    esac
    shown=$dir
    case $dir in "$HOME"/*) shown="\$HOME/${dir#"$HOME"/}" ;; esac
    printf '\n %s!%s %s is not on your PATH. Add this line to %s, then open a new terminal:\n\n  export PATH="%s:$PATH"\n' \
      "$red" "$off" "$dir" "$rc" "$shown"
    ;;
esac

cat <<EOF

Run arranger, then open the page it serves:

  arranger                        # start it, then open http://127.0.0.1:7777
  arranger -addr 127.0.0.1:8080   # or pick another port
EOF
