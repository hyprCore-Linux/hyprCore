#!/usr/bin/env bash
# Calamares Desktop profile: apt-install desktop/compositor packages onto server base.
# Hyprland (backports) and Chrome are installed by subsequent hooks — skip here.
# Cursor is personalize/install only (not stock Desktop).
set -euo pipefail

PKG_LIST="${HYPRCORE_DESKTOP_PACKAGES_LIST:-/etc/calamares/hyprcore-desktop-packages.list}"

echo "[hyprcore-desktop] Installing desktop packages…"

if [[ ! -r "$PKG_LIST" ]]; then
	echo "[hyprcore-desktop] Missing package list: $PKG_LIST" >&2
	exit 1
fi

_skip() {
	case "$1" in
		hyprland|hyprpaper|hyprpicker|xdg-desktop-portal-hyprland|hyprland-guiutils|ydotool|google-chrome-stable)
			return 0
			;;
		*) return 1 ;;
	esac
}

mapfile -t _pkgs < <(awk '
	/^[[:space:]]*#/ { next }
	/^[[:space:]]*$/ { next }
	{ print $1 }
' "$PKG_LIST")

if ((${#_pkgs[@]} == 0)); then
	echo "[hyprcore-desktop] Package list is empty — nothing to install (OK)."
	exit 0
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

_to_install=()
for pkg in "${_pkgs[@]}"; do
	if _skip "$pkg"; then
		continue
	fi
	if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q ' install ok installed'; then
		continue
	fi
	_to_install+=("$pkg")
done

if ((${#_to_install[@]} > 0)); then
	echo "[hyprcore-desktop] Installing ${#_to_install[@]} packages (no Recommends)…"
	# kdenlive Depends KF6/Breeze; kio6 Recommends systemsettings and
	# purpose Recommends kdeconnect — skip those Plasma extras.
	apt-get install -y --no-install-recommends "${_to_install[@]}"
else
	echo "[hyprcore-desktop] All listed packages already installed (or deferred to hooks)."
fi

# Point Chromium menu/mime at hyprcore-chromium (package .desktop overwrites includes.chroot)
_wire_hyprcore_chromium() {
	[[ -x /usr/local/bin/hyprcore-chromium ]] || return 0
	local apps=/usr/share/applications
	mkdir -p "$apps"
	cat >"$apps/hyprcore-chromium.desktop" <<'DESK'
[Desktop Entry]
Version=1.0
Type=Application
Name=Chromium
Comment=Chromium with hyprCore extensions
Exec=hyprcore-chromium %U
TryExec=hyprcore-chromium
Icon=chromium
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
StartupWMClass=Chromium-browser
DESK
	if command -v chromium >/dev/null 2>&1 || command -v chromium-browser >/dev/null 2>&1; then
		cat >"$apps/chromium.desktop" <<'DESK'
[Desktop Entry]
Version=1.0
Type=Application
Name=Chromium Web Browser
Comment=Chromium with hyprCore extensions
Exec=hyprcore-chromium %U
TryExec=hyprcore-chromium
Icon=chromium
Terminal=false
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
StartupWMClass=Chromium-browser
DESK
	fi
	if [[ -x /usr/share/hyprcore/register-chrome-extensions.sh ]]; then
		/usr/share/hyprcore/register-chrome-extensions.sh || true
	fi
}
_wire_hyprcore_chromium

# SSH remote login for the installed Desktop user (also covered by sshprep)
if [[ -x /usr/local/sbin/hyprcore-enable-ssh ]]; then
	/usr/local/sbin/hyprcore-enable-ssh || true
fi

echo "[hyprcore-desktop] Desktop package install complete."
