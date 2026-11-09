-- hyprCore Hyprland Lua config (Hyprland 0.55+). Legacy .conf removed in 0.57.
do
  local here = debug.getinfo(1, "S").source:match("^@(.*/)") or ""
  if here ~= "" then
    package.path = here .. "?.lua;" .. here .. "?/init.lua;" .. package.path
  end
end

-- hyprCore Hyprland — GNOME-style shortcuts (black / red / white chrome elsewhere)

hl.env("GSK_RENDERER", "cairo")
hl.env("GTK_THEME", "hyprcore")
hl.env("GTK_ICON_THEME", "Papirus-Dark")
hl.env("XDG_ICON_THEME", "Papirus-Dark")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("SAL_USE_VCLPLUGIN", "gtk3")
hl.env("XCURSOR_SIZE", "24")

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "1",
})

-- Personalize overlay (empty in default/). Named outputs must come after the fallback.
require("monitors")

hl.animation({
    leaf = "global",
    enabled = true,
    speed = 4,
    bezier = "default",
})
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 3.5,
    bezier = "default",
})
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 3.5,
    bezier = "default",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 3,
    bezier = "default",
})
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 3.5,
    bezier = "default",
})
hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 3,
    bezier = "default",
})
hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 3,
    bezier = "default",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 3,
    bezier = "default",
})
hl.animation({
    leaf = "workspacesIn",
    enabled = true,
    speed = 3,
    bezier = "default",
})
hl.animation({
    leaf = "workspacesOut",
    enabled = true,
    speed = 3,
    bezier = "default",
})
hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 4,
    bezier = "default",
})
hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 4,
    bezier = "default",
})
hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 3,
    bezier = "default",
})


-- Layer surfaces (fuzzel / waybar / settings / wallpaper)
hl.layer_rule({
    name = "launcher-slide",
    match = { namespace = "launcher" },
    animation = "slide bottom",
    blur = true,
    ignore_alpha = 0.15,
})
hl.layer_rule({
    name = "waybar-blur",
    match = { namespace = "waybar" },
    blur = true,
    ignore_alpha = 0.8,
})
hl.layer_rule({
    name = "hyprcore-bar-fill",
    match = { namespace = "hyprcore-bar-fill" },
    no_anim = true,
})
hl.layer_rule({
    name = "hyprcore-popover",
    match = { namespace = "hyprcore-popover" },
    no_anim = true,
    blur = true,
    ignore_alpha = 0.8,
})
hl.layer_rule({
    name = "hyprcore-settings",
    match = { namespace = "hyprcore-settings" },
    animation = "slide top",
    blur = false,
})
hl.layer_rule({
    name = "hyprpaper",
    match = { namespace = "hyprpaper" },
    no_anim = true,
})


local mod = "SUPER"

hl.bind(mod .. " + Return", hl.dsp.exec_cmd("hyprcore-launch gtk-term"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("hyprcore-launch gtk-files"))
hl.bind(mod .. " + T", hl.dsp.exec_cmd("hyprcore-launch gtk-term"))
hl.bind(mod .. " + G", hl.dsp.exec_cmd("hyprcore-launch env GSK_RENDERER=ngl gtk-edit"))
hl.bind(mod .. " + comma", hl.dsp.exec_cmd("hyprcore-launch hypr-settings"))

hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd("hyprcore-launch gtk-term"))
hl.bind("CTRL + ALT + X", hl.dsp.exec_cmd("hyprcore-launch gtk-calc"))
hl.bind("CTRL + ALT + N", hl.dsp.exec_cmd("hyprcore-launch gtk-files ~"))
hl.bind("CTRL + ALT + SHIFT + N", hl.dsp.exec_cmd("hyprcore-launch env GSK_RENDERER=ngl gtk-edit"))
hl.bind("CTRL + ALT + equal", hl.dsp.exec_cmd("hyprcore-launch gtk-colors"))
hl.bind("CTRL + ALT + up", hl.dsp.exec_cmd("hyprcore-volume +5"))
hl.bind("CTRL + ALT + down", hl.dsp.exec_cmd("hyprcore-volume -5"))

hl.bind("SUPER + Super_L", hl.dsp.exec_cmd("hyprcore-fuzzel"), { release = true })
hl.bind("SUPER + Super_R", hl.dsp.exec_cmd("hyprcore-fuzzel"), { release = true })
hl.bind("Escape", hl.dsp.exec_cmd("hyprcore-escape"))
hl.bind("CTRL + SUPER + Super_L", hl.dsp.exec_cmd("hyprcore-fuzzel"), { release = true })
hl.bind("CTRL + SUPER + Super_R", hl.dsp.exec_cmd("hyprcore-fuzzel"), { release = true })
hl.bind(mod .. " + A", hl.dsp.exec_cmd("hyprcore-fuzzel"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("makoctl restore"))
hl.bind(mod .. " + M", hl.dsp.exec_cmd("makoctl dismiss --all"))
hl.bind(mod .. " + L", hl.dsp.exec_cmd("dm-tool lock"))
hl.bind("ALT + F2", hl.dsp.exec_cmd("hyprcore-fuzzel"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("hyprcore-launch nwg-bar"))

hl.bind(mod .. " + Tab", hl.dsp.window.cycle_next({ next = true }))
hl.bind(mod .. " + Tab", hl.dsp.window.bring_to_top())
hl.bind(mod .. " + SHIFT + Tab", hl.dsp.window.cycle_next({ prev = true }))
hl.bind(mod .. " + grave", hl.dsp.window.cycle_next({ next = true }))
hl.bind("ALT + Tab", hl.dsp.exec_cmd("hyprcore-window-switch"))
hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("hyprcore-window-switch --reverse"))
hl.bind("ALT + Alt_L", hl.dsp.exec_cmd("hyprcore-window-switch --commit"), { release = true })
hl.bind("ALT + Alt_R", hl.dsp.exec_cmd("hyprcore-window-switch --commit"), { release = true })
hl.bind("ALT + Escape", hl.dsp.window.cycle_next({ next = true }))
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind("CTRL + Q", hl.dsp.window.close())
hl.bind(mod .. " + Up", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mod .. " + Down", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + Left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + Right", hl.dsp.window.move({ direction = "r" }))
hl.bind("ALT + F7", hl.dsp.submap("gnomemove"))
hl.define_submap("gnomemove", function()
    hl.bind("left", hl.dsp.window.move({ direction = "l" }), { repeating = true })
    hl.bind("right", hl.dsp.window.move({ direction = "r" }), { repeating = true })
    hl.bind("up", hl.dsp.window.move({ direction = "u" }), { repeating = true })
    hl.bind("down", hl.dsp.window.move({ direction = "d" }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)

hl.bind("ALT + F8", hl.dsp.submap("gnomeresize"))
hl.define_submap("gnomeresize", function()
    hl.bind("left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
    hl.bind("right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
    hl.bind("up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
    hl.bind("down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
    hl.bind("Return", hl.dsp.submap("reset"))
end)

hl.bind("ALT + Space", hl.dsp.exec_cmd("hyprcore-launch hypr-settings"))

hl.bind(mod .. " + CTRL + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + CTRL + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + CTRL + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + CTRL + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mod .. " + page_down", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mod .. " + page_up", hl.dsp.focus({ workspace = -1 }))
hl.bind("CTRL + ALT + left", hl.dsp.focus({ workspace = -1 }))
hl.bind("CTRL + ALT + right", hl.dsp.focus({ workspace = "+1" }))
hl.bind("CTRL + ALT + SHIFT + left", hl.dsp.window.move({ workspace = -1 }))
hl.bind("CTRL + ALT + SHIFT + right", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(mod .. " + SHIFT + page_down", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(mod .. " + SHIFT + page_up", hl.dsp.window.move({ workspace = -1 }))
hl.bind(mod .. " + SHIFT + left", hl.dsp.window.move({ monitor = "l" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ monitor = "r" }))

hl.workspace_rule({
    workspace = "1",
    persistent = true,
})

hl.workspace_rule({
    workspace = "2",
    persistent = true,
})

hl.workspace_rule({
    workspace = "3",
    persistent = true,
})

hl.workspace_rule({
    workspace = "4",
    persistent = true,
})

hl.bind(mod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

hl.bind("Print", hl.dsp.exec_cmd("hyprcore-screenshot"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprcore-screenshot"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("hyprcore-screenshot region-file"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("hyprcore-screenshot full"))
hl.bind("CTRL + ALT + SHIFT + R", hl.dsp.exec_cmd("sh -c 'if pgrep -x wf-recorder >/dev/null; then pkill -x wf-recorder; notify-send \"Recording\" \"Stopped\"; elif command -v wf-recorder >/dev/null; then mkdir -p \"$HOME/Videos\" && wf-recorder -f \"$HOME/Videos/Recording-$(date +%Y-%m-%d_%H-%M-%S).mp4\" & notify-send \"Recording\" \"Started\"; else notify-send \"Recording\" \"Install wf-recorder to enable\"; fi'"))

hl.bind("ALT + " .. mod .. " + S", hl.dsp.exec_cmd("sh -c 'command -v orca >/dev/null && (pgrep -x orca >/dev/null && pkill -x orca || orca &) || notify-send \"Screen reader\" \"Install orca to enable\"'"))
hl.bind("ALT + " .. mod .. " + 8", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/cursor-zoom.sh reset"))
hl.bind(mod .. " + ALT + equal", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/cursor-zoom.sh in"))
hl.bind(mod .. " + ALT + minus", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/cursor-zoom.sh out"))

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("hyprcore-volume +5"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("hyprcore-volume -5"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("hyprcore-volume mute-toggle"))

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize())
hl.bind("mouse:273", hl.dsp.exec_cmd("hyprcore-desktop-rmb"), { non_consuming = true })



hl.window_rule({
    match = {
        class = "^(org\\.hyprcore\\.btop)$",
    },
    float = true,
})

hl.window_rule({
    match = {
        class = "^(org\\.hyprcore\\.cava)$",
    },
    float = true,
})

hl.window_rule({
    match = {
        class = "^(cava)$",
    },
    float = true,
})

hl.window_rule({
    match = {
        class = "^(xfce4-power-manager-settings)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    match = {
        class = "^(xarchiver)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    match = {
        class = "^(galculator)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    match = {
        class = "^(org\\.hyprcore\\.GtkCalc)$",
    },
    float = true,
    center = true,
    size = "360 520",
})

hl.window_rule({
    match = {
        class = "^(org\\.linuxos\\.GtkCalc)$",
    },
    float = true,
    center = true,
    size = "360 520",
})

hl.window_rule({
    match = {
        class = "^(org\\.hyprcore\\.GtkThemeEditor)$",
    },
    float = true,
})

hl.window_rule({
    match = {
        class = "^(org\\.linuxos\\.GtkMeld|org\\.hyprcore\\.GtkMeld|org\\.gnome\\.Meld)$",
    },
    float = true,
    fullscreen_state = "2 2",
})

hl.window_rule({
    match = {
        class = "^(org\\.hyprcore\\.GtkThemeEditor)$",
    },
    center = true,
    size = "960 720",
})

hl.window_rule({
    match = {
        class = "^(zenity)$",
    },
    float = true,
    center = true,
    border_size = 0,
})

hl.window_rule({
    match = {
        class = "^(polkit-mate-authentication-agent-1)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    match = {
        class = "^(Polkit-mate-authentication-agent-1)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    match = {
        class = "^(polkit-gnome-authentication-agent-1)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    match = {
        title = "^(Authenticate)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    match = {
        class = "^(hyprcore-choice)$",
    },
    float = true,
    border_size = 0,
    rounding = 20,
})

hl.window_rule({
    match = {
        class = "^(hyprcore-calendar)$",
    },
    float = true,
    border_size = 0,
    rounding = 20,
})

hl.window_rule({
    match = {
        class = "^(xdg-desktop-portal-gtk)$",
    },
    float = true,
    center = true,
    size = "780 560",
    border_size = 0,
})

hl.window_rule({
    match = {
        class = "^(io\\.calamares\\.calamares)$",
    },
    float = true,
    center = true,
    size = "920 620",
})

hl.window_rule({
    match = {
        float = true,
    },
    opacity = "0.97 override 0.97 override",
})

hl.window_rule({
    match = {
        float = true,
        xwayland = true,
    },
    force_rgbx = true,
})

hl.window_rule({
    match = {
        float = true,
    },
    no_blur = true,
})

hl.window_rule({
    match = {
        xdg_tag = "popup",
    },
    border_size = 0,
    rounding = 0,
    no_shadow = true,
})

hl.window_rule({
    match = {
        xdg_tag = "menu",
    },
    border_size = 0,
})

hl.window_rule({
    match = {
        xdg_tag = "dropdown",
    },
    border_size = 0,
})

hl.window_rule({
    match = {
        xdg_tag = "tooltip",
    },
    border_size = 0,
})

hl.window_rule({
    match = {
        modal = true,
    },
    border_size = 0,
})

hl.window_rule({
    match = {
        title = "[Pp]icture[-\\\\s]?[Ii]n[-\\\\s]?[Pp]icture",
    },
    float = true,
    pin = true,
    keep_aspect_ratio = true,
    size = "25% 25%",
    move = "73% 72%",
})

hl.window_rule({
    match = {
        title = ".*is sharing (your screen|a window).*",
    },
    float = true,
    pin = true,
})

hl.window_rule({
    match = {
        title = "^(Open File)",
    },
    float = true,
    center = true,
})

hl.window_rule({
    match = {
        title = "^(Save As)",
    },
    float = true,
    center = true,
})

hl.window_rule({
    match = {
        title = "^(Open Folder)",
    },
    float = true,
    center = true,
})

-- Personalize extras (default is empty; overlay may replace binds-personal.lua)
require("binds-personal")

hl.config({
    xwayland = {
        enabled = true,
    },
    -- Personalize overlay (empty in default/). Named outputs must come after the fallback.
    general = {
        gaps_in = 12,
        gaps_out = 18,
        border_size = 3,
        col = {
            active_border = "rgba(505050aa)",
            inactive_border = "rgba(2a2a2a88)",
        },
        layout = "dwindle",
    },
    dwindle = {
        preserve_split = true,
    },
    decoration = {
        rounding = 8,
        -- (1.0 → blank/black thumbnails on Hyprland 0.55). Keep <1.0 even for floats.
        active_opacity = 0.97,
        inactive_opacity = 0.97,
        blur = {
            enabled = true,
            size = 6,
            passes = 2,
            new_optimizations = true,
            -- Don't blur behind opaque window surfaces (stops “bleed through” look)
            ignore_opacity = false,
            xray = false,
        },
        shadow = {
            enabled = true,
            range = 12,
            render_power = 2,
            -- Soft grey shadow (was near-opaque black)
            color = "rgba(00000055)",
        },
    },
    -- ~2× default speed (global default is 8ds; lower = faster)
    animations = {
        enabled = true,
        -- Layer surfaces (fuzzel / notifications); per-layer style via layerrule
    },
    -- Fuzzel (namespace "launcher") slides up from the bottom; keep bars/wallpaper still.
    misc = {
        background_color = "rgb(272822)",
        -- Allow Super alone (application launcher) without eating other Super binds
        enable_swallow = false,
        disable_hyprland_logo = true,
        disable_hyprland_guiutils_check = true,
        -- gtk-theme writes this file; auto-reload would re-apply monitor= and shuffle outputs.
        disable_autoreload = true,
    },
    -- Quiet Hyprland’s bottom “tips” / donation / update nags
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
    debug = {
        suppress_errors = true,
    },
    input = {
        kb_layout = "us,us",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
        },
    },
    -- --- hyprCore daily apps (non-conflicting) ---
    -- --- Extra shortcuts (CTRL+ALT, native binds) ---
    -- =============================================================================
    -- 1. System & Navigation (GNOME)
    -- =============================================================================
    -- Super (release alone) → application launcher (fuzzel)
    -- Escape dismisses fuzzel; else passes through to the focused window
    -- Ctrl+Super → Applications (Fuzzel; release Super while Ctrl held)
    -- Modmask must include both CTRL and SUPER (Hyprland "only modkeys" rule)
    -- Super+A → Applications
    -- Super+V / Super+M → notification history / dismiss
    -- Super+L → lock
    -- Alt+F2 → run command
    -- Ctrl+Alt+Del → session / power menu
    -- Super+Space → right-side program panel
    -- =============================================================================
    -- 2. Window switcher & management (GNOME)
    -- =============================================================================
    -- Super + ` (grave) → same-app style cycle (best-effort: next window)
    -- Windows-style MRU: one Alt+Tab toggles the last two; extra Tab while Alt is
    -- held walks further down recently-used windows on the focused monitor.
    -- Maximize / restore
    -- Snap left / right (move window in layout)
    -- Alt+F7 move mode / Alt+F8 resize mode
    -- Alt+Space → Settings (hypr-settings)
    -- Focus (Hyprland: Super+Ctrl+arrows — Super+arrows are snap)
    -- =============================================================================
    -- 3. Workspaces & monitors (GNOME)
    -- =============================================================================
    -- Ctrl+Alt+←/→ → previous / next desktop
    -- Ctrl+Shift+Alt+←/→ → take active window to previous / next desktop
    -- Always keep four desktops as a stable base set.
    -- Higher desks are created on demand (showNewWorkspace + scroll); empty ones may
    -- be GC'd by Hyprland unless they have windows.
    -- Numbered workspaces
    -- =============================================================================
    -- 4. Screenshots & screen recording (GNOME)
    -- =============================================================================
    -- Print / Super+Shift+S: region → ~/Pictures + clipboard + gtk-image (Esc cancels)
    -- Shift+Print: full screen → ~/Pictures + clipboard + gtk-image
    -- Alt+Print: region → ~/Pictures + gtk-image (no clipboard)
    -- =============================================================================
    -- 5. Accessibility (GNOME) — best-effort
    -- =============================================================================
    -- =============================================================================
    -- Media keys
    -- =============================================================================
    -- Right-click empty desktop → wallpaper picker (bindn: apps still receive RMB)
    -- Float some utilities (dialogs stay centered, not stretched edge-to-edge)
    -- Meld diffs need the whole monitor, not the area under the bar.
    -- Calamares: keep branding windowSize (avoid nearly-fullscreen float)
    -- RGBX is an XWayland workaround. On Wayland it turns Chrome/GTK menus into
    -- huge black frames (alpha stripped). Keep it off for native floats.
    -- Chrome/Chromium menus (xdg-popups). Match xdg_tag, not class+float, so a
    -- personalize overlay that floats windows does not strip the main browser chrome.
    -- Picture-in-Picture / screen-share (dots-hyprland rules; no color changes)
    -- Personalize extras (default is empty; overlay may replace this file)
})

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP GSK_RENDERER GTK_THEME QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME GTK_ICON_THEME XDG_ICON_THEME SAL_USE_VCLPLUGIN XCURSOR_SIZE")
    hl.exec_cmd("/usr/share/hyprcore/hyprcore-hyprland-session-start.sh")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

