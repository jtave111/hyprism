#!/usr/bin/env bash
# =====================================================================
#  Hyprism installer — sets up the whole desktop on Arch Linux + Hyprland
#
#    ./install.sh                  interactive: pick components, confirm
#    ./install.sh --yes            everything recommended, no questions
#    ./install.sh --components core,hyprland,waybar,desktop-menu,lock
#    ./install.sh --no-deps        skip package installation
#    ./install.sh --dry-run        show what would happen, change nothing
#    ./install.sh --uninstall      remove Hyprism links, restore backups
#    ./install.sh --lang pt        installer + Hyprism language (en|pt)
#
#  Safe by design:
#   - existing configs are moved to ~/.config/hyprism/backups/<date>/
#     before anything is written, and every change is recorded in a
#     manifest so --uninstall can put your old files back;
#   - binaries are symlinked into ~/.local/bin (the repo stays the single
#     source of truth — `git pull` updates Hyprism in place);
#   - packages go through pacman (and yay/paru for the few AUR ones),
#     always showing you the transaction.
# =====================================================================
set -u

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
BIN="$HOME/.local/bin"
CFG="$HOME/.config"
STAMP="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP="$CFG/hyprism/backups/install-$STAMP"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprism"
MANIFEST="$STATE_DIR/install.manifest"
VERSION="$(cat "$REPO/VERSION" 2>/dev/null || echo dev)"

YES=0 DEPS=1 DRY=0 UNINSTALL=0 COMPONENTS="" LANG_SEL=""
while [ $# -gt 0 ]; do
  case "$1" in
    -y|--yes) YES=1 ;;
    --no-deps) DEPS=0 ;;
    -n|--dry-run) DRY=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --components) shift; COMPONENTS="${1:-}" ;;
    --components=*) COMPONENTS="${1#*=}" ;;
    --lang) shift; LANG_SEL="${1:-}" ;;
    --lang=*) LANG_SEL="${1#*=}" ;;
    -h|--help) sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1 (see --help)" >&2; exit 2 ;;
  esac
  shift
done

# ---------- language ----------
case "$LANG_SEL" in
  pt|en) LX="$LANG_SEL" ;;
  *) case "${LANG:-}" in pt*) LX=pt ;; *) LX=en ;; esac ;;
esac
L(){ [ "$LX" = pt ] && printf '%s' "$1" || printf '%s' "$2"; }   # L "pt" "en"

# ---------- output ----------
if [ -t 1 ]; then A=$'\033[38;2;255;59;59m' G=$'\033[32m' Y=$'\033[33m' D=$'\033[38;2;138;138;138m' B=$'\033[1m' R=$'\033[0m'
else A='' G='' Y='' D='' B='' R=''; fi
title(){ printf '\n%s%s▌ %s %s\n' "$A" "$B" "$1" "$R"; }
ok(){    printf '  %s[ OK ]%s %s\n' "$G" "$R" "$*"; }
warn(){  printf '  %s[ !! ]%s %s\n' "$Y" "$R" "$*"; }
info(){  printf '  %s[ -- ]%s %s\n' "$D" "$R" "$*"; }
die(){   printf '  %s[FAIL]%s %s\n' "$A" "$R" "$*" >&2; exit 1; }
run(){   if [ "$DRY" = 1 ]; then printf '  %s(dry-run)%s %s\n' "$D" "$R" "$*"; else "$@"; fi; }
have(){  command -v "$1" >/dev/null 2>&1; }
ask(){   # ask "question" default(y|n) — with --yes the default answer is used
  local d="${2:-y}" a
  if [ "$YES" = 1 ]; then [ "$d" = y ]; return; fi
  read -rp "  $1 [$( [ "$d" = y ] && echo Y/n || echo y/N )] " a
  a="${a:-$d}"; [[ "$a" =~ ^[YySs] ]]
}
record(){ [ "$DRY" = 1 ] || { mkdir -p "$STATE_DIR"; printf '%s\n' "$*" >> "$MANIFEST"; }; }

# =====================================================================
#  Uninstall
# =====================================================================
if [ "$UNINSTALL" = 1 ]; then
  title "$(L 'Desinstalando o Hyprism' 'Uninstalling Hyprism')"
  n=0
  for l in "$BIN"/*; do
    [ -L "$l" ] || continue
    case "$(readlink -f "$l")" in "$REPO"/*) run rm -f "$l"; n=$((n+1)) ;; esac
  done
  ok "$(L "links removidos: $n" "links removed: $n")"
  if [ -f "$MANIFEST" ]; then
    last=$(grep '^backup ' "$MANIFEST" | tail -1 | cut -d' ' -f2-)
    if [ -n "$last" ] && [ -d "$last" ] && ask "$(L "Restaurar as configs anteriores de $last?" "Restore your previous configs from $last?")" y; then
      (cd "$last" && find . -type f -o -type l) | while read -r f; do
        f="${f#./}"; run mkdir -p "$(dirname "$HOME/$f")"; run cp -a "$last/$f" "$HOME/$f"
        info "$(L 'restaurado' 'restored'): ~/$f"
      done
    fi
  fi
  info "$(L 'Seus dados (~/.config/hypr/themes, presets, wallpapers) foram mantidos.' 'Your data (~/.config/hypr/themes, presets, wallpapers) was kept.')"
  exit 0
fi

# =====================================================================
#  Components
# =====================================================================
#  id|default|pt label|en label|pacman packages|aur packages
COMPS=(
"core|y|Núcleo: hyprism, visualconf, configurações, paletas, presets|Core: hyprism, visualconf, settings, palettes, presets|fzf jq imagemagick swaybg xdg-user-dirs libnotify pacman-contrib polkit hyprpolkitagent|"
"hyprland|y|Config do Hyprland (hyprland.lua gerenciado pelo Hyprism)|Hyprland config (hyprland.lua managed by Hyprism)|hyprland xdg-desktop-portal-hyprland qt6ct|"
"waybar|y|Barra Waybar com estilos flat/pills/segmentada|Waybar bar with flat/pills/segmented styles|waybar ttf-nerd-fonts-symbols ttf-firacode-nerd playerctl wireplumber|"
"launcher|y|Rofi: launcher, menu de energia, menu rápido (SUPER+I)|Rofi: launcher, power menu, quick menu (SUPER+I)|rofi|"
"terminal|y|Kitty com temas e prompts Starship|Kitty with themes and Starship prompts|kitty starship|"
"desktop-menu|y|Menu do botão direito na área de trabalho|Right-click desktop menu|python-gobject gtk3 gtk-layer-shell|"
"lock|y|Tela de bloqueio e ociosidade (hyprlock + hypridle)|Lock screen and idle (hyprlock + hypridle)|hyprlock hypridle|"
"notify|y|Notificações (dunst)|Notifications (dunst)|dunst|"
"system|y|Ferramentas das Configurações: rede, som, bluetooth, energia|Settings backends: network, sound, bluetooth, power|networkmanager pipewire pipewire-pulse wireplumber bluez bluez-utils brightnessctl|"
"screenshot|y|Capturas de tela (SUPER+P, Print)|Screenshots (SUPER+P, Print)|grim slurp wl-clipboard hyprshot|"
"extras|n|Extras: wallpaper animado, prévias no terminal, perfis de energia|Extras: animated wallpaper, terminal previews, power profiles|ffmpeg chafa power-profiles-daemon nwg-look|mpvpaper"
)
comp_field(){ printf '%s' "$1" | cut -d'|' -f"$2"; }

select_components(){
  local sel="" c id def lab
  if [ -n "$COMPONENTS" ]; then
    sel=" ${COMPONENTS//,/ } "
    case "$sel" in *" core "*) ;; *) sel="$sel core " ;; esac
  elif [ "$YES" = 1 ] || [ ! -t 0 ]; then
    for c in "${COMPS[@]}"; do [ "$(comp_field "$c" 2)" = y ] && sel="$sel $(comp_field "$c" 1) "; done
  elif have fzf; then
    local lines=()
    for c in "${COMPS[@]}"; do
      id=$(comp_field "$c" 1); def=$(comp_field "$c" 2)
      lab=$( [ "$LX" = pt ] && comp_field "$c" 3 || comp_field "$c" 4 )
      lines+=("$id"$'\t'"$lab")
    done
    local picked
    picked=$(printf '%s\n' "${lines[@]}" | fzf --multi --delimiter=$'\t' --with-nth=2 \
      --layout=reverse --height=60% --border=double \
      --border-label=" HYPRISM $VERSION · $(L 'componentes' 'components') " \
      --header="$(L 'TAB marca/desmarca · ENTER confirma · (Núcleo é sempre instalado)' 'TAB toggle · ENTER confirm · (Core is always installed)')" \
      --bind 'start:select-all' --prompt="$(L 'instalar' 'install') > " | cut -f1)
    [ -n "$picked" ] || { info "$(L 'Nada selecionado — saindo.' 'Nothing selected — exiting.')"; exit 0; }
    sel=" core $(printf '%s ' $picked) "
  else
    for c in "${COMPS[@]}"; do
      id=$(comp_field "$c" 1); def=$(comp_field "$c" 2)
      lab=$( [ "$LX" = pt ] && comp_field "$c" 3 || comp_field "$c" 4 )
      if [ "$id" = core ] || ask "$lab?" "$def"; then sel="$sel $id "; fi
    done
  fi
  printf '%s' "$sel"
}
want(){ case "$SELECTED" in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

# =====================================================================
#  Checks
# =====================================================================
printf '%s%s' "$A" "$B"
cat <<'EOF'
   _   _                  _
  | | | |_   _ _ __  _ __(_)___ _ __ ___
  | |_| | | | | '_ \| '__| / __| '_ ` _ \
  |  _  | |_| | |_) | |  | \__ \ | | | | |
  |_| |_|\__, | .__/|_|  |_|___/_| |_| |_|
         |___/|_|
EOF
printf '%s  %s %s%s\n' "$R$D" "$(L 'uma paleta → o desktop inteiro' 'one palette → the whole desktop')" "· v$VERSION" "$R"

[ "$(id -u)" = 0 ] && die "$(L 'Não rode como root; o instalador pede sudo quando precisar.' 'Do not run as root; the installer asks for sudo when needed.')"
have pacman || warn "$(L 'pacman não encontrado: pulando pacotes (Hyprism é feito para Arch).' 'pacman not found: skipping packages (Hyprism targets Arch).')"
have pacman || DEPS=0

SELECTED="$(select_components)"
title "$(L 'Componentes' 'Components')"
for c in "${COMPS[@]}"; do
  id=$(comp_field "$c" 1)
  want "$id" && ok "$( [ "$LX" = pt ] && comp_field "$c" 3 || comp_field "$c" 4 )"
done

# =====================================================================
#  Packages
# =====================================================================
if [ "$DEPS" = 1 ]; then
  title "$(L 'Pacotes' 'Packages')"
  repo_pkgs="" aur_pkgs=""
  for c in "${COMPS[@]}"; do
    want "$(comp_field "$c" 1)" || continue
    repo_pkgs="$repo_pkgs $(comp_field "$c" 5)"; aur_pkgs="$aur_pkgs $(comp_field "$c" 6)"
  done
  # power-profiles-daemon conflicts with tlp/auto-cpufreq — never fight an existing setup
  if pacman -Qq tlp >/dev/null 2>&1 || pacman -Qq auto-cpufreq >/dev/null 2>&1; then
    repo_pkgs="${repo_pkgs//power-profiles-daemon/}"
  fi
  missing=""
  for p in $repo_pkgs; do
    pacman -Qq "$p" >/dev/null 2>&1 && continue
    if pacman -Si "$p" >/dev/null 2>&1; then missing="$missing $p"
    elif pacman -Qqg "$p" >/dev/null 2>&1; then :
    else aur_pkgs="$aur_pkgs $p"; fi   # not in the repos any more → try AUR
  done
  if [ -n "${missing// /}" ]; then
    info "$(L 'faltando' 'missing'):$missing"
    if ask "$(L 'Instalar agora com pacman?' 'Install now with pacman?')" y; then
      # shellcheck disable=SC2086
      run sudo pacman -S --needed $missing || warn "$(L 'pacman falhou — continue e instale depois.' 'pacman failed — continuing, install later.')"
    fi
  else
    ok "$(L 'todos os pacotes oficiais já instalados' 'all official packages already installed')"
  fi
  aur_missing=""
  for p in $aur_pkgs; do pacman -Qq "$p" >/dev/null 2>&1 || aur_missing="$aur_missing $p"; done
  if [ -n "${aur_missing// /}" ]; then
    helper=""; for h in paru yay; do have "$h" && { helper=$h; break; }; done
    if [ -n "$helper" ]; then
      if ask "$(L "Instalar do AUR com $helper:$aur_missing?" "Install from AUR with $helper:$aur_missing?")" n; then
        # shellcheck disable=SC2086
        run "$helper" -S --needed $aur_missing || warn "$(L 'AUR falhou (opcional).' 'AUR failed (optional).')"
      fi
    else
      info "$(L "AUR (opcional, instale depois):$aur_missing" "AUR (optional, install later):$aur_missing")"
    fi
  fi
fi

# =====================================================================
#  Files
# =====================================================================
backup_path(){ # move an existing file/dir into the backup tree (keeps $HOME-relative path)
  local p="$1" rel
  [ -e "$p" ] || [ -L "$p" ] || return 0
  rel="${p#"$HOME"/}"
  run mkdir -p "$BACKUP/$(dirname "$rel")"
  run mv "$p" "$BACKUP/$rel"
  record "backup $BACKUP"
  info "$(L 'backup' 'backup'): ~/$rel → $(L 'backups' 'backups')/install-$STAMP"
}

deploy(){ # deploy SRC DEST — copy a config template, backing up what was there
  local src="$1" dest="$2"
  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then info "$(L 'igual, mantido' 'unchanged'): ${dest/#$HOME/\~}"; return 0; fi
  backup_path "$dest"
  run mkdir -p "$(dirname "$dest")"
  run cp "$src" "$dest"
  record "file $dest"
  ok "${dest/#$HOME/\~}"
}

title "$(L 'Programas' 'Programs')"
run mkdir -p "$BIN"
for f in "$REPO"/bin/*; do
  [ -f "$f" ] && [ -x "$f" ] || continue
  name=$(basename "$f"); dest="$BIN/$name"
  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$f")" ]; then continue; fi
  [ -e "$dest" ] || [ -L "$dest" ] && backup_path "$dest"
  run ln -s "$f" "$dest"; record "link $dest"
done
# compat alias used by older configs
[ -L "$BIN/hyprtheme" ] || { [ -e "$BIN/hyprtheme" ] && backup_path "$BIN/hyprtheme"; run ln -s "$REPO/bin/hyprism" "$BIN/hyprtheme"; record "link $BIN/hyprtheme"; }
# links left behind by older Hyprism versions (scripts that no longer exist)
for l in "$BIN"/*; do
  [ -L "$l" ] && [ ! -e "$l" ] && case "$(readlink "$l")" in "$REPO"/*) run rm -f "$l"; info "$(L 'link antigo removido' 'stale link removed'): $(basename "$l")" ;; esac
done
# VirtualBox (VMSVGA) / VMware: Hyprland rejects kitty's GL buffers, so kitty
# gets a software-rendering shim ahead of /usr/bin (the session PATH starts
# with ~/.local/bin). --uninstall drops it with the other links.
if want terminal && grep -qs '^vmwgfx ' /proc/modules; then
  if [ ! -L "$BIN/kitty" ] || [ "$(readlink -f "$BIN/kitty")" != "$(readlink -f "$REPO/share/vm/kitty")" ]; then
    [ -e "$BIN/kitty" ] || [ -L "$BIN/kitty" ] && backup_path "$BIN/kitty"
    run ln -s "$REPO/share/vm/kitty" "$BIN/kitty"; record "link $BIN/kitty"
  fi
  info "$(L 'VM (vmwgfx) detectada: kitty renderiza por software' 'VM (vmwgfx) detected: kitty renders in software')"
fi
ok "$(L 'links em' 'links in') ~/.local/bin → $REPO/bin"

title "$(L 'Dados' 'Data')"
PAL="$CFG/hypr/themes/palettes"; run mkdir -p "$PAL" "$CFG/hypr/themes/presets" "$CFG/hyprism"
n=0; for p in "$REPO"/palettes/*.env; do [ -e "$PAL/$(basename "$p")" ] || { run cp "$p" "$PAL/"; n=$((n+1)); }; done
ok "$(L "paletas: $n novas" "palettes: $n new") ($(ls "$REPO"/palettes/*.env | wc -l) $(L 'no total' 'total'))"
ok "$(L "presets embutidos: $(ls "$REPO"/presets/*.preset 2>/dev/null | wc -l) (hyprism preset list)" "built-in presets: $(ls "$REPO"/presets/*.preset 2>/dev/null | wc -l) (hyprism preset list)")"
# themes/prompts/layouts the engines need on a fresh machine (never overwrite yours)
seed_dir(){ local s="$1" d="$2" k=0 x; [ -d "$s" ] || return 0; run mkdir -p "$d"
  for x in "$s"/*; do [ -e "$d/$(basename "$x")" ] || { run cp -r "$x" "$d/"; k=$((k+1)); }; done
  [ "$k" -gt 0 ] && ok "${d/#$HOME/\~}: $k $(L 'arquivos' 'files')"; return 0; }
want terminal && seed_dir "$REPO/share/kitty/themes"  "$CFG/kitty/themes"
want terminal && seed_dir "$REPO/share/kitty/prompts" "$CFG/kitty/prompts"
want launcher && seed_dir "$REPO/share/rofi/layouts"  "$CFG/rofi/themes/layouts"
want launcher && [ -f "$REPO/share/rofi/wifi.rasi" ] && [ ! -e "$CFG/rofi/wifi.rasi" ] && run cp "$REPO/share/rofi/wifi.rasi" "$CFG/rofi/wifi.rasi"
want launcher && [ -f "$REPO/share/rofi/config.rasi" ] && [ ! -e "$CFG/rofi/config.rasi" ] && run cp "$REPO/share/rofi/config.rasi" "$CFG/rofi/config.rasi"

# a wallpaper folder and a default wallpaper, so the first login is not black
# (same lookup as bin/hyprism: xdg-user-dir answers $HOME when no user-dirs exist)
PICS=$(xdg-user-dir PICTURES 2>/dev/null)
{ [ -z "$PICS" ] || [ "$PICS" = "$HOME" ]; } && PICS="$HOME/Pictures"
WALLDIR="$PICS/wallpaper"
[ -d "$HOME/Pictures/wallpaper" ] && WALLDIR="$HOME/Pictures/wallpaper"
run mkdir -p "$WALLDIR"
if [ -z "$(ls -A "$WALLDIR" 2>/dev/null)" ] && have magick; then
  run magick -size 1920x1080 radial-gradient:'#2a2f3a'-'#0d0f14' -attenuate 0.18 +noise Gaussian "$WALLDIR/hyprism-default.png" 2>/dev/null \
    && ok "$(L 'wallpaper padrão criado' 'default wallpaper created'): ${WALLDIR/#$HOME/\~}/hyprism-default.png"
fi
if [ ! -s "$CFG/hypr/wallpaper" ] && [ -f "$WALLDIR/hyprism-default.png" ]; then
  [ "$DRY" = 1 ] || printf '%s\n' "$WALLDIR/hyprism-default.png" > "$CFG/hypr/wallpaper"
fi

if want hyprland; then
  title "Hyprland"
  # Hyprland writes an example config on first start; that one is not the
  # user's work, so it is replaced (still backed up) without asking.
  if [ -f "$CFG/hypr/hyprland.lua" ] && grep -qE 'AUTOGENERATED HYPRLAND CONFIG|autogenerated *= *true' "$CFG/hypr/hyprland.lua"; then
    deploy "$REPO/configs/hypr/hyprland.lua" "$CFG/hypr/hyprland.lua"
  elif [ -f "$CFG/hypr/hyprland.lua" ] && ! grep -q 'Hyprland config shipped by Hyprism' "$CFG/hypr/hyprland.lua"; then
    warn "$(L 'Você já tem um hyprland.lua próprio.' 'You already have your own hyprland.lua.')"
    if ask "$(L 'Substituir pelo do Hyprism? (o seu vai pro backup)' 'Replace it with Hyprism'"'"'s? (yours goes to the backup)')" n; then
      deploy "$REPO/configs/hypr/hyprland.lua" "$CFG/hypr/hyprland.lua"
    else
      run cp "$REPO/configs/hypr/hyprland.lua" "$CFG/hypr/hyprland.hyprism-example.lua"
      info "$(L 'mantido o seu; exemplo salvo em ~/.config/hypr/hyprland.hyprism-example.lua' 'kept yours; example saved to ~/.config/hypr/hyprland.hyprism-example.lua')"
    fi
  else
    deploy "$REPO/configs/hypr/hyprland.lua" "$CFG/hypr/hyprland.lua"
  fi
  deploy "$REPO/configs/hypr/vm-mode.lua" "$CFG/hypr/vm-mode.lua"
fi

if want waybar; then
  title "Waybar"
  if [ -f "$CFG/waybar/config.jsonc" ] && ! grep -q 'Waybar config shipped by Hyprism' "$CFG/waybar/config.jsonc"; then
    if ask "$(L 'Substituir sua config da Waybar pela do Hyprism? (backup automático)' 'Replace your Waybar config with Hyprism'"'"'s? (automatic backup)')" y; then
      deploy "$REPO/configs/waybar/config.jsonc" "$CFG/waybar/config.jsonc"
    fi
  else
    deploy "$REPO/configs/waybar/config.jsonc" "$CFG/waybar/config.jsonc"
  fi
fi

# =====================================================================
#  First run
# =====================================================================
title "$(L 'Primeira execução' 'First run')"
case ":$PATH:" in *":$BIN:"*) ;; *) warn "$(L "$BIN não está no PATH — adicione no seu shell." "$BIN is not on your PATH — add it in your shell rc.")" ;; esac
if [ "$DRY" = 0 ] && [ -x "$BIN/hyprism" ]; then
  "$BIN/hyprism" lang "$LX" >/dev/null 2>&1 && ok "$(L 'idioma' 'language'): $LX"
  if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    "$BIN/hyprism" render >/dev/null 2>&1 && ok "$(L 'tema aplicado ao vivo' 'theme applied live')"
  else
    "$BIN/hyprism" render >/dev/null 2>&1; info "$(L 'Hyprland não está rodando: tudo será aplicado no próximo login.' 'Hyprland is not running: everything applies at your next login.')"
  fi
fi
record "installed $VERSION $STAMP"

title "$(L 'Pronto' 'Done')"
cat <<EOF
  $(L 'Abrir o Hyprism' 'Open Hyprism')            ${B}visualconf${R}   ${D}(SUPER + H)${R}
  $(L 'Configurações do sistema' 'System settings')    ${B}hyprism-settings${R}   ${D}(SUPER + ,)${R}
  $(L 'Menu rápido' 'Quick menu')                ${D}SUPER + I${R}     $(L 'Energia' 'Power') ${D}SUPER + ESC${R}
  $(L 'Aplicar um visual pronto' 'Apply a ready-made look')    ${B}hyprism preset list${R}
  $(L 'Desinstalar' 'Uninstall')                ${B}./install.sh --uninstall${R}
EOF
[ -d "$BACKUP" ] && printf '\n  %s%s: %s%s\n' "$D" "$(L 'Backups das suas configs' 'Backups of your configs')" "${BACKUP/#$HOME/\~}" "$R"
exit 0
