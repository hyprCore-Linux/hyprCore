#!/bin/sh
# LightDM / greetd entry: start Hyprland with hyprCore session environment.

set -e

if [ -r /usr/share/hyprcore/hyprcore-hyprland-session-env.sh ]; then
	# shellcheck source=/usr/share/hyprcore/hyprcore-hyprland-session-env.sh
	. /usr/share/hyprcore/hyprcore-hyprland-session-env.sh
	hyprcore_hyprland_session_env
fi

# Clear failed portal units left by the previous graphical session (user systemd
# often survives logout). They must not start until Hyprland owns WAYLAND_DISPLAY.
if command -v systemctl >/dev/null 2>&1; then
	systemctl --user stop \
		xdg-desktop-portal-hyprland.service \
		xdg-desktop-portal-gtk.service \
		xdg-desktop-portal.service \
		2>/dev/null || true
	systemctl --user reset-failed \
		xdg-desktop-portal-hyprland.service \
		xdg-desktop-portal-gtk.service \
		xdg-desktop-portal.service \
		2>/dev/null || true
fi

exec start-hyprland
