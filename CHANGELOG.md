# Changelog

## 0.2.0 — 2026-09-23

### Added
- **System settings** (`hyprism-settings`): display resolution/refresh/scale/position/rotation/VRR with auto-revert, sound, Wi-Fi, Bluetooth, power & idle, keyboard & mouse, time zone, default apps, startup apps, storage cleanup, updates, about.
- **Installer rewrite**: component picker, pacman/AUR dependencies, config backups + manifest, `--dry-run`, `--yes`, `--uninstall`, `--lang`.
- Shipped configs: `configs/hypr/hyprland.lua` (reads colors/look/monitors/autostart, auto NVIDIA env) and `configs/waybar/config.jsonc`.
- 12 built-in presets (`hyprism preset list`), merged into your state without touching keyboard, mouse or language.
- `hyprism-power` (session menu), `hyprism-launcher`, `hyprism-open` (opens TUIs in any terminal).
- Lock screen fully customizable: background image/color, clock size/color/format, frame, avatar, message, password field style/width/position.
- SDDM login theme picker with thumbnails.
- `-V/--version`, `VERSION`, this changelog.

### Changed
- New retro console look shared by every screen (`lib/ui.sh`): double frame, inverse selection bar, shell-path prompt, function-key footer, accent picked for contrast.
- Every tool follows `hyprism lang en|pt`, switchable live (visualconf, control-center, rofitheme, kittytheme, wifi-menu, desktop menu).
- Neutral defaults for new users (keyboard from the system, Adwaita cursor, available Nerd Font).

### Fixed
- Right-click menu opened an extra terminal for Sound/Bluetooth/Displays.
- `sset` corrupted values containing `&`, `|` or `\`.
- Wi-Fi names with multi-word security (WPA2 WPA3) or `:`.
- Lock screen with an animated wallpaper; raw `<span>` text in the password field.
- Bar height/position not restored by presets; accent line on the wrong edge with a top bar.
- SDDM "current theme" precedence.

### Removed
- `hyprism-menu`, `hyprism-appmenu` and the jgmenu code path (replaced by the native GTK menu).

## 0.1.0 — 2026-08-17
- First version: palettes, Waybar styles, bilingual CLI, wallpaper picker, lock screen.
