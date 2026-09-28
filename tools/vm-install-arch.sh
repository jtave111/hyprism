#!/usr/bin/env bash
# =====================================================================
#  Arch Linux + Hyprland in a VIRTUAL MACHINE, ready to test Hyprism.
#
#  Boot the Arch ISO in the VM, then (as root, in the live console):
#
#    loadkeys br-abnt2        # only if your keyboard is ABNT2
#    curl -fsSLo i.sh https://raw.githubusercontent.com/jtave111/hyprism/main/tools/vm-install-arch.sh
#    bash i.sh
#
#  It asks for a user name/password (Enter = defaults), then ERASES the
#  VM's virtual disk and installs: base system, GRUB (UEFI or BIOS),
#  NetworkManager, PipeWire, Hyprland, kitty, SDDM and the VM guest tools.
#  Hyprism is cloned to ~/dev/hyprism — after the first login just run:
#
#    cd ~/dev/hyprism && ./install.sh
#
#  Refuses to run outside a virtual machine, so it can never wipe a real PC.
# =====================================================================
set -euo pipefail

G=$'\033[32m' R=$'\033[31m' B=$'\033[1m' Z=$'\033[0m'
step(){ printf '\n%s▌ %s%s\n' "$B" "$*" "$Z"; }
ok(){   printf '  %s[ OK ]%s %s\n' "$G" "$Z" "$*"; }
die(){  printf '\n  %s[FAIL]%s %s\n' "$R" "$Z" "$*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "run as root from the Arch ISO"
[ -d /run/archiso ] || die "this must run from the Arch Linux ISO (live environment)"
VIRT=$(systemd-detect-virt --vm 2>/dev/null || true)
[ -n "$VIRT" ] && [ "$VIRT" != none ] || die "not a virtual machine — refusing to erase a real disk"
ok "virtual machine detected: $VIRT"

# ---------- the virtual disk ----------
mapfile -t DISKS < <(lsblk -dnpo NAME,TYPE,RO,RM | awk '$2=="disk" && $3=="0" && $4=="0" && $1 !~ /loop|sr|zram/ {print $1}')
[ "${#DISKS[@]}" -eq 1 ] || die "expected exactly one virtual disk, found: ${DISKS[*]:-none}"
DISK=${DISKS[0]}
SIZE_GB=$(( $(lsblk -dnbo SIZE "$DISK") / 1024 / 1024 / 1024 ))
[ "$SIZE_GB" -ge 7 ] || die "$DISK has ${SIZE_GB} GB — give the VM at least 8 GB (20 GB is comfortable)"
case "$DISK" in *nvme*|*mmcblk*) PFX=p ;; *) PFX= ;; esac
UEFI=0; [ -d /sys/firmware/efi/efivars ] && UEFI=1

# ---------- questions (Enter = default) ----------
read -rp "  User name [hyprism]: " USERNAME; USERNAME=${USERNAME:-hyprism}
[[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "invalid user name"
read -rsp "  Password for $USERNAME and root [hyprism]: " PASS; echo; PASS=${PASS:-hyprism}
read -rp "  Keyboard [br]  (br, us, …): " KB; KB=${KB:-br}
read -rp "  Time zone [America/Sao_Paulo]: " TZN; TZN=${TZN:-America/Sao_Paulo}
[ -f "/usr/share/zoneinfo/$TZN" ] || die "unknown time zone: $TZN"
case "$KB" in br) CONSOLE_KEYMAP=br-abnt2 ;; *) CONSOLE_KEYMAP=$KB ;; esac

printf '\n  %sThis ERASES %s (%s GB) inside the VM%s — boot mode: %s\n' "$B" "$DISK" "$SIZE_GB" "$Z" "$([ $UEFI = 1 ] && echo UEFI || echo BIOS)"
read -rp "  Type YES to continue: " CONFIRM
[ "$CONFIRM" = YES ] || die "cancelled — nothing was changed"

# ---------- network ----------
step "Network"
curl -fsI --max-time 15 https://archlinux.org >/dev/null 2>&1 || die "no internet in the VM (check the VM network adapter: NAT)"
timedatectl set-ntp true
ok "online"

# ---------- partitions ----------
step "Partitioning $DISK"
umount -R /mnt 2>/dev/null || true
wipefs -af "$DISK" >/dev/null
if [ $UEFI = 1 ]; then
  sfdisk -q "$DISK" <<'EOF'
label: gpt
size=512MiB, type=uefi, name="EFI system partition"
type=linux, name="root"
EOF
  BOOTP=${DISK}${PFX}1; ROOTP=${DISK}${PFX}2
else
  sfdisk -q "$DISK" <<'EOF'
label: gpt
size=1MiB, type=21686148-6449-6E6F-744E-656564454649, name="bios_grub"
type=linux, name="root"
EOF
  BOOTP=""; ROOTP=${DISK}${PFX}2
fi
partprobe "$DISK" 2>/dev/null || true; udevadm settle
mkfs.ext4 -q -F -L arch "$ROOTP"
mount "$ROOTP" /mnt
if [ -n "$BOOTP" ]; then
  mkfs.fat -F32 -n EFI "$BOOTP" >/dev/null
  mount --mkdir "$BOOTP" /mnt/boot
fi
ok "root ext4 on $ROOTP$([ -n "$BOOTP" ] && echo ", EFI on $BOOTP")"

# ---------- packages ----------
step "Installing packages (this is the long part)"
case "$VIRT" in
  oracle)          GUEST="virtualbox-guest-utils" ; GUEST_SVC="vboxservice" ;;
  kvm|qemu)        GUEST="qemu-guest-agent spice-vdagent" ; GUEST_SVC="qemu-guest-agent" ;;
  vmware)          GUEST="open-vm-tools" ; GUEST_SVC="vmtoolsd" ;;
  *)               GUEST="" ; GUEST_SVC="" ;;
esac
CPU_UCODE=""; grep -q GenuineIntel /proc/cpuinfo && CPU_UCODE=intel-ucode; grep -q AuthenticAMD /proc/cpuinfo && CPU_UCODE=amd-ucode
# a stale ISO keyring makes pacstrap fail on signatures
pacman -Sy --noconfirm --needed archlinux-keyring >/dev/null
# keep the target's pacman fast and resilient
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
# shellcheck disable=SC2086
pacstrap -K /mnt base linux linux-firmware $CPU_UCODE sudo nano vim git \
  networkmanager grub efibootmgr \
  pipewire pipewire-pulse wireplumber \
  hyprland xdg-desktop-portal-hyprland kitty sddm \
  mesa ttf-dejavu noto-fonts ttf-nerd-fonts-symbols \
  fzf jq $GUEST
ok "base system + Hyprland installed"

genfstab -U /mnt >> /mnt/etc/fstab

# ---------- configure the new system ----------
step "Configuring"
cat > /mnt/root/setup.sh <<EOF
set -euo pipefail
ln -sf /usr/share/zoneinfo/$TZN /etc/localtime; hwclock --systohc
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/; s/^#pt_BR.UTF-8/pt_BR.UTF-8/' /etc/locale.gen; locale-gen >/dev/null
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=$CONSOLE_KEYMAP' > /etc/vconsole.conf
mkdir -p /etc/X11/xorg.conf.d
printf 'Section "InputClass"\n  Identifier "system-keyboard"\n  MatchIsKeyboard "on"\n  Option "XkbLayout" "$KB"\nEndSection\n' > /etc/X11/xorg.conf.d/00-keyboard.conf
echo archvm > /etc/hostname
printf '127.0.0.1 localhost\n::1 localhost\n127.0.1.1 archvm.localdomain archvm\n' > /etc/hosts
useradd -m -G wheel,video,audio -s /bin/bash $USERNAME
echo '$USERNAME:$PASS' | chpasswd; echo 'root:$PASS' | chpasswd
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel; chmod 440 /etc/sudoers.d/10-wheel
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 5/' /etc/pacman.conf
systemctl enable NetworkManager sddm >/dev/null 2>&1
[ -n "$GUEST_SVC" ] && systemctl enable $GUEST_SVC >/dev/null 2>&1 || true
if [ $UEFI = 1 ]; then
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable >/dev/null
else
  grub-install --target=i386-pc $DISK >/dev/null
fi
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1
# Hyprism, cloned and ready: after login run  cd ~/dev/hyprism && ./install.sh
sudo -u $USERNAME git clone -q https://github.com/jtave111/hyprism.git /home/$USERNAME/dev/hyprism
cat > /home/$USERNAME/LEIA-ME.txt <<'TXT'
Hyprism test VM
  cd ~/dev/hyprism && ./install.sh          (English)
  cd ~/dev/hyprism && ./install.sh --lang pt (Português)
TXT
chown $USERNAME: /home/$USERNAME/LEIA-ME.txt
pacman -Scc --noconfirm >/dev/null 2>&1 || true
EOF
arch-chroot /mnt bash /root/setup.sh
rm -f /mnt/root/setup.sh
ok "user $USERNAME, keyboard $KB, time zone $TZN, GRUB, SDDM, Hyprism cloned"

umount -R /mnt
printf '\n%sDone.%s Power the VM off, then in the VM settings:\n' "$B" "$Z"
cat <<'EOF'
  • Display → Video Memory 128 MB and ENABLE 3D ACCELERATION (Hyprland needs it)
  • System → 4 GB RAM (or more) and 2+ CPUs
  • Storage → remove the Arch ISO from the optical drive
Boot, log in on SDDM (session: Hyprland), open kitty with SUPER+Q or SUPER+RETURN, then:
  cd ~/dev/hyprism && ./install.sh
EOF
