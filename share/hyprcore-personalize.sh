# shellcheck shell=bash
# Personalize overlay helpers — prefer personalize/ over committed defaults.
#
# Usage (from repo scripts):
#   source "$REPO_ROOT/share/hyprcore-personalize.sh"
#   hyprcore_resolve_file "$REPO_ROOT/default/images" "$REPO_ROOT/personalize/images" "live/background.png"
#   hyprcore_resolve_image "$REPO_ROOT/default/images" "$REPO_ROOT/personalize/images" "icons/menu-icon"

if [[ -n "${HYPRCORE_PERSONALIZE_LIB_LOADED:-}" ]]; then
	return 0 2>/dev/null || exit 0
fi
HYPRCORE_PERSONALIZE_LIB_LOADED=1

# Echo absolute path if $1/$2 exists (file).
_hyprcore_file_if_exists() {
	local root="$1" rel="$2"
	[[ -n "$root" && -n "$rel" && -f "${root%/}/$rel" ]] || return 1
	printf '%s\n' "${root%/}/$rel"
}

_hyprcore_has_file() {
	local root="$1" rel="$2"
	[[ -n "$root" && -n "$rel" && -f "${root%/}/$rel" ]]
}

# Prefer personalize_root/rel over defaults_root/rel.
# Usage: hyprcore_resolve_file <defaults_root> <personalize_root> <relative_path>
hyprcore_resolve_file() {
	local defaults_root="$1" personalize_root="$2" rel="$3"
	if _hyprcore_has_file "$personalize_root" "$rel"; then
		_hyprcore_file_if_exists "$personalize_root" "$rel"
		return 0
	fi
	if _hyprcore_has_file "$defaults_root" "$rel"; then
		_hyprcore_file_if_exists "$defaults_root" "$rel"
		return 0
	fi
	return 1
}

# Prefer personalize, then defaults; try each extension for basename_no_ext.
# Usage: hyprcore_resolve_image <defaults_root> <personalize_root> <rel_without_ext> [ext...]
# Default extensions: png jpg jpeg webp
hyprcore_resolve_image() {
	local defaults_root="$1" personalize_root="$2" rel_base="$3"
	shift 3
	local -a exts=("$@")
	local ext rel
	if ((${#exts[@]} == 0)); then
		exts=(png jpg jpeg webp)
	fi
	for ext in "${exts[@]}"; do
		rel="${rel_base}.${ext}"
		if _hyprcore_has_file "$personalize_root" "$rel"; then
			_hyprcore_file_if_exists "$personalize_root" "$rel"
			return 0
		fi
	done
	for ext in "${exts[@]}"; do
		rel="${rel_base}.${ext}"
		if _hyprcore_has_file "$defaults_root" "$rel"; then
			_hyprcore_file_if_exists "$defaults_root" "$rel"
			return 0
		fi
	done
	return 1
}

# Install wallpapers into dest.
# If personalize/images/installed contains any image, those files are the only
# ones installed. An empty or missing personalize folder uses the defaults.
# Previous images in dest are removed so leftovers from the other set do not remain.
# Prints the source directory used.
hyprcore_stage_installed_wallpapers() {
	local dest="$1" defaults_dir="$2" personalize_dir="$3"
	local src="" dir f
	local nullglob_was=0
	shopt -q nullglob && nullglob_was=1
	shopt -s nullglob
	for dir in "$personalize_dir" "$defaults_dir"; do
		[[ -d "$dir" ]] || continue
		for f in "$dir"/*.png "$dir"/*.jpg "$dir"/*.jpeg "$dir"/*.webp; do
			[[ -f "$f" ]] || continue
			src="$dir"
			break 2
		done
	done
	if [[ -z "$src" ]]; then
		((nullglob_was)) || shopt -u nullglob
		echo "no installed wallpapers in ${personalize_dir} or ${defaults_dir}" >&2
		return 1
	fi
	mkdir -p "$dest"
	find "$dest" -mindepth 1 -maxdepth 1 -type f \
		\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -delete
	for f in "$src"/*.png "$src"/*.jpg "$src"/*.jpeg "$src"/*.webp; do
		[[ -f "$f" ]] || continue
		cp -a "$f" "$dest/"
	done
	((nullglob_was)) || shopt -u nullglob
	printf '%s\n' "$src"
}
