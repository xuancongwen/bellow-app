#!/bin/bash
# Bellow installer for Apple Silicon Macs.
#
#   curl -fsSL https://xuancongwen.github.io/bellow-app/install.sh | bash
#
# Downloads the release DMG (or its split parts, for releases that exceeded GitHub's
# 2 GB asset cap), verifies the SHA-256, copies Bellow.app to /Applications,
# clears the quarantine flag if the build is not notarized (releases before 1.0.0-rc.6),
# and opens the app. The app itself downloads its models on first start. Set
# BELLOW_VERSION=v1.0.0-rc.14 to pin a release; the default is the newest
# release, pre-releases included. Downloads go to ~/Library/Caches/Bellow-installer
# and resume if the script is rerun.
set -euo pipefail

REPO="${BELLOW_REPO:-xuancongwen/bellow-app}"
DEST="${BELLOW_DEST:-/Applications}"
CACHE="${HOME}/Library/Caches/Bellow-installer"

say()  { printf '\033[1m==>\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == Darwin ]] || fail "Bellow runs on macOS only."
[[ "$(uname -m)" == arm64 ]] || fail "Bellow needs an Apple Silicon Mac (M1 or newer)."
# llama.cpp, which runs the cleanup model, needs 13.3.
IFS=. read -r major minor _ <<< "$(sw_vers -productVersion)"
(( major > 13 || (major == 13 && ${minor:-0} >= 3) )) || fail "Bellow needs macOS 13.3 Ventura or newer (you have $(sw_vers -productVersion))."
mem_gb=$(( $(sysctl -n hw.memsize) / 1073741824 ))
(( mem_gb >= 8 )) || fail "Bellow needs at least 8 GB of memory (this Mac has ${mem_gb} GB); the app refuses to load its models below that."
for tool in curl shasum hdiutil ditto xattr; do
  command -v "$tool" >/dev/null || fail "Missing $tool, which ships with macOS."
done

api="https://api.github.com/repos/${REPO}/releases"
if [[ -n "${BELLOW_VERSION:-}" ]]; then
  api="${api}/tags/${BELLOW_VERSION}"
  release_json="$(curl -fsSL "$api" 2>&1)" || fail "No release tagged ${BELLOW_VERSION} at https://github.com/${REPO}/releases (${release_json})"
else
  # /releases/latest skips pre-releases, and the list is ordered by the tagged commit's date, which releases
  # tagged on the same commit share; take the most recently published entry instead.
  list_json="$(curl -fsSL "${api}?per_page=30" 2>&1)" || fail "Could not look up the latest release on GitHub (${list_json}). Try again in a few minutes, or download the DMG from https://github.com/${REPO}/releases"
  newest="$(printf '%s' "$list_json" | grep -o '"\(tag_name\|published_at\)": *"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' | paste - - | sort -k2 -r | head -1 | cut -f1 || true)"
  [[ -n "$newest" ]] || fail "No releases found at https://github.com/${REPO}/releases"
  release_json="$(curl -fsSL "${api}/tags/${newest}" 2>&1)" || fail "Could not look up release ${newest} on GitHub (${release_json}). Try again in a few minutes, or download the DMG from https://github.com/${REPO}/releases"
fi
# `grep` exits 1 on no match; keep set -e from killing the script before the messages below.
tag="$(printf '%s' "$release_json" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || true)"
[[ -n "$tag" ]] || fail "No releases found at https://github.com/${REPO}/releases"
urls="$(printf '%s' "$release_json" | grep -o '"browser_download_url": *"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/' || true)"
sha_url="$(printf '%s\n' "$urls" | grep '\.dmg\.sha256$' | head -1 || true)"
[[ -n "$sha_url" ]] || fail "Release ${tag} has no .sha256 asset; is the build still running? https://github.com/${REPO}/releases/tag/${tag}"
dmg="$(basename "${sha_url%.sha256}")"
part_urls="$(printf '%s\n' "$urls" | grep "^.*/${dmg}\.part-" | sort || true)"
whole_url="$(printf '%s\n' "$urls" | grep "/${dmg}$" | head -1 || true)"
[[ -n "$part_urls" || -n "$whole_url" ]] || fail "Release ${tag} has no DMG assets."

mkdir -p "$CACHE"
cd "$CACHE"
say "Installing Bellow ${tag}"
curl -fsSL "$sha_url" -o "${dmg}.sha256"

if [[ -f "$dmg" ]] && shasum -a 256 -c "${dmg}.sha256" >/dev/null 2>&1; then
  say "Using the already-downloaded ${dmg}"
else
  rm -f "$dmg"
  if [[ -n "$whole_url" ]]; then
    say "Downloading ${dmg}"
    curl -fL --retry 3 -C - --progress-bar "$whole_url" -o "$dmg.partial"
    mv "$dmg.partial" "$dmg"
  else
    n=0
    for url in $part_urls; do
      n=$((n + 1)); part="$(basename "$url")"
      say "Downloading part ${n} ($(printf '%s\n' "$part_urls" | wc -l | tr -d ' ') total): ${part}"
      curl -fL --retry 3 -C - --progress-bar "$url" -o "$part"
    done
    say "Reassembling ${dmg}"
    cat "${dmg}".part-* > "$dmg"
  fi
  say "Verifying checksum"
  shasum -a 256 -c "${dmg}.sha256" || { rm -f "$dmg" "${dmg}".part-*; fail "Checksum mismatch; the download was corrupt. Run the installer again."; }
  rm -f "${dmg}".part-*
fi

say "Copying Bellow to ${DEST}"
mount="$(mktemp -d /tmp/bellow-dmg.XXXXXX)"
hdiutil attach "$dmg" -mountpoint "$mount" -nobrowse -quiet
trap 'hdiutil detach "$mount" -quiet 2>/dev/null || true' EXIT
app="$(find "$mount" -maxdepth 1 -name '*.app' | head -1)"
[[ -n "$app" ]] || fail "No .app found inside ${dmg}."
if pgrep -xq Bellow; then
  say "Quitting the running Bellow"
  osascript -e 'tell application "Bellow" to quit' >/dev/null 2>&1 || true
  sleep 2
fi
rm -rf "${DEST}/Bellow.app"
ditto "$app" "${DEST}/Bellow.app"
hdiutil detach "$mount" -quiet
trap - EXIT
# A notarized build passes Gatekeeper as is. An ad-hoc signed release candidate would be
# blocked until allowed in System Settings > Privacy & Security, so clear its quarantine flag.
if spctl --assess --type execute "${DEST}/Bellow.app" >/dev/null 2>&1; then
  say "Notarized by Apple; Gatekeeper accepts it"
else
  say "Development build (not notarized); clearing the quarantine flag"
  xattr -dr com.apple.quarantine "${DEST}/Bellow.app" 2>/dev/null || true
fi
rm -f "$dmg" "${dmg}.sha256"

say "Installed ${DEST}/Bellow.app (${tag})"
echo
echo "Opening Bellow. Grant Microphone and Accessibility in the setup window and click Start."
echo "The first start downloads the speech and cleanup models (2 to 3.4 GB, once)."
echo "When the status reads \"Ready\", press Control+Option+X to dictate."
open "${DEST}/Bellow.app"
