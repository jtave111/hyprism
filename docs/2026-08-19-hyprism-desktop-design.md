# Hyprism Desktop — design & roadmap

Turning the Hyprland desktop into one coherent, Hyprism-branded system: a
configuration center (SUPER+I), a categorized application menu (right-click on
the desktop), and a few quality-of-life binds. English by default (system
standard), bilingual where Hyprism already is.

## Context

The user runs Hyprland on Arch (BlackArch tooling). Config today is scattered:
`hyprism` (theming, just modularized/i18n'd), `net-tui` (ugly hand-rolled
network TUI), `control-center` (rofi launcher on SUPER+I), `visualconf`,
`rofitheme`, `kittytheme`. The user wants it unified under **Hyprism**, more
organized and intuitive, and specifically:

1. **SUPER+I becomes Hyprism** — the visual center is the Hyprism menu, grouped.
2. **Right-click on the empty desktop** opens a big **BlackArch-style categorized
   app menu** at the cursor (like the stock BlackArch fluxbox menu), with the
   tools organized by specialty as submenus. Does not replace SUPER+Space.
3. **SUPER + mouse scroll = grow/shrink the focused window.**
4. Language selector stays prominent (English default).
5. Network stays first-class (native module later, not sidelined).

## Roadmap (each sub-project = its own build)

1. **App menu + desktop right-click** (this build) — self-contained, high value.
2. **SUPER+I → Hyprism** grouped central + **SUPER+scroll resize** (this build).
3. **Network** native Hyprism module (replaces net-tui).
4. **Binds central** (JSON→Lua, safe) — manages scroll-resize et al.
5. **System** launchers (sound/bluetooth/displays) inside the central.
6. **Modularize** hyprism into `lib/` (internal hygiene).

---

## This build

> **Update (build):** the desktop menu is a **native GTK menu** built inside
> `bin/hyprism-desktop`, not rofi. GTK gives true cascading submenus that open on
> **hover**, gradient styling via CSS pulled from the active palette, opens at the
> cursor (`popup_at_pointer`), and dismisses on click-away — matching the BlackArch
> fluxbox look the user asked for. `bin/hyprism-menu` (rofi walker) is kept as a
> CLI fallback. The taxonomy below still applies (same specialties/groups).

### A. Categorized application menu — `bin/hyprism-menu`

Data-driven from pacman groups, so it is always complete and needs no
hand-maintenance; only **installed** tools appear.

- **Mapping:** installed members of a group =
  `comm -12 <(pacman -Sqg <group> | sort -u) <(pacman -Qq | sort -u)`.
- **Structure** (rofi, navigated as a re-invoking walker — rofi has no native
  cascades):
  ```
  root:   Terminals ▸ · Browsers ▸ · Files · BlackArch ▸ · Settings (Hyprism)
  BlackArch ▸  →  8 specialties (only those with installed tools):
      Recon & OSINT · Web & Apps · Exploitation & Access · Networks & Wireless
      Reversing & Binary · Forensics & Defense · Hardware & Radio · Crypto & Wordlists · Misc
  specialty ▸  →  its blackarch-<category> groups that have installed tools
  category ▸   →  installed tools  →  launch
  ```
- **Specialty → groups map** (curated; groups with 0 installed are hidden):
  - Recon & OSINT: recon, fingerprint, scanner, social, database
  - Web & Apps: webapp, code-audit, fuzzer, proxy, mobile
  - Exploitation & Access: exploitation, backdoor, dos, malware, keylogger, honeypot
  - Networks & Wireless: networking, wireless, bluetooth, sniffer, spoof, tunnel, nfc, voip
  - Reversing & Binary: reversing, binary, debugger, disassembler, decompiler, packer, unpacker
  - Forensics & Defense: forensic, anti-forensic, defensive, ids, threat-model, stego
  - Hardware & Radio: hardware, radio, firmware, drone, automobile, gpu
  - Crypto & Wordlists: crypto, cracker, wordlist
  - Misc: automation, ai, config, windows, misc
  A tool appearing in two groups shows in both (BlackArch's own behavior).
- **Launch:** GUI tools (wireshark, zaproxy, burpsuite, ghidra, …) run directly;
  everything else opens in a kitty terminal. A small GUI allow-list decides.
- **Positioning at the cursor:** read `hyprctl cursorpos`, pass rofi a theme
  override placing the window near the click (`window { anchor/location + x/y offset }`).
- **Theme:** uses the user's existing rofi theme (rofitheme), so it matches the
  palette automatically. Labels in English.
- **Non-BlackArch categories:** Terminals/Browsers are discovered from installed
  packages / desktop entries.

### B. Desktop right-click trigger — `bin/hyprism-desktop`

A transparent full-screen **wlr-layer-shell** surface via `gtk-layer-shell` +
`python-gobject`, on the **bottom** layer (above the wallpaper `swaybg`, below
normal windows). It receives pointer events only where no window covers it — i.e.
the empty desktop. On **right-click (button 3)** it launches `hyprism-menu` at the
cursor. Autostarted from Hyprland (`exec-once`). This is the correct
layer-shell approach; if unavailable, fallback is SUPER+right-click via a Hyprland
`bindm`.

### C. Hyprland binds (`~/.config/hypr/hyprland.lua`)

- **SUPER + I** → open Hyprism central in a kitty window
  (`kitty --class hyprism-center -e hyprism menu`), replacing `control-center`.
- **SUPER + scroll** → resize focused window (up = grow, down = shrink) via
  `hyprctl dispatch resizeactive`. (Will later be managed by the Binds central.)
- **exec-once** → `hyprism-desktop` (the right-click catcher).
- A window rule centers/sizes the `hyprism-center` class nicely.

### D. Hyprism central menu — `hyprism menu`

A new grouped entry point (does not disturb existing subcommands). Groups:
`Appearance` (palette, wallpaper, bar & style, cursor, effects, …),
`System` (network, sound, bluetooth, displays — launchers for now),
`Keys` (view; create/edit later), plus language (en/pt), config, sync.
Language shown at the top. Reuses the existing i18n (`t`/`FZFM`/`row`).

## Verification

- `hyprism-menu` walks BlackArch → specialty → category → tool and launches; only
  installed tools listed; opens at cursor; English labels.
- Right-click on empty desktop opens the menu; right-click inside an app is
  unaffected.
- SUPER+I opens the Hyprism central (kitty); SUPER+scroll resizes the focused
  window; both survive a Hyprland reload.
- `bash -n` clean; scripts symlinked by `install.sh`.
