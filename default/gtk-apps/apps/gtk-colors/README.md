# gtk-colors

GTK4 color picker and format converter for the hyprCore Linux GTK apps.

Created by Kevin Hinds

## Features

- GTK color chooser dialog
- Live preview + editable RGB / Hex and many color spaces (HSL, HSV, CMYK, XYZ, CIELAB, HWB, CIELCh, LMS, Hunter Lab, RGB565)
- Five-swatch palette harmonies with CSS custom-property export
- Shared suite **Profile** theme menu (hamburger) via `gtk-theme`

## Dependencies

```bash
# Debian / Ubuntu
sudo apt-get install python3-gi gir1.2-gtk-4.0
```

PyGObject is required (`requirements.txt`).

## Usage

```bash
python3 colors.py
```

Or via the suite launcher:

```bash
~/DevTools/LinuxOS/build-launch.sh gtk-colors
```

Kevin-Launcher shortcut: `ctrl+alt+super+=`

## License

GNU General Public License v3.0. See [LICENSE](LICENSE).
