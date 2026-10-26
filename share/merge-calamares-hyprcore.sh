#!/usr/bin/env bash
# Merge hyprCore Calamares YAML + branding into a live-build includes.chroot tree.
# Usage: merge-calamares-hyprcore.sh <includes.chroot> <images-dir> [personalize-images-dir]

set -euo pipefail
TARGET="${1:?target includes dir}"
IMAGES="${2:?Images directory (default/images/)}"
IMAGES_PERSONALIZE="${3:-}"
_here="$(cd "$(dirname "$0")" && pwd)"
ROOT="$_here/calamares-hyprcore"
# shellcheck source=hyprcore-personalize.sh
source "$_here/hyprcore-personalize.sh"

mkdir -p "$TARGET/etc/calamares"
cp -a "$ROOT/etc/calamares/." "$TARGET/etc/calamares/"

if [[ -d "$ROOT/usr" ]]; then
  mkdir -p "$TARGET/usr/share/applications" "$TARGET/usr/share/pixmaps"
  cp -a "$ROOT/usr/." "$TARGET/usr/"
fi

for _sbin in \
  "$TARGET/usr/local/sbin/hyprcore-nm-user-perms.sh" \
  "$TARGET/usr/local/sbin/hyprcore-add-user-input-group.sh" \
  "$TARGET/usr/local/sbin/hyprcore-strip-desktop.sh" \
  "$TARGET/usr/local/sbin/hyprcore-apply-server-packages.sh" \
  "$TARGET/usr/local/sbin/hyprcore-apply-desktop-profile.sh" \
  "$TARGET/usr/local/sbin/hyprcore-install-hyprland-backports.sh" \
  "$TARGET/usr/local/sbin/hyprcore-apply-server-profile.sh"; do
  if [[ -f "$_sbin" ]]; then
    chmod 0755 "$_sbin"
  fi
done

br="$TARGET/etc/calamares/branding/hyprcore"
mkdir -p "$br"

pick_welcome_image() {
  # Prefer a Welcome-specific hero (no “installation in progress” copy).
  hyprcore_resolve_image "$IMAGES" "$IMAGES_PERSONALIZE" "calamares/welcome-hero" png jpg jpeg webp \
    || hyprcore_resolve_image "$IMAGES" "$IMAGES_PERSONALIZE" "calamares/image" png jpg jpeg webp \
    || hyprcore_resolve_image "$IMAGES" "$IMAGES_PERSONALIZE" "live/background" png jpg jpeg webp \
    || hyprcore_resolve_image "$IMAGES" "$IMAGES_PERSONALIZE" "icons/menu-icon" png jpg jpeg webp \
    || true
}

pick_slideshow_image() {
  # Install-step slideshow may keep the progress-themed artwork.
  hyprcore_resolve_image "$IMAGES" "$IMAGES_PERSONALIZE" "calamares/image" png jpg jpeg webp \
    || hyprcore_resolve_image "$IMAGES" "$IMAGES_PERSONALIZE" "calamares/welcome-hero" png jpg jpeg webp \
    || true
}

pick_sidebar_logo() {
  # Icon above Welcome / Install type / … — never fall back to calamares/image
  # (that large welcome pane is productWelcome, not the sidebar logo).
  hyprcore_resolve_image "$IMAGES" "$IMAGES_PERSONALIZE" "calamares/user-login" png jpg jpeg webp \
    || hyprcore_resolve_image "$IMAGES" "$IMAGES_PERSONALIZE" "calamares/user-icon" png jpg jpeg webp \
    || hyprcore_resolve_image "$IMAGES" "$IMAGES_PERSONALIZE" "icons/menu-icon" png jpg jpeg webp \
    || true
}

_sidebar="$(pick_sidebar_logo)"
if [[ -n "$_sidebar" ]]; then
  if command -v convert >/dev/null 2>&1 && [[ "${_sidebar##*.}" != "png" ]]; then
    convert "$_sidebar" PNG:"$br/hyprcore-logo.png"
    mkdir -p "$TARGET/usr/share/pixmaps"
    convert "$_sidebar" PNG:"$TARGET/usr/share/pixmaps/hyprcore-console.png"
  else
    cp -a "$_sidebar" "$br/hyprcore-logo.png"
    mkdir -p "$TARGET/usr/share/pixmaps"
    cp -a "$_sidebar" "$TARGET/usr/share/pixmaps/hyprcore-console.png"
  fi
else
  echo "merge-calamares-hyprcore: warning: missing calamares/user-login.png|.jpg or user-icon (sidebar logo)." >&2
fi

_welcome_large="$(pick_welcome_image)"
if [[ -n "$_welcome_large" ]]; then
  # Keep Welcome compact so language combo / requirements aren't crushed.
  if command -v convert >/dev/null 2>&1; then
    convert "$_welcome_large" -resize '560x300>' \
      -background '#151515' -gravity center -extent 560x300 \
      PNG:"$br/welcome.png"
  else
    cp -a "$_welcome_large" "$br/welcome.png"
  fi
else
  echo "merge-calamares-hyprcore: warning: missing calamares/welcome-hero.png or image.png for welcome." >&2
fi

_slide="$(pick_slideshow_image)"
if [[ -n "$_slide" ]]; then
  if command -v convert >/dev/null 2>&1 && [[ "${_slide##*.}" != "png" ]]; then
    convert "$_slide" PNG:"$br/slide1.png"
  else
    cp -a "$_slide" "$br/slide1.png"
  fi
elif [[ -f "$br/welcome.png" ]]; then
  cp -a "$br/welcome.png" "$br/slide1.png"
else
  echo "merge-calamares-hyprcore: warning: missing calamares/image.png for slideshow." >&2
fi

# Install-type packagechooser cards (compact; never reuse the full-bleed welcome art).
_profile_desktop="$(hyprcore_resolve_image "$IMAGES" "$IMAGES_PERSONALIZE" "calamares/profile-card" png jpg jpeg webp || true)"
_profile_server="$(hyprcore_resolve_image "$IMAGES" "$IMAGES_PERSONALIZE" "calamares/profile-card-server" png jpg jpeg webp || true)"
if [[ -z "${_profile_desktop:-}" && -f "$br/hyprcore-logo.png" ]]; then
  _profile_desktop="$br/hyprcore-logo.png"
fi
if [[ -z "${_profile_server:-}" ]]; then
  _profile_server="${_profile_desktop:-}"
fi
if command -v convert >/dev/null 2>&1 && [[ -n "${_profile_desktop:-}" ]]; then
  convert "$_profile_desktop" -resize 480x300\> \
    -background '#1a1a1a' -gravity center -extent 480x300 \
    PNG:"$br/profile-desktop.png"
  if [[ -n "${_profile_server:-}" ]]; then
    convert "$_profile_server" -resize 480x300\> \
      -background '#1a1a1a' -gravity center -extent 480x300 \
      PNG:"$br/profile-server.png"
  else
    convert "$_profile_desktop" -resize 480x300\> -colorspace Gray \
      -background '#1a1a1a' -gravity center -extent 480x300 \
      PNG:"$br/profile-server.png"
  fi
elif [[ -n "${_profile_desktop:-}" ]]; then
  cp -a "$_profile_desktop" "$br/profile-desktop.png"
  cp -a "${_profile_server:-$_profile_desktop}" "$br/profile-server.png"
fi
