#!/usr/bin/env bash
# Resolve live-build output + generated recipe paths under scratch (never the git tree).
# Sourced by build.sh, setup.sh, and validate-manifest.sh after debian.env.
set -euo pipefail

hyprcore_build_user() {
	printf '%s' "${USER:-build}"
}

# Default live-build cwd (config/, chroot/, binary/, iso, cache/).
# /var/tmp, not /tmp: /tmp is often a RAM-backed tmpfs and a full build
# (chroot + squashfs + apt cache) needs 20-40 GB of real disk.
hyprcore_default_build_root() {
	printf '/var/tmp/hyprcore-build-%s' "$(hyprcore_build_user)"
}

# Expand leading ~ in HYPRCORE_BUILD_ROOT when set in metadata.
hyprcore_home_path() {
	local path="$1"
	case "$path" in
	"~/"*) printf '%s' "${HOME}/${path#~/}" ;;
	"~") printf '%s' "${HOME}" ;;
	*) printf '%s' "$path" ;;
	esac
}

# True if path is a scratch dir (/var/tmp, /tmp, $TMPDIR).
# Build artifacts must never land in a git tree.
hyprcore_is_tmp_path() {
	local p="${1%/}"
	local tmp="${TMPDIR:-/tmp}"
	tmp="${tmp%/}"
	[[ "$p" == /var/tmp || "$p" == /var/tmp/* \
		|| "$p" == /tmp || "$p" == /tmp/* \
		|| "$p" == "$tmp" || "$p" == "$tmp"/* ]]
}

# Set HYPRCORE_BUILD_ROOT (export) and generated recipe dirs under it.
# Always relocates to scratch if personalize/metadata (or an old $HOME default)
# would write into a checkout and dirty git.
hyprcore_apply_build_staging() {
	local from_default="${1:-}"

	if [[ -n "${HYPRCORE_BUILD_ROOT:-}" ]]; then
		HYPRCORE_BUILD_ROOT="$(hyprcore_home_path "$HYPRCORE_BUILD_ROOT")"
	elif [[ -n "$from_default" ]]; then
		HYPRCORE_BUILD_ROOT="$(hyprcore_home_path "$from_default")"
	else
		local def="${HYPRCORE_BUILD_ROOT_DEFAULT:-}"
		if [[ -n "$def" ]]; then
			HYPRCORE_BUILD_ROOT="$(hyprcore_home_path "$def")"
		else
			HYPRCORE_BUILD_ROOT="$(hyprcore_default_build_root)"
		fi
	fi

	if ! hyprcore_is_tmp_path "$HYPRCORE_BUILD_ROOT"; then
		local relocated
		relocated="$(hyprcore_default_build_root)"
		echo "hyprcore-build-staging: ${HYPRCORE_BUILD_ROOT} is not a scratch dir — using ${relocated} (keeps personalize from clobbering git trees)" >&2
		HYPRCORE_BUILD_ROOT="$relocated"
	fi

	export HYPRCORE_BUILD_ROOT
	export HYPRCORE_GEN_DIR="${HYPRCORE_BUILD_ROOT}/generated"
	export HYPRCORE_LIST_DIR="${HYPRCORE_GEN_DIR}/package-lists"
	export HYPRCORE_CALAMARES_GEN="${HYPRCORE_GEN_DIR}/calamares"
}
