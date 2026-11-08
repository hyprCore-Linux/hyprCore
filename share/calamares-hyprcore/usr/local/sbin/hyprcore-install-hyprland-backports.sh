#!/usr/bin/env bash
# Install Hyprland 0.56.2 stack for hyprCore (live hook 997 + Calamares Desktop).
#
# Filename kept as *-backports.sh for Calamares / merge script compatibility.
#
# Target OS: Debian 13 (trixie).
# - hyprland / hyprland-dev: 0.56.2+ds-3 from snapshot.debian.org
# - hyprpaper: 0.8.4-1~bpo13+1 from the same snapshot era
#   (sid 0.8.5 aborts with "free(): invalid pointer" against Hyprland 0.56.2)
# - xdph / guiutils / hyprpicker: from unstable (low pin priority)
# Kernel is handled separately by hyprcore-install-kernel-latest.sh.
set -euo pipefail

HYPRLAND_VER="${HYPRCORE_HYPRLAND_VER:-0.56.2+ds-3}"
HYPRLAND_SNAPSHOT="${HYPRCORE_HYPRLAND_SNAPSHOT:-20260914T142711Z}"
HYPR_PAPER_VER="${HYPRCORE_HYPR_PAPER_VER:-0.8.4-1~bpo13+1}"
DEB_CACHE="${HYPRCORE_HYPRLAND_DEBDIR:-/usr/share/hyprcore/debs/hyprland-0.56}"
ARCH="$(dpkg --print-architecture 2>/dev/null || echo amd64)"

_log() { printf '[hyprcore-hyprland] %s\n' "$*"; }
_warn() { printf '[hyprcore-hyprland] WARNING: %s\n' "$*" >&2; }

_suite() {
	# shellcheck disable=SC1091
	. /etc/os-release 2>/dev/null || true
	printf '%s' "${VERSION_CODENAME:-trixie}"
}

_fetch() {
	local url="$1" dest="$2"
	if command -v wget >/dev/null 2>&1; then
		wget -q -O "${dest}.partial" "${url}"
	elif command -v curl >/dev/null 2>&1; then
		curl -fsSL -o "${dest}.partial" "${url}"
	else
		_warn "need wget or curl to fetch ${url}"
		return 1
	fi
	mv -f "${dest}.partial" "${dest}"
}

_ensure_sid_apt() {
	mkdir -p /etc/apt/sources.list.d /etc/apt/preferences.d

	# Drop legacy NVIDIA / LTS kernel freezes — latest Debian 13 kernel is OK.
	rm -f /etc/apt/preferences.d/hyprcore-kernel-lts \
		/etc/apt/preferences.d/hyprcore-kernel-latest \
		/etc/dkms/nvidia-current.conf \
		/etc/apt/sources.list.d/hyprland-0.56-sid.list

	cat >/etc/apt/sources.list.d/hyprcore-sid.list <<'EOF'
# Low-priority sid for Hyprland 0.56 companions (xdph / guiutils / …).
# hyprpaper is NOT taken from sid — 0.8.5 crashes with Hyprland 0.56.2.
# Only used with: apt-get install -t unstable …
deb http://deb.debian.org/debian sid main contrib non-free non-free-firmware
EOF

	cat >/etc/apt/preferences.d/hyprcore-sid <<'EOF'
Package: *
Pin: release a=unstable
Pin-Priority: 100
EOF

	# Never pull sid kernels; use trixie / trixie-backports instead.
	cat >/etc/apt/preferences.d/hyprcore-kernel-sid <<'EOF'
Package: linux-*
Pin: release a=unstable
Pin-Priority: -1
EOF

	# Hold the compositor on 0.56.2 even if sid advances to 0.57+.
	cat >/etc/apt/preferences.d/hyprcore-hyprland-056 <<EOF
Package: hyprland
Pin: version ${HYPRLAND_VER}
Pin-Priority: 1001

Package: hyprland-dev
Pin: version ${HYPRLAND_VER}
Pin-Priority: 1001
EOF

	# Hold hyprpaper on the known-good 0.8.4 build (sid 0.8.5 crashes).
	cat >/etc/apt/preferences.d/hyprcore-hyprpaper-084 <<EOF
Package: hyprpaper
Pin: version ${HYPR_PAPER_VER}
Pin-Priority: 1001
EOF
}

_download_stack_debs() {
	mkdir -p "${DEB_CACHE}"
	local base="https://snapshot.debian.org/archive/debian/${HYPRLAND_SNAPSHOT}/pool/main/h"
	local pkg deb dest url enc

	for pkg in hyprland hyprland-dev; do
		deb="${pkg}_${HYPRLAND_VER}_${ARCH}.deb"
		dest="${DEB_CACHE}/${deb}"
		if [[ -s "${dest}" ]]; then
			_log "have ${deb}"
			continue
		fi
		url="${base}/hyprland/${pkg}_${HYPRLAND_VER//+/%2B}_${ARCH}.deb"
		_log "download ${deb}"
		_fetch "${url}" "${dest}"
	done

	deb="hyprpaper_${HYPR_PAPER_VER}_${ARCH}.deb"
	dest="${DEB_CACHE}/${deb}"
	if [[ -s "${dest}" ]]; then
		_log "have ${deb}"
	else
		enc="${HYPR_PAPER_VER//'~'/%7E}"
		enc="${enc//+/%2B}"
		url="${base}/hyprpaper/hyprpaper_${enc}_${ARCH}.deb"
		_log "download ${deb}"
		_fetch "${url}" "${dest}"
	fi
}

_install_stack() {
	local with_dev=0
	case "${1:-}" in
		--with-dev) with_dev=1 ;;
	esac

	export DEBIAN_FRONTEND=noninteractive
	_ensure_sid_apt
	apt-get update -qq

	_download_stack_debs

	local -a debs=(
		"${DEB_CACHE}/hyprland_${HYPRLAND_VER}_${ARCH}.deb"
		"${DEB_CACHE}/hyprpaper_${HYPR_PAPER_VER}_${ARCH}.deb"
	)
	if [[ "${with_dev}" -eq 1 ]]; then
		debs+=("${DEB_CACHE}/hyprland-dev_${HYPRLAND_VER}_${ARCH}.deb")
	fi

	local f
	for f in "${debs[@]}"; do
		[[ -s "${f}" ]] || {
			_warn "missing ${f}"
			return 1
		}
	done

	_log "install Hyprland ${HYPRLAND_VER} + hyprpaper ${HYPR_PAPER_VER} + sid companions (suite=$(_suite))"
	# Local hyprland/hyprpaper debs first; companions from unstable (not hyprpaper).
	apt-get install -y \
		"${debs[@]}"
	apt-get install -y -t unstable \
		xdg-desktop-portal-hyprland \
		hyprland-guiutils \
		hyprpicker \
		ydotool

	_log "versions:"
	dpkg -l hyprland hyprpaper xdg-desktop-portal-hyprland hyprland-guiutils hyprpicker \
		| awk '/^ii/{print "  "$2" "$3}'
}

_install_stack "${1:-}"
_log "OK."
