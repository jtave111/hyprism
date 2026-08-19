#!/usr/bin/env bash
# Hyprism installer — idempotent.
# Symlinks the binaries into ~/.local/bin and seeds the default palettes.
set -u

REPO="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
PALDIR="$HOME/.config/hypr/themes/palettes"

mkdir -p "$BIN" "$PALDIR"

link(){ # link <target> <linkname>
  local target="$1" name="$2"
  ln -sfn "$target" "$name"
  printf '  linked  %s -> %s\n' "$name" "$target"
}

link "$REPO/bin/hyprism"        "$BIN/hyprism"
link "$REPO/bin/set-wallpaper"  "$BIN/set-wallpaper"
link "$REPO/bin/hyprism-menu"   "$BIN/hyprism-menu"
link "$REPO/bin/hyprism-desktop" "$BIN/hyprism-desktop"
# Backward-compatible alias (older configs / muscle memory call it hyprtheme).
link "$REPO/bin/hyprism"        "$BIN/hyprtheme"

# Seed default palettes without overwriting user-modified ones.
n=0
for p in "$REPO"/palettes/*.env; do
  [ -e "$p" ] || continue
  dest="$PALDIR/$(basename "$p")"
  if [ ! -e "$dest" ]; then cp "$p" "$dest"; n=$((n+1)); fi
done
printf '  palettes: %d new, %d already present\n' "$n" "$(( $(ls "$REPO"/palettes/*.env 2>/dev/null | wc -l) - n ))"

# Dependency check (informational only).
need="fzf magick swaybg waybar"
opt="kitten kitty mpvpaper ffmpeg chafa rofi dunst hyprlock notify-send wl-copy"
miss=""
for c in $need; do command -v "$c" >/dev/null 2>&1 || miss="$miss $c"; done
[ -n "$miss" ] && printf '  ! missing required:%s\n' "$miss"
missopt=""
for c in $opt; do command -v "$c" >/dev/null 2>&1 || missopt="$missopt $c"; done
[ -n "$missopt" ] && printf '  · missing optional:%s\n' "$missopt"

case ":$PATH:" in
  *":$BIN:"*) ;;
  *) printf '  ! %s is not on your PATH — add it to use "hyprism"\n' "$BIN" ;;
esac

printf '\nDone. Run:  hyprism\n'
