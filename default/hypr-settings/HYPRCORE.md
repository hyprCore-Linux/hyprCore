# hypr-settings (hyprCore packaged)

System settings app for Hyprland desktops (Wi‑Fi, Ethernet, Bluetooth, Displays, Sound,
Apps, Themes, Configs, Screensaver, Battery, System Info, Weather).

**Themes** launches `gtk-theme-editor` (suite color profiles).
**Configs** is the former gtk-configs editor (`configs_lib/`) for `~/configs`
(Hyprland, Waybar, Fuzzel, Mako, GTK, MIME, …) without color pickers.
**Screensaver** configures `hyprcore-screensaver-idle` (`~/.config/hyprcore-screensaver/config.ini`).
**Weather** shows a WeatherAPI.com current reading and 3-day forecast (`~/.config/hyprcore/weather.json`).

Upstream settings shell: vendored from hypr-settings-main (PySide6 / Qt6).

```bash
sudo ./hyprcore-install.sh
# or into an ISO tree:
sudo DESTDIR=/path/to/includes.chroot ./hyprcore-install.sh
```

Requires: `python3-pyside6.qt{core,gui,widgets,charts}` (see install-list).
