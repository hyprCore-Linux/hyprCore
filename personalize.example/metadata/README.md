# personalize/metadata/

Optional branding / distro identity overlays. Copied into private
`personalize/metadata/` (no `.sample` suffix).

## Example `debian.env`

Sourced **after** `default/metadata/debian.env` — set only keys you want to change:

```bash
# HYPRCORE_PRODUCT_NAME=MyhyprCore
# HYPRCORE_LIVE_HOSTNAME=my-hyprcore
# HYPRCORE_PRODUCT_VERSION=0.1
```

## Example `debian.distro.conf`

Replaces `/etc/hyprcore/distro.conf` when present:

```bash
# HYPRCORE_DISTRO=debian
# HYPRCORE_SUITE=trixie
# HYPRCORE_PRODUCT_NAME=MyhyprCore
# HYPRCORE_LIVE_HOSTNAME=my-hyprcore
# HYPRCORE_DESKTOP_SESSION=hyprcore-hyprland
# HYPRCORE_CALAMARES_INSTALLER=calamares-install-debian
# HYPRCORE_ENABLE_BACKPORTS=1
# HYPRCORE_FLATPAK_DECIBELS=0
```
