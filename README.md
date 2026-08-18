# Hyprism

**One palette, the whole spectrum.**

Hyprism is a single-file theming command center for [Hyprland](https://hyprland.org/).
Pick one palette and it repaints your whole desktop — **Hyprland**, **Waybar**,
**Hyprlock**, **Dunst**, and (optionally) **Kitty** and **Rofi** — from one place,
driven by a central state file. No config files to hand-edit, an interactive
[`fzf`](https://github.com/junegunn/fzf) menu with live previews, and a bilingual
interface (English / Português).

> Prism metaphor: one source of light → the full spectrum across every app.

---

## Features

- 🎨 **27 built-in palettes** (generated from Kitty themes) + a `terminal-red` login theme. Light and dark palettes both supported — colors are never hardcoded.
- 🖼️ **Fast wallpaper picker** with in-terminal Kitty-graphics previews, cached thumbnails, live apply, and keybindings (shuffle, open folder, copy path). Handles filenames with spaces.
- 📊 **Customizable Waybar** — three visual styles you switch at will:
  - `flat` — attached, minimal (default)
  - `pills` — floating, one rounded chip per module
  - `segmented` — attached, rounded module clusters
  - plus fine tuning: outer margin, corner radius, gap between modules.
- 🔒 **Hyprlock**, 🔔 **Dunst**, ✨ effects (blur / shadow / opacity / dim), animations, window behavior, workspaces, input (keyboard/mouse/touchpad), cursor, borders & accent — all from the menu, applied live.
- 🌍 **Bilingual UI** — English by default, switch with `hyprism lang pt`. The whole interface translates; command keywords and stored values never do.
- 🎛️ Everything is a knob in `~/.config/hypr/themes/.state`; the generators write `colors.lua` / `look.lua` that `hyprland.lua` reads. **Customizing never rewrites your Hyprland config.**

---

## Screenshots

<!-- Add your own screenshots here -->
| Menu | Wallpaper picker | Bar styles |
|------|------------------|------------|
| _todo_ | _todo_ | _todo_ |

---

## Install

```sh
git clone https://github.com/<you>/hyprism.git
cd hyprism
./install.sh
```

`install.sh` symlinks `bin/hyprism` and `bin/set-wallpaper` into `~/.local/bin`
(and keeps a `hyprtheme` alias for muscle memory), then copies the default
palettes into `~/.config/hypr/themes/palettes/` if they are missing. Make sure
`~/.local/bin` is on your `PATH`.

### Dependencies

**Required:** `bash` (4+), `fzf`, `imagemagick` (`magick`), and the Hyprland stack
you're theming: `hyprland`, `hyprlock`, `hypridle`, `waybar`, `dunst`, plus
`swaybg` for wallpapers.

**Recommended:** `kitty` (for in-terminal image previews via `kitten icat`).

**Optional:** `mpvpaper` (animated wallpapers), `ffmpeg` (animated thumbnails),
`chafa` (image preview fallback outside Kitty), `rofi` + `rofitheme`,
`kittytheme`, `notify-send`, `wl-clipboard`/`xclip` (copy wallpaper path).

---

## Usage

```
hyprism                      open the full menu
hyprism <palette>            apply a palette directly
hyprism -l                   list palettes
hyprism -r                   random palette
hyprism -g                   (re)generate palettes from Kitty themes

hyprism palette | wallpaper | appearance | effects | animations
hyprism bar | style | modules | windows | workspaces
hyprism input | cursor | lock | notifications | font
hyprism borders | preset | config | sync | binds

hyprism style [flat|pills|segmented]     switch the bar look
hyprism effects [performance|subtle|glass|focus]
hyprism animations [off|fast|balanced|smooth|elastic]
hyprism lang [en|pt]                     switch the interface language
hyprism sync                             reapply the global theme to Kitty + Rofi
```

Every subcommand also accepts its Portuguese alias (`paleta`, `barra`, `estilo`,
`idioma`, …) for backward compatibility.

---

## How it works

```
palettes/*.env  ─┐
                 ├─►  .state (your choices)  ──►  generators  ──►  colors.lua
kitty themes  ───┘                                              └─►  look.lua
                                                                       │
                                        hyprland.lua reads both ◄──────┘
                                        + Waybar style.css, hyprlock.conf, dunstrc
```

- **Colors** come only from the active palette's variables (`bg`, `fg`, `accent`,
  `sel`, …), so every style works on light and dark themes alike.
- **State** lives in `~/.config/hypr/themes/.state`. Switching palette resets manual
  accent/border tweaks; the bar style, language and other knobs are preserved.
- `NO_COLOR` is honored for the tool's own output.

---

## License

MIT — see [LICENSE](LICENSE).
