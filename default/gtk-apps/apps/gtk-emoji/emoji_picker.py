#!/usr/bin/env python3
"""GTK4 emoji picker. Search uses the same index as GTK Edit's Ctrl+; chooser."""
from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    import gi

    gi.require_version("Gtk", "4.0")
    from gi.repository import Gdk, Gio, GLib, Gtk, Pango
except ImportError:
    print("Error: GTK not available. Install python3-gi and gir1.2-gtk-4.0.")
    sys.exit(1)


# Group ids in /org/gtk/libgtk/emoji/en.data (the Ctrl+; chooser index).
CATEGORIES = (
    ("recent", "Recent"),
    (0, "Smileys"),
    (1, "People"),
    (3, "Nature"),
    (4, "Food"),
    (5, "Travel"),
    (6, "Activities"),
    (7, "Objects"),
    (8, "Symbols"),
    (9, "Flags"),
)

COLUMNS = 14
WINDOW_WIDTH = 980
WINDOW_HEIGHT = 680


def load_gtk_emoji_index():
    """Same records GtkEmojiChooser searches on Ctrl+;."""
    Gtk.init()
    raw = Gio.resources_lookup_data("/org/gtk/libgtk/emoji/en.data", 0).get_data()
    variant = GLib.Variant.new_from_bytes(
        GLib.VariantType.new("a(aussasasu)"), GLib.Bytes.new(raw), False
    )
    items = []
    for i in range(variant.n_children()):
        item = variant.get_child_value(i)
        codes = item.get_child_value(0)
        chars = "".join(
            chr(codes.get_child_value(j).get_uint32()) for j in range(codes.n_children())
        )
        name = item.get_child_value(1).get_string()
        words = item.get_child_value(3)
        keywords = [words.get_child_value(j).get_string() for j in range(words.n_children())]
        group = item.get_child_value(5).get_uint32()
        items.append(
            {
                "char": chars,
                "name": name,
                "keywords": keywords,
                "group": group,
                "search": " ".join([name, *keywords]).lower(),
            }
        )
    return items


class EmojiPickerWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.set_title("Emoji Picker")
        self.set_default_size(WINDOW_WIDTH, WINDOW_HEIGHT)
        self.set_resizable(False)
        self._emojis = load_gtk_emoji_index()
        self._category = 0
        self._search_id = 0
        self._buttons = []

        self._css()
        try:
            from gtk_theme import attach_profile_menu

            header = Gtk.HeaderBar()
            self.set_titlebar(header)
            attach_profile_menu(
                self,
                header,
                about_name="GTK Emoji",
                about_comments="Pick and copy emoji to the clipboard.",
            )
        except Exception as exc:
            print(f"gtk-theme menu unavailable: {exc}")

        self._build()
        self._show_category(0)
        self.present()
        self.search.grab_focus()

    def _css(self):
        css = Gtk.CssProvider()
        css.load_from_data(
            """
            .emoji-button {
                background: transparent;
                border: none;
                border-radius: 14px;
                padding: 2px;
                min-width: 0;
                min-height: 52px;
            }
            .emoji-button label {
                font-family: "Noto Color Emoji";
                font-size: 30px;
            }
            .emoji-button:hover {
                background: alpha(@theme_fg_color, 0.10);
            }
            .emoji-button:active {
                background: alpha(@theme_fg_color, 0.18);
            }
            .emoji-cat {
                border-radius: 999px;
                padding: 2px 12px;
                min-height: 32px;
            }
            .emoji-status {
                color: alpha(@theme_fg_color, 0.62);
                font-size: 13px;
            }
            .emoji-search {
                min-height: 40px;
                font-size: 15px;
            }
            """.encode()
        )
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

    def _build(self):
        column = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        column.set_margin_top(18)
        column.set_margin_bottom(14)
        column.set_margin_start(20)
        column.set_margin_end(20)
        column.set_halign(Gtk.Align.FILL)
        column.set_hexpand(True)
        column.set_vexpand(True)

        self.search = Gtk.SearchEntry()
        self.search.set_placeholder_text("Search emoji")
        self.search.add_css_class("emoji-search")
        self.search.set_hexpand(True)
        self.search.connect("search-changed", self._on_search_changed)
        column.append(self.search)

        cats = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        cats.set_halign(Gtk.Align.CENTER)
        self._cat_buttons = []
        for key, label in CATEGORIES:
            button = Gtk.ToggleButton(label=label)
            button.add_css_class("emoji-cat")
            button.connect("toggled", self._on_category, key)
            cats.append(button)
            self._cat_buttons.append(button)
        self._cat_buttons[1].set_active(True)
        column.append(cats)

        self.grid = Gtk.Grid(column_spacing=4, row_spacing=4)
        self.grid.set_hexpand(True)
        self.grid.set_halign(Gtk.Align.FILL)
        self.grid.set_valign(Gtk.Align.START)
        self.grid.set_column_homogeneous(True)

        scroll = Gtk.ScrolledWindow()
        scroll.set_child(self.grid)
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_propagate_natural_width(False)
        column.append(scroll)

        self.status = Gtk.Label(label="Click an emoji to copy it")
        self.status.add_css_class("emoji-status")
        self.status.set_halign(Gtk.Align.CENTER)
        column.append(self.status)

        self.set_child(column)

    def _on_category(self, button, key):
        if not button.get_active():
            return
        for other in self._cat_buttons:
            if other is not button:
                other.set_active(False)
        self._category = key
        if not self.search.get_text().strip():
            self._show_category(key)

    def _on_search_changed(self, entry):
        if self._search_id:
            GLib.source_remove(self._search_id)
        text = entry.get_text()
        self._search_id = GLib.timeout_add(80, self._apply_search, text)

    def _apply_search(self, text):
        self._search_id = 0
        query = text.strip().lower()
        if not query:
            self._show_category(self._category)
            return False
        words = query.split()
        matches = []
        for item in self._emojis:
            hay = item["search"]
            if all(word in hay or word in item["char"] for word in words):
                matches.append(item)
        self._fill(matches)
        if matches:
            self.status.set_text(f"{len(matches)} matches")
        else:
            self.status.set_text(f"No emoji for “{text.strip()}”")
        return False

    def _show_category(self, key):
        if key == "recent":
            chars = set(self._load_recent())
            items = [item for item in self._emojis if item["char"] in chars]
            order = {char: i for i, char in enumerate(self._load_recent())}
            items.sort(key=lambda item: order.get(item["char"], 999))
            self._fill(items)
            self.status.set_text("Recent" if items else "No recent emoji yet")
            return
        items = [item for item in self._emojis if item["group"] == key]
        self._fill(items)
        self.status.set_text("Click an emoji to copy it")

    def _fill(self, items):
        for child in list(self.grid):
            self.grid.remove(child)
        if not items:
            label = Gtk.Label(label="Nothing here")
            label.add_css_class("emoji-status")
            self.grid.attach(label, 0, 0, 1, 1)
            return
        for index, item in enumerate(items):
            self.grid.attach(
                self._button(item),
                index % COLUMNS,
                index // COLUMNS,
                1,
                1,
            )

    def _button(self, item):
        label = Gtk.Label(label=item["char"])
        attrs = Pango.AttrList()
        attrs.insert(Pango.attr_family_new("Noto Color Emoji"))
        attrs.insert(Pango.attr_size_new(30 * Pango.SCALE))
        label.set_attributes(attrs)
        button = Gtk.Button()
        button.set_child(label)
        button.set_hexpand(True)
        button.add_css_class("emoji-button")
        button.set_tooltip_text(item["name"])
        button.connect("clicked", self._on_click, item)
        return button

    def _on_click(self, _button, item):
        char = item["char"]
        self.status.set_text(f"Copying {char}…")
        GLib.timeout_add(10, self._copy_async, char, item["name"])

    def _copy_async(self, char, name):
        if self._copy(char):
            self._remember(char)
            self.status.set_text(f"{char}  {name} copied")
            if self._category == "recent" and not self.search.get_text().strip():
                self._show_category("recent")
            GLib.timeout_add_seconds(2, self._reset_status)
        else:
            self.status.set_text("Could not copy")
        return False

    def _reset_status(self):
        if not self.search.get_text().strip():
            self.status.set_text("Click an emoji to copy it")
        return False

    def _recent_path(self):
        folder = Path.home() / ".emoji_picker"
        folder.mkdir(exist_ok=True)
        return folder / "recent_emojis.json"

    def _load_recent(self):
        path = self._recent_path()
        if not path.exists():
            return []
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return []
        return data if isinstance(data, list) else []

    def _remember(self, char):
        recent = [item for item in self._load_recent() if item != char]
        recent.insert(0, char)
        self._recent_path().write_text(
            json.dumps(recent[:48], ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    def _copy(self, text):
        try:
            self.get_clipboard().set(text)
        except Exception as exc:
            print(f"clipboard: {exc}")
            return False
        return True


def main():
    app = Gtk.Application(application_id="org.hyprcore.GtkEmoji")

    def on_activate(application):
        window = EmojiPickerWindow(application)
        window.connect("close-request", lambda _w: application.quit())

    app.connect("activate", on_activate)
    app.run(None)


if __name__ == "__main__":
    main()
