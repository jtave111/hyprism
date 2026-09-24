# shellcheck shell=bash
# =====================================================================
#  Hyprism shared TUI style — sourced by visualconf, hyprism, rofitheme
#  and kittytheme so every fzf screen looks like one program.
#
#  Look: a retro Linux console (BIOS setup / mc / dialog). Double outer
#  frame, square inner panes, an inverse selection bar, a function-key
#  footer. Monochrome plus ONE accent taken from the active palette.
#
#  Readability rules: text on the black terminal must reach ~4.5:1, and
#  the selection is marked by a pointer + inverse bar, never by color only.
# =====================================================================

# relative luminance x1000 of #rrggbb (sRGB, WCAG formula)
_ui_lum(){
  local h="${1#\#}"
  awk -v r=$((16#${h:0:2})) -v g=$((16#${h:2:2})) -v b=$((16#${h:4:2})) 'function c(v){v/=255; return v<=0.03928? v/12.92 : ((v+0.055)/1.055)^2.4}
    BEGIN{printf "%d", 1000*(0.2126*c(r)+0.7152*c(g)+0.0722*c(b))}'
}
# chroma (max-min channel): near 0 means grey — grey is not an accent
_ui_chroma(){
  local h="${1#\#}" r g b mx mn
  r=$((16#${h:0:2})); g=$((16#${h:2:2})); b=$((16#${h:4:2}))
  mx=$r; [ "$g" -gt "$mx" ] && mx=$g; [ "$b" -gt "$mx" ] && mx=$b
  mn=$r; [ "$g" -lt "$mn" ] && mn=$g; [ "$b" -lt "$mn" ] && mn=$b
  echo $((mx - mn))
}

# Picks the UI accent: the palette's accent, then its lit variant, then a
# console red. A candidate must be a real hue and readable on black
# (luminance >= 0.175 is ~4.5:1 against #000).
ui_init(){
  [ -n "${UI_ACC:-}" ] && return 0
  local hd="$HOME/.config/hypr" cand c lit
  lit=$(grep -m1 -oE 'accent_lit *= *"#[0-9A-Fa-f]{6}"' "$hd/colors.lua" 2>/dev/null | grep -oE '#[0-9A-Fa-f]{6}')
  for c in "$(cat "$hd/accent" 2>/dev/null)" "$lit" '#ff3b3b'; do
    [[ "$c" =~ ^#[0-9A-Fa-f]{6}$ ]] || continue
    [ "$(_ui_chroma "$c")" -ge 48 ] || continue
    [ "$(_ui_lum "$c")" -ge 175 ] || continue
    cand="$c"; break
  done
  UI_ACC="${cand:-#ff3b3b}"
  UI_FG='#c8c8c8'      # body text      (~12:1 on black)
  UI_DIM='#8a8a8a'     # secondary text (~5.9:1 on black)
  UI_RULE='#5c5c5c'    # frames/rules   (decorative, non-text)
  UI_ONACC='#000000'   # text on the accent bar

  local h="${UI_ACC#\#}"
  UI_E_ACC=$(printf '\033[38;2;%d;%d;%dm' $((16#${h:0:2})) $((16#${h:2:2})) $((16#${h:4:2})))
  UI_E_BAR=$(printf '\033[48;2;%d;%d;%dm\033[38;2;0;0;0;1m' $((16#${h:0:2})) $((16#${h:2:2})) $((16#${h:4:2})))
  UI_E_FG=$'\033[38;2;200;200;200m'
  UI_E_DIM=$'\033[38;2;138;138;138m'
  UI_E_RULE=$'\033[38;2;92;92;92m'
  UI_E_B=$'\033[1m'
  UI_E_RST=$'\033[0m'
}

# fzf flags shared by every screen. Extra flags (prompt, labels, preview…)
# are appended by the caller.
ui_fzf(){
  ui_init
  fzf --height=100% --layout=reverse --ansi --cycle \
      --border=double --border-label-pos=3 \
      --list-border=sharp --input-border=sharp \
      --info=inline-right --no-separator --highlight-line \
      --gutter=' ' --pointer='▶' --marker='■' --scrollbar='█' --ellipsis='…' \
      --color="bg:-1,fg:$UI_FG,bg+:$UI_ACC,fg+:$UI_ONACC:bold,hl:$UI_ACC:bold,hl+:$UI_ONACC:bold:underline" \
      --color="pointer:$UI_ONACC,marker:$UI_ACC,prompt:$UI_ACC:bold,query:#ffffff,info:$UI_DIM,header:$UI_DIM" \
      --color="border:$UI_RULE,list-border:$UI_RULE,input-border:$UI_RULE,preview-border:$UI_RULE,footer-border:$UI_RULE" \
      --color="label:$UI_ACC:bold,list-label:$UI_ACC,input-label:$UI_DIM,preview-label:$UI_ACC,footer:$UI_DIM" \
      --color="scrollbar:$UI_ACC,gutter:-1,spinner:$UI_ACC" \
      "$@"
}

# " KEY label  KEY label " — a function-key bar in the style of mc
ui_keys(){
  ui_init
  local out="" k l
  while [ $# -ge 2 ]; do
    k="$1"; l="$2"; shift 2
    out+="${UI_E_ACC}${UI_E_B}${k}${UI_E_RST} ${UI_E_DIM}${l}${UI_E_RST}   "
  done
  printf '%s' "$out"
}

# inverse title bar for preview panes:  ▌ HYPRLAND
ui_title(){ ui_init; printf '%s %s %s\n' "$UI_E_BAR" "$1" "$UI_E_RST"; }

# "label ........ value" with a fixed leader width
ui_kv(){
  ui_init
  local k="$1" v="$2" w="${3:-15}" n dots=""
  n=$(( w - ${#k} )); [ "$n" -lt 2 ] && n=2
  printf -v dots '%*s' "$n" ''; dots=${dots// /.}
  printf '  %s%s %s%s %s%s%s\n' "$UI_E_DIM" "$k" "$UI_E_RULE" "$dots" "$UI_E_FG" "$v" "$UI_E_RST"
}

# thin rule with an optional caption:  ── state ───────────
ui_rule(){
  ui_init
  local cap="${1:-}" w="${FZF_PREVIEW_COLUMNS:-44}" line
  w=$(( w - 2 - ${#cap} )); [ "$w" -lt 4 ] && w=4
  printf -v line '%*s' "$w" ''; line=${line// /─}
  if [ -n "$cap" ]; then printf '%s── %s%s%s %s%s\n' "$UI_E_RULE" "$UI_E_DIM" "$cap" "$UI_E_RULE" "${line:4}" "$UI_E_RST"
  else printf '%s%s──%s\n' "$UI_E_RULE" "$line" "$UI_E_RST"; fi
}
