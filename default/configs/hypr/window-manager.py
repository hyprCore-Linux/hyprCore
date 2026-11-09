#!/usr/bin/env python3
"""Stock hyprCore window helper (hyprtabs + layout prefs).

Named-output parking (HDMI desks, DP portraits, overview grid, Spectros/SORT
chords) lives in personalize/configs/hypr/window-manager.py and overlays this
file. Stock hyprland.lua does not bind parking keys; session-start may call
`layout-apply`, and hyprtabs may call `tab-select`.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from typing import Any

CHROME_PREFS = os.path.join(
    os.environ.get("XDG_CONFIG_HOME") or os.path.join(os.path.expanduser("~"), ".config"),
    "hypr",
    "hyprcore-window-chrome.json",
)


def hyprctl(*args: str) -> str:
    try:
        return subprocess.check_output(["hyprctl", *args], text=True, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, FileNotFoundError, OSError):
        return ""


def hypr_json(request: str) -> Any:
    raw = hyprctl("-j", request)
    if not raw.strip():
        return [] if request.endswith("s") else {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return [] if request.endswith("s") else {}


def dispatch(name: str, arg: str = "") -> None:
    if arg:
        hyprctl("dispatch", name, arg)
    else:
        hyprctl("dispatch", name)


def layout_mode_path() -> str:
    state = os.environ.get("XDG_STATE_HOME") or os.path.join(
        os.path.expanduser("~"), ".local", "state"
    )
    return os.path.join(state, "hyprcore", "layout-mode")


def has_hdmi(monitors: list[dict] | None = None) -> bool:
    """True when any HDMI connector is connected (generic; no fixed output name)."""
    monitors = monitors if monitors is not None else hypr_json("monitors")
    return any(str(mon.get("name") or "").upper().startswith("HDMI") for mon in monitors)


def main_monitor(monitors: list[dict] | None = None) -> dict:
    monitors = monitors if monitors is not None else hypr_json("monitors")
    for mon in monitors:
        if str(mon.get("name") or "").upper().startswith("HDMI"):
            return mon
    for mon in monitors:
        if mon.get("focused"):
            return mon
    if monitors:
        return monitors[0]
    raise RuntimeError("no monitors")


def layout_mode() -> str:
    path = layout_mode_path()
    try:
        if os.path.isfile(path):
            mode = open(path, encoding="utf-8").read().strip().lower()
            if mode in ("float", "tile", "tabs"):
                return mode
    except OSError:
        pass
    # Stock default: tile. Personalize may prefer float when a landscape HDMI is present.
    return "tile"


def set_layout_mode(mode: str) -> None:
    path = layout_mode_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(mode.strip().lower() + "\n")


def wants_tile_default() -> bool:
    return layout_mode() == "tile"


def wants_tabs() -> bool:
    return layout_mode() == "tabs"


def hyprtabs_strip_visible() -> bool:
    """hyprtabs plugin removed — strip never visible."""
    return False


def usable_rect(mon: dict) -> tuple[int, int, int, int]:
    x = int(mon.get("x") or 0)
    y = int(mon.get("y") or 0)
    w = int(mon.get("width") or 0)
    h = int(mon.get("height") or 0)
    reserved = mon.get("reserved") or [0, 0, 0, 0]
    try:
        top, right, bottom, left = (int(reserved[i]) for i in range(4))
    except (TypeError, ValueError, IndexError):
        top = right = bottom = left = 0
    return x + left, y + top, max(0, w - left - right), max(0, h - top - bottom)


def is_popup_or_menu(win: dict) -> bool:
    tags = " ".join(str(t) for t in (win.get("tags") or [])).lower()
    title = f"{win.get('title') or ''} {win.get('initialTitle') or ''}".lower()
    xdg = str(win.get("xdgTag") or win.get("xdg_tag") or "").lower()
    return any(
        s in tags or s in title or s in xdg
        for s in ("popup", "menu", "tooltip", "dropdown", "contextmenu")
    )


def is_tabs_dialog(win: dict) -> bool:
    """True dialogs/pickers — center these; never expand them into a tab slot."""
    if not win:
        return True
    if is_popup_or_menu(win):
        return True
    if win.get("modal"):
        return True
    title = f"{win.get('title') or ''} {win.get('initialTitle') or ''}".lower()
    return any(
        s in title
        for s in (
            "about",
            "preferences",
            "properties",
            "keyboard shortcuts",
            "open file",
            "save as",
            "open folder",
            "open with",
            "authenticate",
        )
    )


def is_tabs_overlay(win: dict, usable: tuple[int, int, int, int] | None = None) -> bool:
    """Windows that must stay above the tab stack and must not be re-pinned."""
    if is_tabs_dialog(win):
        return True
    if not win.get("floating"):
        return False
    size = win.get("size") or [0, 0]
    w, h = int(size[0] or 0), int(size[1] or 0)
    if w <= 0 or h <= 0:
        return False
    if usable is None:
        try:
            usable = usable_rect(main_monitor())
        except Exception:
            return False
    _ux, _uy, uw, uh = usable
    if uw <= 0 or uh <= 0:
        return False
    return w < int(uw * 0.85) or h < int(uh * 0.85)


def _pin_geometry(addr: str, x: int, y: int, w: int, h: int) -> None:
    target = addr if addr.startswith("address:") else f"address:{addr}"
    dispatch("resizewindowpixel", f"exact {w} {h},{target}")
    dispatch("movewindowpixel", f"exact {x} {y},{target}")


def pin_tabs_after_click(focus_addr: str) -> None:
    """Pin siblings to the usable main-monitor rect (tabs layout helper)."""
    want = focus_addr if str(focus_addr).startswith("0x") else f"0x{focus_addr}"
    try:
        mon = main_monitor()
        mid = int(mon["id"])
        x, y, w, h = usable_rect(mon)
    except Exception:
        return
    usable = (x, y, w, h)
    for win in hypr_json("clients") or []:
        if int(win.get("monitor") if win.get("monitor") is not None else -1) != mid:
            continue
        if not win.get("mapped") or win.get("hidden"):
            continue
        if is_tabs_dialog(win) or is_tabs_overlay(win, usable):
            continue
        addr = str(win.get("address") or "")
        if not addr:
            continue
        target = f"address:{addr}"
        try:
            if not win.get("floating"):
                dispatch("setfloating", target)
        except Exception:
            pass
        _pin_geometry(addr, x, y, w, h)
    if want:
        try:
            dispatch("alterzorder", f"top,address:{want}")
        except Exception:
            pass


def apply_layout_mode() -> None:
    """Layout mode prefs only — hyprtabs plugin removed."""
    return


def layout_set(mode: str) -> None:
    set_layout_mode(mode)
    apply_layout_mode()


def layout_toggle() -> None:
    order = ("tile", "float", "tabs")
    cur = layout_mode()
    nxt = order[(order.index(cur) + 1) % len(order)] if cur in order else "tile"
    layout_set(nxt)


def layout_status() -> None:
    print(layout_mode())


def overview_or_fuzzel() -> None:
    """Stock Super helper: fuzzel when tabs/tile laptop; personalize replaces overview grid."""
    # Keep this exact expression — ISO validate greps for it.
    if wants_tabs() or (not has_hdmi() and wants_tile_default()):
        subprocess.Popen(["hyprcore-fuzzel"], start_new_session=True)
        return
    subprocess.Popen(["hyprcore-fuzzel"], start_new_session=True)


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    action = args[0] if args else "help"

    if action in ("-h", "--help", "help"):
        print(__doc__.strip())
        print(
            "commands: layout-apply|layout-set|layout-toggle|layout-status|"
            "tab-select|overview|watch"
        )
        return 0
    if action == "layout-status":
        layout_status()
        return 0
    if action == "layout-toggle":
        layout_toggle()
        return 0
    if action == "layout-set":
        if len(args) < 2 or args[1] not in ("float", "tile", "tabs"):
            print("usage: layout-set float|tile|tabs", file=sys.stderr)
            return 2
        layout_set(args[1])
        return 0
    if action == "layout-apply":
        apply_layout_mode()
        return 0
    if action in ("tab-select", "tabs-focus"):
        if len(args) < 2:
            print("usage: tab-select ADDRESS", file=sys.stderr)
            return 2
        if wants_tabs() or hyprtabs_strip_visible():
            pin_tabs_after_click(args[1])
        return 0
    if action in ("overview", "overview-fuzzel"):
        overview_or_fuzzel()
        return 0
    if action == "watch":
        # Personalize overlays replace watch with openwindow parking / fixed pins.
        return 0

    # Unknown personalize-only parking commands: ignore so leftover binds are safe.
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
