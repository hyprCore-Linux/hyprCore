#!/usr/bin/env bash
# Sync monorepo Packages/gtk-apps into hyprCore/default so ISO staging + git
# trees match the workstation Packages checkout.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=linuxos-layout.sh
source "$REPO_ROOT/share/linuxos-layout.sh"
PACKAGES="$(hyprcore_packages_dir "$REPO_ROOT" || true)"
if [[ -z "${PACKAGES:-}" ]]; then
	echo "sync-packages-into-default: no Packages/ beside hyprCore — skip" >&2
	exit 0
fi
if [[ -d "$PACKAGES/gtk-apps/gtk-theme/python" ]]; then
	rsync -a --delete --exclude '__pycache__' --exclude '.git' \
		"$PACKAGES/gtk-apps/gtk-theme/python/" \
		"$REPO_ROOT/default/gtk-apps/gtk-theme/python/"
	rsync -a --delete --exclude '__pycache__' --exclude '.git' \
		"$PACKAGES/gtk-apps/gtk-theme/python/" \
		"$REPO_ROOT/default/gtk-apps/python/"
	echo "sync-packages-into-default: gtk-theme python"
fi
if [[ -d "$PACKAGES/gtk-apps/gtk-configs" ]]; then
	rsync -a --exclude '__pycache__' --exclude '.git' --exclude 'target' \
		"$PACKAGES/gtk-apps/gtk-configs/" \
		"$REPO_ROOT/default/gtk-apps/apps/gtk-configs/"
	echo "sync-packages-into-default: gtk-configs"
fi
