#!/usr/bin/env bash
# Smoke-test desktop GUI apps on a Hyprland hyprCore session.
#
# Usage:
#   ./test-desktop-apps-hyprland.sh                    # on the VM (Hyprland session)
#   ./test-desktop-apps-hyprland.sh --remote live@HOST # via SSH
#   HYPRCORE_TEST_TIMEOUT=2 ./test-desktop-apps-hyprland.sh
set -euo pipefail

REMOTE=""
TIMEOUT="${HYPRCORE_TEST_TIMEOUT:-2}"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--remote) REMOTE="${2:?user@host required}"; shift 2 ;;
		-h|--help)
			echo "Usage: $0 [--remote user@host]"
			exit 0
			;;
		*) echo "Unknown: $1" >&2; exit 1 ;;
	esac
done

_run() {
	local timeout="$1"
	# shellcheck disable=SC2016
	cat <<'SCRIPT'
set -u
T="__TIMEOUT__"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR}/bus}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls "$XDG_RUNTIME_DIR/hypr/" 2>/dev/null | grep -v lock | head -1)}"
eval "$(systemctl --user show-environment 2>/dev/null | sed 's/^\([^=]*\)=/export \1=/')" 2>/dev/null || true

if ! pgrep -x Hyprland >/dev/null 2>&1; then
	echo "ERROR: Hyprland not running — log into hyprcore-hyprland first." >&2
	exit 2
fi

echo "=== hyprCore desktop app launch test ==="
echo "host=$(hostname) user=$(whoami) kernel=$(uname -r)"
echo "hyprcore-launch=$(test -x /usr/local/bin/hyprcore-launch && echo yes || echo NO)"
echo "hyprcore-fuzzel=$(test -x /usr/local/bin/hyprcore-fuzzel && echo yes || echo NO)"
echo "GSK_RENDERER=${GSK_RENDERER:-unset}"
echo

ok=0 fail=0 missing=0

_test() {
	local name="$1" cmd="$2" bin="$3"
	if ! command -v "$bin" >/dev/null 2>&1; then
		echo "MISSING|$name|binary $bin not installed"
		missing=$((missing + 1))
		return
	fi
	hyprctl dispatch exec "$cmd" >/dev/null 2>&1 || true
	sleep "$T"
	if pgrep -x "$bin" >/dev/null 2>&1 || pgrep -f "/${bin}( |$)" >/dev/null 2>&1; then
		echo "OK|$name|started"
		ok=$((ok + 1))
		pkill -x "$bin" 2>/dev/null || pkill -f "/${bin}( |$)" 2>/dev/null || true
		sleep 0.2
		return
	fi
	log="/tmp/hyprcore-test-${name}.log"
	# shellcheck disable=SC2086
	$cmd >"$log" 2>&1 &
	local pid=$!
	sleep "$T"
	if kill -0 "$pid" 2>/dev/null; then
		kill "$pid" 2>/dev/null || true
		echo "OK|$name|direct"
		ok=$((ok + 1))
	else
		wait "$pid" 2>/dev/null || true
		note=$(tail -1 "$log" 2>/dev/null | cut -c1-72)
		echo "FAIL|$name|${note:-exit error}"
		fail=$((fail + 1))
	fi
}

_test gtk-term "hyprcore-launch gtk-term" gtk-term
_test gtk-files "hyprcore-launch gtk-files" gtk-files
_test gtk-edit "hyprcore-launch gtk-edit" gtk-edit
_test gtk-image "hyprcore-launch gtk-image" gtk-image
_test gtk-video "hyprcore-launch gtk-video" gtk-video
_test gtk-player "hyprcore-launch gtk-player" gtk-player
_test gtk-calc "hyprcore-launch gtk-calc" gtk-calc
_test galculator "hyprcore-launch galculator" galculator
_test imv "hyprcore-launch imv" imv
_test zathura "hyprcore-launch zathura" zathura
_test xarchiver "hyprcore-launch xarchiver" xarchiver
_test xfce4-power-manager "hyprcore-launch xfce4-power-manager" xfce4-power-manager
_test gparted "hyprcore-launch gparted" gparted
_test gimp "hyprcore-launch gimp" gimp
_test deskflow "hyprcore-launch deskflow" deskflow
_test synaptic "hyprcore-launch synaptic" synaptic
_test system-config-printer "hyprcore-launch system-config-printer" system-config-printer
_test dconf-editor "hyprcore-launch dconf-editor" dconf-editor
_test remmina "hyprcore-launch remmina" remmina
_test kicad "hyprcore-launch kicad" kicad
_test handbrake "hyprcore-launch handbrake" handbrake
_test kdenlive "hyprcore-launch kdenlive" kdenlive
_test openshot-qt "hyprcore-launch openshot-qt" openshot-qt
_test smplayer "hyprcore-launch smplayer" smplayer
_test vlc "hyprcore-launch vlc" vlc
_test mpv "hyprcore-launch mpv" mpv
_test mplayer "hyprcore-launch mplayer" mplayer
_test audacity "hyprcore-x11-app audacity" audacity
_test blender "hyprcore-x11-app blender" blender
_test nwg-bar "hyprcore-launch nwg-bar" nwg-bar
_test hypr-settings "hyprcore-launch hypr-settings" hypr-settings

echo
echo "=== Summary: OK=$ok FAIL=$fail MISSING=$missing ==="

if [ "$fail" -gt 0 ] || [ "$missing" -gt 0 ]; then
	echo
	echo "=== Remediation ==="
	echo "• Re-login to hyprcore-hyprland (Layer B env must include GSK_RENDERER=cairo)."
	echo "• Launch via Super+D (hyprcore-fuzzel) or: hyprcore-launch APP"
	echo "• audacity/blender: desktop Exec must use hyprcore-x11-app; xwayland enabled in hyprland.conf"
	echo "• GPU apps in VM: VirtualBox 3D acceleration + Guest Additions"
	echo "• Missing hyprcore-launch: rebuild ISO or copy from overlay /usr/local/bin/"
	exit 1
fi
exit 0
SCRIPT
}

script=$(_run "$TIMEOUT")
script="${script//__TIMEOUT__/$TIMEOUT}"

if [[ -n "$REMOTE" ]]; then
	if command -v sshpass >/dev/null 2>&1 && [[ -n "${SSHPASS:-}" ]]; then
		sshpass -e ssh -o StrictHostKeyChecking=accept-new -o PreferredAuthentications=password -o PubkeyAuthentication=no "$REMOTE" "bash -s" <<< "$script"
	else
		ssh -o StrictHostKeyChecking=accept-new "$REMOTE" "bash -s" <<< "$script"
	fi
else
	bash -s <<< "$script"
fi
