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

# Live media ships the personalize tree, including a workstation monitor
# layout (named 4K outputs). That modeset runs before exec-once, so a
# machine whose panel is not those outputs stays black and Calamares
# never appears. Use the default preferred-mode layout for this boot
# only. /etc/skel still has the workstation file for the installed user.
if grep -qw boot=live /proc/cmdline 2>/dev/null; then
	_hypr_conf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
	if [ -d "$_hypr_conf" ] && [ -w "$_hypr_conf" ]; then
		cat >"$_hypr_conf/monitors.conf" <<'EOF'
# Live session. Each connected display uses its preferred mode.
# The workstation layout stays in /etc/skel for the installed system.
monitor=,preferred,auto,1
EOF
		if [ -f "$_hypr_conf/hyprland.conf" ] && [ -w "$_hypr_conf/hyprland.conf" ]; then
			sed -i \
				's|/usr/share/neuronix/neuronix-hyprland-session-start.sh|/usr/share/hyprcore/hyprcore-hyprland-session-start.sh|' \
				"$_hypr_conf/hyprland.conf"
		fi
	fi
fi

exec start-hyprland
