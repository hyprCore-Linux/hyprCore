#!/usr/bin/env bash
# Calamares: after slim unpack — drop live-only LightDM autologin bits.
# Full desktop purge is Server-profile only (hyprcore-apply-server-profile.sh).
set -euo pipefail

echo "[hyprcore-strip] Cleaning live-session installer leftovers…"

rm -f /etc/lightdm/lightdm.conf.d/50-hyprcore-live-autologin.conf \
	/etc/lightdm/lightdm.conf.d/10-hyprcore-lightdm-debug.conf 2>/dev/null || true

echo "[hyprcore-strip] Done."
