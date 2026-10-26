# shellcheck shell=bash
# Shared parser for default/install-list (@manifest-format: 1)
#
# Package line:  PACKAGENAME # description
# Section line:  # --- section-name ---
#
# Usage:
#   source "$(dirname "$0")/manifest-lib.sh"   # from hyprcore-iso/packages/
#   hyprcore_manifest_load /path/to/default/install-list
#   printf '%s\n' "${HYPRCORE_MANIFEST_PKGS[@]}"
#   echo "${HYPRCORE_MANIFEST_DESC[sudo]}"
#   echo "${HYPRCORE_MANIFEST_SECTION[nwg-bar]}"

if [[ -n "${HYPRCORE_MANIFEST_LIB_LOADED:-}" ]]; then
	return 0 2>/dev/null || exit 0
fi
HYPRCORE_MANIFEST_LIB_LOADED=1

declare -a HYPRCORE_MANIFEST_PKGS=()
declare -A HYPRCORE_MANIFEST_DESC=()
declare -A HYPRCORE_MANIFEST_SECTION=()

# Parse one manifest line into HYPRCORE_MANIFEST_LINE_PKG / HYPRCORE_MANIFEST_LINE_DESC.
# Returns 0 if line defines a package, 1 otherwise.
hyprcore_manifest_parse_line() {
	local line="${1-}" section_ref="${2:-}"
	HYPRCORE_MANIFEST_LINE_PKG=""
	HYPRCORE_MANIFEST_LINE_DESC=""

	line="${line%%$'\r'}"
	[[ -z "${line//[[:space:]]/}" ]] && return 1

	if [[ "$line" =~ ^[[:space:]]*# ]]; then
		if [[ -n "$section_ref" && "$line" =~ ^[[:space:]]*#[[:space:]]*---[[:space:]]*(.+)[[:space:]]*---[[:space:]]*$ ]]; then
			printf -v "$section_ref" '%s' "${BASH_REMATCH[1]%%[[:space:]]}"
		fi
		return 1
	fi

	if [[ "$line" == *" # "* ]]; then
		HYPRCORE_MANIFEST_LINE_PKG="${line%% # *}"
		HYPRCORE_MANIFEST_LINE_DESC="${line#* # }"
	else
		HYPRCORE_MANIFEST_LINE_PKG="${line%% *}"
		HYPRCORE_MANIFEST_LINE_DESC=""
	fi

	HYPRCORE_MANIFEST_LINE_PKG="${HYPRCORE_MANIFEST_LINE_PKG#"${HYPRCORE_MANIFEST_LINE_PKG%%[![:space:]]*}"}"
	HYPRCORE_MANIFEST_LINE_PKG="${HYPRCORE_MANIFEST_LINE_PKG%"${HYPRCORE_MANIFEST_LINE_PKG##*[![:space:]]}"}"
	HYPRCORE_MANIFEST_LINE_DESC="${HYPRCORE_MANIFEST_LINE_DESC#"${HYPRCORE_MANIFEST_LINE_DESC%%[![:space:]]*}"}"
	HYPRCORE_MANIFEST_LINE_DESC="${HYPRCORE_MANIFEST_LINE_DESC%"${HYPRCORE_MANIFEST_LINE_DESC##*[![:space:]]}"}"
	[[ -n "$HYPRCORE_MANIFEST_LINE_PKG" ]] || return 1
	return 0
}

# Load manifest file into HYPRCORE_MANIFEST_* globals (replaces prior contents).
hyprcore_manifest_load() {
	local file="$1" line section=""
	HYPRCORE_MANIFEST_PKGS=()
	HYPRCORE_MANIFEST_DESC=()
	HYPRCORE_MANIFEST_SECTION=()

	[[ -r "$file" ]] || {
		echo "manifest-lib: unreadable file: $file" >&2
		return 1
	}

	while IFS= read -r line || [[ -n "$line" ]]; do
		if hyprcore_manifest_parse_line "$line" section; then
			HYPRCORE_MANIFEST_PKGS+=("$HYPRCORE_MANIFEST_LINE_PKG")
			HYPRCORE_MANIFEST_DESC["$HYPRCORE_MANIFEST_LINE_PKG"]="$HYPRCORE_MANIFEST_LINE_DESC"
			HYPRCORE_MANIFEST_SECTION["$HYPRCORE_MANIFEST_LINE_PKG"]="$section"
		fi
	done <"$file"
}

# Append packages from another manifest (e.g. personalize/install-list).
# Skips names already present (base wins). Section comes from the append file.
hyprcore_manifest_append() {
	local file="$1" line section="" pkg
	[[ -r "$file" ]] || {
		echo "manifest-lib: unreadable file: $file" >&2
		return 1
	}

	while IFS= read -r line || [[ -n "$line" ]]; do
		if hyprcore_manifest_parse_line "$line" section; then
			pkg="$HYPRCORE_MANIFEST_LINE_PKG"
			[[ -n "${HYPRCORE_MANIFEST_SECTION[$pkg]+x}" ]] && continue
			HYPRCORE_MANIFEST_PKGS+=("$pkg")
			HYPRCORE_MANIFEST_DESC["$pkg"]="$HYPRCORE_MANIFEST_LINE_DESC"
			HYPRCORE_MANIFEST_SECTION["$pkg"]="$section"
		fi
	done <"$file"
}

# Print TSV: package<TAB>section<TAB>description
hyprcore_manifest_print_tsv() {
	local pkg
	for pkg in "${HYPRCORE_MANIFEST_PKGS[@]}"; do
		printf '%s\t%s\t%s\n' \
			"$pkg" \
			"${HYPRCORE_MANIFEST_SECTION[$pkg]:-}" \
			"${HYPRCORE_MANIFEST_DESC[$pkg]:-}"
	done
}

# Strip description from a package line (for .list.chroot compatibility).
hyprcore_manifest_pkg_only() {
	local line="${1-}" pkg=""
	if hyprcore_manifest_parse_line "$line"; then
		pkg="$HYPRCORE_MANIFEST_LINE_PKG"
	else
		line="${line%%#*}"
		line="${line#"${line%%[![:space:]]*}"}"
		line="${line%"${line##*[![:space:]]}"}"
		[[ -n "$line" ]] && pkg="${line%% *}"
	fi
	[[ -n "$pkg" ]] && printf '%s' "$pkg"
	return 0
}
