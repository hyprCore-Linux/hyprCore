# shellcheck shell=bash
# Monorepo layout helpers — shared by hyprcore-iso/setup.sh and Packages tools.
#
# Expected siblings of this hyprCore checkout:
#   ../Packages/gtk-apps
#   ../Packages/hyprframes
#   ../KvNix/
#
# ISO setup and syn-to-devices resolve the monorepo root from this layout
# (parent of hyprCore/, or walk-up from Packages/). No on-disk marker files.
#
# Usage:
#   source "$REPO_ROOT/share/linuxos-layout.sh"
#   MONOREPO_ROOT="$(hyprcore_linuxos_root "$REPO_ROOT")" || true
#   PACKAGES="$(hyprcore_packages_dir "$REPO_ROOT")" || true

if [[ -n "${HYPRCORE_LINUXOS_LAYOUT_LOADED:-}" ]]; then
	return 0 2>/dev/null || exit 0
fi
HYPRCORE_LINUXOS_LAYOUT_LOADED=1

# Echo absolute path of the hyprCore checkout (parent of share/).
hyprcore_repo_root_from_share() {
	cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

# True when $1 is a monorepo root (has hyprCore stock gtk-apps).
hyprcore_is_linuxos_root() {
	local d="${1:-}"
	[[ -n "$d" && -d "$d" ]] || return 1
	[[ -d "$d/hyprCore/default/gtk-apps" || -d "$d/hyprCore/Build/default/gtk-apps" ]]
}

# Monorepo root for a hyprCore checkout: parent directory when it has the
# expected siblings. Echoes absolute path.
# Usage: hyprcore_linuxos_root [hyprcore_repo_root]
hyprcore_linuxos_root() {
	local repo="${1:-}"
	if [[ -z "$repo" ]]; then
		repo="$(hyprcore_repo_root_from_share)"
	fi
	repo="$(cd "$repo" && pwd)"
	local root
	root="$(cd "$repo/.." && pwd)"
	if hyprcore_is_linuxos_root "$root"; then
		printf '%s\n' "$root"
		return 0
	fi
	# Parent has Packages/ even if hyprCore path layout differs slightly.
	if [[ -d "$root/Packages" && -d "$repo/default/gtk-apps" ]]; then
		printf '%s\n' "$root"
		return 0
	fi
	return 1
}

# Echo <monorepo>/Packages when present.
# Usage: hyprcore_packages_dir [hyprcore_repo_root]
hyprcore_packages_dir() {
	local root
	root="$(hyprcore_linuxos_root "${1:-}")" || return 1
	[[ -d "$root/Packages" ]] || return 1
	printf '%s\n' "$root/Packages"
}
