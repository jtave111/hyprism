# Hyprism

**One palette → the whole desktop.** Hyprism turns a bare Hyprland install on Arch Linux into a complete, coherent desktop — bar, lock screen, notifications, launcher, terminal, right-click menu and a *Windows-Settings-style* system panel — all driven from one retro terminal UI, in English or Portuguese.

```
╔═  HYPRISM  ══════════════════════════════════════════════════════════════════════╗
║     palette blackarch   bar pills   language EN    ┌──────────── details ──────────┐ ║
║ ┌──────────────── search ────────────────┐         │ Control the compositor, the   │ ║
║ │ hyprism:/ $                      12/12 │         │ windows and the whole desktop.│ ║
║ └────────────────────────────────────────┘         │ ── current state ──────────── │ ║
║ ┌──────────────── Hyprism ───────────────┐         │  HYPRLAND                     │ ║
║ │   Search any setting                   │         │   palette ........ blackarch  │ ║
║ │ ▶ Hyprland and Waybar                  │         │   border ......... 1px · 4px  │ ║
║ │   System settings                      │         │   animations ..... smooth     │ ║
║ │   Rofi Launcher                        │         │   waybar ......... pills · top│ ║
║ │   Kitty and Shell                      │         │   notifications .. top-right  │ ║
║ │   Manage look · Sync · Random look     │         └───────────────────────────────┘ ║
║ └────────────────────────────────────────┘                                            ║
║     ENTER open   ESC back   ↑↓ move   type filter                                     ║
╚═══════════════════════════════════════════════════════════════════════════════════════╝
```

## What you get

| | |
|---|---|
| **Hyprism center** (`visualconf`, `SUPER+H`) | One place for every look setting: palette, wallpaper (live preview), borders, gaps, blur, animations, bar, modules, lock screen, notifications, cursor, presets. |
| **System settings** (`hyprism-settings`, `SUPER+,`) | Like Windows Settings, in the terminal: **display resolution / refresh rate / scale / position / rotation / VRR** (with auto-revert), sound devices, Wi-Fi, Bluetooth, power profile & idle/sleep timers, keyboard & mouse, time zone, default apps, startup apps, storage cleanup, updates, about. |
| **27 palettes, 12 presets** | Nord, Catppuccin (4), Gruvbox, Tokyo Night, Rosé Pine, Dracula, Everforest, Kanagawa, Solarized, Matrix… and ready-made looks: *glass*, *tiling-minimal*, *retro-terminal*, *floating-desktop*, *performance*, *cyberpunk-neon*, *light-day*… |
| **Waybar** | Three bar styles (flat, pills, segmented) with margin/radius/gap tuning; every module toggleable; colors always follow the palette (light palettes included). |
| **Lock screen** | hyprlock generated from the palette: background (wallpaper, image or solid color), clock size/color/12-24h, frame, avatar, message, password field style/width/position. |
| **Login screen** | Pick any installed SDDM theme with thumbnails, applied through a polkit prompt. |
| **Right-click menu** | Native GTK menu on the empty desktop: applications by category, terminals, browsers, Hyprism, System settings (BlackArch tools too, when installed). |
| **Quick menu** (`SUPER+I`) | Rofi menu for network, sound, Bluetooth, displays and GUI settings apps. |
| **Power menu** (`SUPER+ESC`) | Lock, log out, suspend, reboot, power off (with confirmation). |
| **Bilingual** | Every screen follows `hyprism lang en|pt`, switchable live. |

## Install

Requirements: **Arch Linux** (or derivative) with **Hyprland ≥ 0.56 (Lua config)**. The installer pulls the rest with pacman.

```bash
git clone https://github.com/jtave111/hyprism.git ~/dev/hyprism
cd ~/dev/hyprism
./install.sh            # pick components, review, confirm
```

| Option | Effect |
|---|---|
| `--yes` | Recommended components, no questions (never overwrites your own `hyprland.lua`) |
| `--components core,hyprland,waybar,…` | Choose exactly what to install |
| `--no-deps` | Skip package installation |
| `--dry-run` | Show every action, change nothing |
| `--lang pt` | Installer and Hyprism in Portuguese |
| `--uninstall` | Remove Hyprism links and restore the configs it replaced |

**Components:** `core` (always) · `hyprland` · `waybar` · `launcher` (rofi) · `terminal` (kitty + starship) · `desktop-menu` · `lock` (hyprlock + hypridle) · `notify` (dunst) · `system` (NetworkManager, PipeWire, BlueZ) · `screenshot` · `extras` (animated wallpapers via mpvpaper, power-profiles-daemon, previews).

**Safe by design.** Any config it replaces is moved to `~/.config/hyprism/backups/install-<date>/` first, and every change is written to a manifest so `--uninstall` can restore it. Programs are symlinked into `~/.local/bin`, so `git pull` updates Hyprism in place. If you already have your own `hyprland.lua`, it is kept and Hyprism's is saved next to it as an example.

## Everyday use

```bash
visualconf                 # the Hyprism center (also: hyprism with no arguments)
hyprism-settings display   # jump straight to a settings section
hyprism preset list        # ready-made looks
hyprism preset glass       # apply one (your keyboard, mouse and language are kept)
hyprism <palette>          # e.g. hyprism tokyo-night
hyprism -r                 # random palette
hyprism style pills        # bar style: flat | pills | segmented
hyprism lang pt            # interface language: en | pt
hyprism sddm               # login screen theme picker
hyprism -h                 # every command
```

### Keybindings (Hyprism's `hyprland.lua`)

| Keys | Action | Keys | Action |
|---|---|---|---|
| `SUPER+SPACE` | App launcher | `SUPER+RETURN` / `SUPER+K` | Terminal |
| `SUPER+H` | Hyprism center | `SUPER+,` | System settings |
| `SUPER+I` | Quick menu | `SUPER+W` | Network |
| `SUPER+ESC` | Power menu | `SUPER+L` | Lock |
| `SUPER+Q` | Close window | `SUPER+SHIFT+Q` | Exit Hyprland |
| `SUPER+F` / `SUPER+M` | Fullscreen / maximize | `SUPER+V` / `SUPER+T` | Float window / whole workspace |
| `SUPER+D` / `SUPER+SHIFT+D` | Minimize / restore all | `SUPER+C` | Center window |
| `SUPER+arrows` | Focus | `SUPER+SHIFT+arrows` | Snap to half screen |
| `SUPER+CTRL+arrows` | Resize | `SUPER+ALT+arrows` | Move |
| `SUPER+1…0` | Workspace | `SUPER+SHIFT+1…0` | Send window |
| `SUPER+[` / `SUPER+]` | Focus monitor | `SUPER+SHIFT+[` / `]` | Send to monitor |
| `SUPER+P` | Region screenshot | `PRINT` / `SUPER+SHIFT+S` | Screen / region to clipboard |
| `SUPER+B` | Restart the bar | `SUPER+scroll` | Resize (`+ALT`: switch workspace) |

## How it fits together

Hyprism never asks you to hand-edit generated files. It owns a small set of files and your `hyprland.lua` only reads them — each with a fallback, so nothing breaks before Hyprism runs.

| File | Written by | Read by |
|---|---|---|
| `~/.config/hypr/themes/.state` | every Hyprism tool (single source of truth) | Hyprism |
| `~/.config/hypr/colors.lua`, `look.lua` | `hyprism render` | `hyprland.lua` |
| `~/.config/hypr/monitors.lua` | `hyprism-settings` → Display | `hyprland.lua` |
| `~/.config/hyprism/autostart` | `hyprism-settings` → Startup apps | `hyprland.lua` |
| `~/.config/hypr/hyprlock.conf`, `hypridle.conf` | `hyprism render`, `hyprism-settings` → Power | hyprlock, hypridle |
| `~/.config/waybar/style.css` + module lines of `config.jsonc` | `hyprism render` | Waybar |
| `~/.config/dunst/dunstrc` | `hyprism render` | dunst |
| `~/.config/rofi/…`, `~/.config/kitty/…` | `rofitheme`, `kittytheme` (synced from the palette) | rofi, kitty |

> **Lua config note.** With `hyprland.lua`, `hyprctl keyword …` and raw `hyprctl dispatch <name>` no longer work. Hyprism applies live changes with `hyprctl eval '<lua>'` (e.g. `hyprctl eval 'hl.monitor({ output = "DP-1", mode = "2560x1440@165" })'`).

### Repository layout

```
bin/        hyprism · visualconf · hyprism-settings · control-center · hyprism-desktop
            hyprism-power · hyprism-launcher · hyprism-open · rofitheme · kittytheme
            wifi-menu · set-wallpaper · restart-waybar
lib/ui.sh   shared retro TUI style (every fzf screen looks like one program)
configs/    hyprland.lua and Waybar templates deployed by the installer
palettes/   27 palettes (.env)        presets/   12 ready-made looks
share/      kitty themes & Starship prompts, rofi layouts (seeded on first run)
```

## Troubleshooting

- **Monitor stuck at 60 Hz** — open `hyprism-settings display` and pick the refresh rate; it is applied live and kept after you confirm. Unlisted monitors already default to their highest refresh rate.
- **NVIDIA** — `hyprland.lua` sets `LIBVA_DRIVER_NAME`, `__GLX_VENDOR_LIBRARY_NAME` and `NVD_BACKEND` automatically when the NVIDIA driver is loaded; install `libva-nvidia-driver` for hardware video decode.
- **A menu shows the wrong language** — `hyprism lang en` (or `pt`); every Hyprism screen reads the same setting.
- **Something looks off after an update** — `visualconf doctor` checks dependencies, files and config syntax without changing anything.

## Português

Hyprism transforma um Hyprland recém-instalado no Arch num desktop completo e coerente, controlado por uma interface de terminal com visual retrô: barra, tela de bloqueio, notificações, launcher, terminal, menu do botão direito e um painel de **Configurações do sistema** no estilo do Windows (resolução/Hz, som, rede, Bluetooth, energia, data e hora, apps padrão, inicialização, armazenamento, atualizações).

```bash
git clone https://github.com/jtave111/hyprism.git ~/dev/hyprism
cd ~/dev/hyprism && ./install.sh --lang pt
```

Tudo que o instalador substitui vai antes para `~/.config/hyprism/backups/`, e `./install.sh --uninstall` restaura. Troque o idioma a qualquer momento com `hyprism lang pt|en`.

## License

MIT — see [LICENSE](LICENSE).
