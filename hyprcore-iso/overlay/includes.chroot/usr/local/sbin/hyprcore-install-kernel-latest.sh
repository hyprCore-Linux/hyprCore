#!/usr/bin/env bash
# Install the latest Debian 13 kernel from trixie-backports (linux 7.x).
# No NVIDIA DKMS freeze; sid kernels stay pinned out separately.
set -euo pipefail

_log() { printf '[hyprcore-kernel] %s\n' "$*"; }

# shellcheck disable=SC1091
. /etc/os-release 2>/dev/null || true
suite="${VERSION_CODENAME:-trixie}"
backports="${suite}-backports"

mkdir -p /etc/apt/sources.list.d /etc/apt/preferences.d

# Drop legacy NVIDIA / LTS kernel freezes.
rm -f /etc/apt/preferences.d/hyprcore-kernel-lts \
	/etc/apt/preferences.d/hyprcore-kernel-latest \
	/etc/dkms/nvidia-current.conf

# Ensure backports is present (also shipped as hyprcore-backports.list).
if [ -f /etc/apt/sources.list ] && ! grep -qE "[[:space:]]${backports}[[:space:]]" /etc/apt/sources.list 2>/dev/null \
	&& ! grep -rqE "[[:space:]]${backports}[[:space:]]" /etc/apt/sources.list.d 2>/dev/null; then
	printf '\ndeb http://deb.debian.org/debian %s main contrib non-free non-free-firmware\n' "${backports}" \
		>>/etc/apt/sources.list
	_log "added ${backports} to sources.list"
fi

# Prefer backports metas over stock suite when both exist.
cat >/etc/apt/preferences.d/hyprcore-kernel-latest <<EOF
Package: linux-image-amd64
Pin: release n=${backports}
Pin-Priority: 990

Package: linux-headers-amd64
Pin: release n=${backports}
Pin-Priority: 990
EOF

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

_log "install linux-image-amd64 + linux-headers-amd64 from ${backports}"
apt-get install -y -t "${backports}" \
	linux-image-amd64 \
	linux-headers-amd64

_log "versions:"
dpkg -l linux-image-amd64 linux-headers-amd64 2>/dev/null \
	| awk '/^ii/{print "  "$2" "$3}'
_log "OK."
