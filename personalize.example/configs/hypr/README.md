# personalize/configs/hypr/

Stock session config lives in `default/configs/hypr/`. Deep-merge overlays
same-named files only — **do not** replace `hyprland.lua` unless you want a full fork.

Stock `hyprland.lua` requires `monitors` then ends with `require("binds-personal")`.
Put extra binds and workspace rules here (or in `workspaces.lua` if you require it
from binds-personal).

To customize window parking / overview / named outputs, drop a full
`window-manager.py` here. It replaces the stock no-op at
`default/configs/hypr/window-manager.py`. Wire it from `binds-personal.lua`:

```lua
local home = os.getenv("HOME") or ""
local window_manager = home .. "/.config/hypr/window-manager.py"
hl.on("hyprland.start", function()
    hl.exec_cmd(window_manager .. " watch")
end)
hl.bind("CTRL + SUPER + ALT + 2", hl.dsp.exec_cmd(window_manager .. " bottom"))
```

Do not use `monitor=…,addreserved,…` to leave a float strip: Hyprland clamps
xdg-popups to the non-reserved work area, so GTK/Chrome context menus fail on
windows in that zone.

## Example `binds-personal.lua`

```lua
-- Optional personalize binds (required by stock hyprland.lua)
hl.bind("CTRL + ALT + J", hl.dsp.exec_cmd("hyprcore-launch gtk-files /home/$USER/SORT"))
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd("gtk-term"))
require("workspaces")
```
