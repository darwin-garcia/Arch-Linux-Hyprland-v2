#!/usr/bin/env bash
# =============================================================================
#  Arch Linux Installer — ThinkPad X1 Carbon Gen 8
#  Basado en: github.com/darwin-garcia/Arch-Linux-Hyprland
#  Hardware: Intel i7-10610U · 16GB LPDDR3 2133 · Samsung NVMe PCIe 4.0 512GB
#  Bootloader: systemd-boot · FS: Btrfs + zram · DE: Hyprland (Wayland)
#
#  USO (desde el live USB de Arch Linux):
#    1. Arrancar el ISO de Arch Linux
#    2. Conectarse a internet: iwctl o ethernet
#    3. curl -sL https://raw.githubusercontent.com/darwin-garcia/Arch-Linux-Hyprland/main/install.sh | bash
#       -- O copiar este script a un USB y ejecutarlo:
#    4. bash install-arch-hyprland.sh
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# COLORES Y HELPERS
# ---------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}   $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
step()    { echo -e "\n${BOLD}${BLUE}====> $*${NC}"; }
ask()     { echo -e "${YELLOW}[?]${NC} $*"; }

banner() {
cat << 'EOF'
 ╔═══════════════════════════════════════════════════════════════╗
 ║   Arch Linux Installer — ThinkPad X1 Carbon Gen 8           ║
 ║   Hyprland · Btrfs · systemd-boot · zram · ML-ready         ║
 ║   github.com/darwin-garcia/Arch-Linux-Hyprland               ║
 ╚═══════════════════════════════════════════════════════════════╝
EOF
}

# ---------------------------------------------------------------------------
# CONFIGURACION — EDITAR ANTES DE EJECUTAR
# ---------------------------------------------------------------------------
DISK="/dev/nvme0n1"          # SSD Samsung NVMe — verificar con: lsblk
HOSTNAME="thinkpad-x1"
USERNAME="user"              # tu nombre de usuario
LOCALE="es_CO.UTF-8"        # Colombia
KEYMAP="la-latin1"          # teclado latinoamericano
TIMEZONE="America/Bogota"
DOTFILES_REPO="https://github.com/darwin-garcia/Arch-Linux-Hyprland.git"
DOTFILES_DIR="/tmp/dotfiles"

# Particiones que se crearán:
#   p1: EFI   512MB  FAT32   /boot/efi
#   p2: ROOT  resto  Btrfs   /  (subvolúmenes: @, @home, @snapshots, @var, @tmp)
EFI_SIZE="512MiB"

# ---------------------------------------------------------------------------
# VERIFICACIONES PREVIAS
# ---------------------------------------------------------------------------
pre_checks() {
    step "Verificaciones previas"

    # UEFI
    [[ -d /sys/firmware/efi ]] || error "No se detectó UEFI. Verifica que el equipo arranca en modo UEFI."
    ok "Modo UEFI confirmado"

    # Internet
    ping -c1 -W3 archlinux.org &>/dev/null || error "Sin conexión a internet. Conecta con: iwctl"
    ok "Conexión a internet activa"

    # Disco existe
    [[ -b "$DISK" ]] || error "Disco $DISK no encontrado. Verifica con: lsblk"
    ok "Disco $DISK detectado"

    # Tiempo sincronizado
    timedatectl set-ntp true
    ok "NTP activado"

    warn "ATENCIÓN: Este script BORRARÁ TODO en $DISK"
    echo -n "Escribe 'CONFIRMAR' para continuar: "
    read -r CONFIRM
    [[ "$CONFIRM" == "CONFIRMAR" ]] || error "Instalación cancelada."
}

# ---------------------------------------------------------------------------
# PASO 1 — PARTICIONADO
# ---------------------------------------------------------------------------
partition_disk() {
    step "Particionado del disco: $DISK"

    # Limpiar tabla de particiones
    sgdisk --zap-all "$DISK"
    sgdisk --clear "$DISK"

    # Crear particiones GPT
    sgdisk --new=1:0:+"$EFI_SIZE" --typecode=1:ef00 --change-name=1:"EFI"  "$DISK"
    sgdisk --new=2:0:0            --typecode=2:8300 --change-name=2:"ROOT" "$DISK"

    # Forzar redetección
    partprobe "$DISK"
    sleep 2

    ok "Particiones creadas:"
    lsblk "$DISK" --output NAME,SIZE,TYPE,FSTYPE
}

# ---------------------------------------------------------------------------
# PASO 2 — FORMATEO
# ---------------------------------------------------------------------------
format_partitions() {
    step "Formateo de particiones"

    local EFI_PART="${DISK}p1"
    local ROOT_PART="${DISK}p2"

    # EFI — FAT32
    mkfs.fat -F32 -n "EFI" "$EFI_PART"
    ok "EFI formateada: $EFI_PART (FAT32)"

    # ROOT — Btrfs
    mkfs.btrfs -f -L "ARCH" "$ROOT_PART"
    ok "ROOT formateada: $ROOT_PART (Btrfs)"

    # Crear subvolúmenes Btrfs
    mount "$ROOT_PART" /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@snapshots
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@tmp
    umount /mnt
    ok "Subvolúmenes Btrfs creados: @, @home, @snapshots, @var, @tmp"
}

# ---------------------------------------------------------------------------
# PASO 3 — MONTAJE
# ---------------------------------------------------------------------------
mount_partitions() {
    step "Montaje de particiones"

    local EFI_PART="${DISK}p1"
    local ROOT_PART="${DISK}p2"
    local BTRFS_OPTS="defaults,noatime,compress=zstd:3,space_cache=v2"

    # Montar subvolúmenes
    mount -o "${BTRFS_OPTS},subvol=@"         "$ROOT_PART" /mnt
    mkdir -p /mnt/{home,.snapshots,var,tmp,boot/efi}

    mount -o "${BTRFS_OPTS},subvol=@home"      "$ROOT_PART" /mnt/home
    mount -o "${BTRFS_OPTS},subvol=@snapshots" "$ROOT_PART" /mnt/.snapshots
    mount -o "${BTRFS_OPTS},subvol=@var"       "$ROOT_PART" /mnt/var
    mount -o "${BTRFS_OPTS},subvol=@tmp"       "$ROOT_PART" /mnt/tmp
    mount "$EFI_PART" /mnt/boot/efi

    ok "Particiones montadas:"
    findmnt --target /mnt --submounts
}

# ---------------------------------------------------------------------------
# PASO 4 — INSTALACIÓN BASE
# ---------------------------------------------------------------------------
install_base() {
    step "Instalación del sistema base"

    # Mirrors rápidos
    reflector --country Colombia,Brazil,US --age 12 --protocol https \
              --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || \
    reflector --country US,Brazil --age 12 --protocol https \
              --sort rate --save /etc/pacman.d/mirrorlist
    ok "Mirrors actualizados"

    # Paquetes base
    pacstrap -K /mnt \
        base base-devel linux linux-lts linux-firmware \
        btrfs-progs \
        intel-ucode \
        networkmanager \
        git curl wget \
        neovim nano \
        zsh \
        sudo \
        reflector \
        man-db man-pages \
        pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
        xdg-user-dirs xdg-utils \
        thermald tlp tlp-rdw \
        mesa intel-media-driver vulkan-intel \
        xf86-input-libinput \
        libva-intel-driver \
        fprintd libfprint \
        usbutils \
        snapper snap-pac
    ok "Sistema base instalado"
}

# ---------------------------------------------------------------------------
# PASO 5 — FSTAB
# ---------------------------------------------------------------------------
generate_fstab() {
    step "Generando fstab"
    genfstab -U /mnt >> /mnt/etc/fstab
    ok "fstab generado"
    cat /mnt/etc/fstab
}

# ---------------------------------------------------------------------------
# PASO 6 — CHROOT: configuración del sistema
# ---------------------------------------------------------------------------
configure_system() {
    step "Configurando sistema (chroot)"

    arch-chroot /mnt /bin/bash -s "$HOSTNAME" "$USERNAME" "$LOCALE" "$KEYMAP" \
        "$TIMEZONE" "$DISK" "$DOTFILES_REPO" "$DOTFILES_DIR" << 'CHROOT_END'

HOSTNAME="$1"; USERNAME="$2"; LOCALE="$3"; KEYMAP="$4"
TIMEZONE="$5"; DISK="$6"; DOTFILES_REPO="$7"; DOTFILES_DIR="$8"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
step() { echo -e "\n${BOLD}${CYAN}----> $*${NC}"; }

# --- Zona horaria ---
step "Zona horaria: $TIMEZONE"
ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
hwclock --systohc
ok "Zona horaria configurada"

# --- Locale ---
step "Configurando locale: $LOCALE"
sed -i "s/#${LOCALE}/${LOCALE}/" /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf
ok "Locale configurado"

# --- Hostname ---
step "Hostname: $HOSTNAME"
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF
ok "Hostname configurado"

# --- mkinitcpio (con btrfs) ---
step "Configurando mkinitcpio"
sed -i 's/^MODULES=.*/MODULES=(btrfs intel_agp i915)/' /etc/mkinitcpio.conf
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P
ok "initramfs generado"

# --- systemd-boot ---
step "Instalando systemd-boot"
bootctl install --esp-path=/boot/efi

ROOT_UUID=$(blkid -s UUID -o value "${DISK}p2")

mkdir -p /boot/efi/loader/entries

cat > /boot/efi/loader/loader.conf << EOF
default  arch-main.conf
timeout  3
console-mode max
editor   no
EOF

cat > /boot/efi/loader/entries/arch-main.conf << EOF
title   Arch Linux (linux-bore / ML optimizado)
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=${ROOT_UUID} rootflags=subvol=@ rw \\
        mitigations=off nowatchdog \\
        nohz_full=1-7 rcu_nocbs=1-7 \\
        processor.max_cstate=1 \\
        intel_pstate=active \\
        i915.enable_fbc=1 i915.enable_psr=1 \\
        pcie_aspm=off \\
        nvme_core.default_ps_max_hint=0
EOF

cat > /boot/efi/loader/entries/arch-lts.conf << EOF
title   Arch Linux LTS (fallback)
linux   /vmlinuz-linux-lts
initrd  /intel-ucode.img
initrd  /initramfs-linux-lts.img
options root=UUID=${ROOT_UUID} rootflags=subvol=@ rw quiet
EOF

ok "systemd-boot configurado"

# --- Usuario root password ---
step "Contraseña de root"
echo "Ingresa contraseña para root:"
passwd root

# --- Usuario normal ---
step "Creando usuario: $USERNAME"
useradd -m -G wheel,audio,video,input,storage,network -s /bin/zsh "$USERNAME"
echo "Ingresa contraseña para $USERNAME:"
passwd "$USERNAME"

# --- Sudo ---
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
ok "Sudo habilitado para grupo wheel"

# --- Servicios base ---
step "Habilitando servicios"
systemctl enable NetworkManager
systemctl enable thermald
systemctl enable tlp
systemctl enable fprintd
systemctl enable fstrim.timer
systemctl enable reflector.timer
ok "Servicios habilitados"

# --- zram ---
step "Configurando zram"
pacman -S --noconfirm --needed zram-generator
cat > /etc/systemd/zram-generator.conf << EOF
[zram0]
zram-size = ram * 3 / 4
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF
ok "zram configurado (12 GB comprimidos con zstd)"

# --- sysctl optimizaciones ML ---
step "Configurando sysctl para ML / rendimiento"
cat > /etc/sysctl.d/99-ml-perf.conf << EOF
vm.swappiness = 10
vm.dirty_ratio = 20
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 50
vm.overcommit_memory = 1
vm.overcommit_ratio = 80
kernel.nmi_watchdog = 0
EOF

# --- udev NVMe scheduler ---
step "Configurando I/O scheduler para NVMe"
cat > /etc/udev/rules.d/60-ioscheduler.rules << EOF
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="2048"
EOF
ok "I/O scheduler 'none' para NVMe"

# --- TLP configuración para i7-10610U ---
step "Configurando TLP para i7-10610U"
cat >> /etc/tlp.conf << EOF

# ThinkPad X1 Carbon Gen 8 — i7-10610U
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=schedutil
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0
CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=0
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
DISK_DEVICES="nvme0n1"
DISK_IDLE_SECS_ON_AC=0
DISK_IDLE_SECS_ON_BAT=2
EOF
ok "TLP configurado"

# --- THP madvise ---
cat > /etc/tmpfiles.d/thp.conf << EOF
w /sys/kernel/mm/transparent_hugepage/enabled - - - - madvise
EOF
ok "Transparent Huge Pages: madvise"

# --- pacman configuración ---
step "Configurando pacman"
sed -i 's/#Color/Color/'                  /etc/pacman.conf
sed -i 's/#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf
sed -i '/\[options\]/a ILoveCandy'        /etc/pacman.conf
ok "pacman configurado (color, paralelo, ILoveCandy)"

CHROOT_END
    ok "Configuración base del sistema completada"
}

# ---------------------------------------------------------------------------
# PASO 7 — INSTALAR HYPRLAND Y ENTORNO DE ESCRITORIO
# ---------------------------------------------------------------------------
install_desktop() {
    step "Instalando entorno Hyprland + dotfiles"

    arch-chroot /mnt /bin/bash -s "$USERNAME" "$DOTFILES_REPO" "$DOTFILES_DIR" << 'DESKTOP_END'
USERNAME="$1"; DOTFILES_REPO="$2"; DOTFILES_DIR="$3"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
step() { echo -e "\n${BOLD}${CYAN}----> $*${NC}"; }

step "Paquetes Hyprland y Wayland"
pacman -S --noconfirm --needed \
    hyprland \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    waybar \
    rofi \
    kitty \
    sddm \
    qt5-wayland qt6-wayland \
    polkit-kde-agent \
    swaylock swayidle \
    wl-clipboard cliphist \
    grim slurp \
    brightnessctl \
    playerctl \
    pamixer \
    network-manager-applet \
    bluez bluez-utils blueman \
    dunst \
    thunar thunar-volman gvfs \
    ranger \
    neovim \
    zsh \
    fzf \
    eza \
    fastfetch \
    conky \
    picom \
    papirus-icon-theme \
    noto-fonts noto-fonts-cjk noto-fonts-emoji \
    ttf-jetbrains-mono-nerd \
    ttf-font-awesome \
    imagemagick \
    mpv \
    okular \
    pavucontrol \
    nm-connection-editor
ok "Paquetes Hyprland instalados"

step "Habilitando servicios de escritorio"
systemctl enable sddm
systemctl enable bluetooth
ok "SDDM y Bluetooth habilitados"

step "Instalando yay (AUR helper)"
# yay se instala como usuario, no como root
su -l "$USERNAME" -s /bin/bash << YAYINSTALL
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg --noconfirm -si
YAYINSTALL
ok "yay instalado"

step "Paquetes AUR adicionales"
su -l "$USERNAME" -s /bin/bash << AURINSTALL
yay -S --noconfirm --needed \
    oh-my-zsh-git \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    zsh-history-substring-search \
    cava \
    galculator
AURINSTALL
ok "Paquetes AUR instalados"

step "Clonando dotfiles: $DOTFILES_REPO"
git clone --depth=1 "$DOTFILES_REPO" "$DOTFILES_DIR"
ok "Dotfiles descargados en $DOTFILES_DIR"

step "Instalando dotfiles en /home/$USERNAME/.config"
HOME_USER="/home/$USERNAME"
CONFIG_DIR="$HOME_USER/.config"
mkdir -p "$CONFIG_DIR"

# Copiar cada configuración del repositorio
for dir in hypr waybar kitty nvim rofi picom conky fastfetch cava bspwm sxhkd polybar; do
    if [[ -d "$DOTFILES_DIR/$dir" ]]; then
        cp -r "$DOTFILES_DIR/$dir" "$CONFIG_DIR/"
        ok "Copiado: $dir → $CONFIG_DIR/$dir"
    fi
done

# zshrc
if [[ -f "$DOTFILES_DIR/zshrc" ]]; then
    # Reemplazar username hardcodeado 'dangmoz' por el username real
    sed "s|dangmoz|$USERNAME|g" "$DOTFILES_DIR/zshrc" > "$HOME_USER/.zshrc"
    ok "zshrc instalado (usuario: $USERNAME)"
fi

# code-flags.conf para VSCode/Cursor con Wayland
if [[ -f "$DOTFILES_DIR/code-flags.conf" ]]; then
    mkdir -p "$HOME_USER/.config/code-flags"
    cp "$DOTFILES_DIR/code-flags.conf" "$HOME_USER/.config/"
    ok "code-flags.conf instalado (VSCode Wayland)"
fi

# Permisos correctos
chown -R "$USERNAME:$USERNAME" "$HOME_USER/.config"
chown "$USERNAME:$USERNAME" "$HOME_USER/.zshrc" 2>/dev/null || true
ok "Permisos aplicados"

step "Configurando zsh como shell por defecto"
chsh -s /bin/zsh "$USERNAME"
ok "Shell por defecto: zsh"

step "Directorios de usuario"
su -l "$USERNAME" -s /bin/bash -c "xdg-user-dirs-update"
mkdir -p "$HOME_USER"/{Documents,Downloads,Pictures,Music,Videos,Projects,ml-projects}
chown -R "$USERNAME:$USERNAME" "$HOME_USER"
ok "Directorios creados"

DESKTOP_END
    ok "Entorno de escritorio instalado"
}

# ---------------------------------------------------------------------------
# PASO 8 — STACK ML/DS (opcional, puede hacerse post-instalación)
# ---------------------------------------------------------------------------
install_ml_stack() {
    step "Instalando stack ML/Data Science base"

    arch-chroot /mnt /bin/bash -s "$USERNAME" << 'MLEND'
USERNAME="$1"
GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}   $*"; }
step() { echo -e "\n${BOLD}${CYAN}----> $*${NC}"; }

step "Instalando Miniconda para $USERNAME"
su -l "$USERNAME" -s /bin/bash << CONDAINSTALL
cd /tmp
curl -sLO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p /home/$USERNAME/miniconda3
/home/$USERNAME/miniconda3/bin/conda init zsh
/home/$USERNAME/miniconda3/bin/conda config --set auto_activate_base false

# Crear entorno ML optimizado para i7-10610U (AVX2, sin AVX-512)
/home/$USERNAME/miniconda3/bin/conda create -y -n mlenv python=3.11 \
    "numpy>=1.26" "scipy>=1.11" "scikit-learn>=1.3" \
    "pandas>=2.1" polars pyarrow \
    xgboost lightgbm \
    matplotlib seaborn plotly \
    jupyterlab ipywidgets \
    "blas=*=*openblas"

/home/$USERNAME/miniconda3/bin/conda run -n mlenv \
    pip install torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cpu

CONDAINSTALL
ok "Miniconda + entorno mlenv instalados"

MLEND
    ok "Stack ML instalado"
}

# ---------------------------------------------------------------------------
# PASO 9 — HUELLA DIGITAL THINKPAD (opcional)
# ---------------------------------------------------------------------------
setup_fingerprint() {
    step "Configuración de lector de huellas (ThinkPad)"

    arch-chroot /mnt /bin/bash << 'FPEND'
# Habilitar PAM para huella
if ! grep -q "pam_fprintd" /etc/pam.d/system-local-login 2>/dev/null; then
    echo "auth sufficient pam_fprintd.so" >> /etc/pam.d/system-local-login
fi
echo -e "\033[0;32m[OK]\033[0m   PAM fprintd configurado"
echo -e "\033[1;33m[INFO]\033[0m Post-instalación: ejecuta 'fprintd-enroll \$USER' para registrar huella"
FPEND
}

# ---------------------------------------------------------------------------
# PASO 10 — RESUMEN FINAL
# ---------------------------------------------------------------------------
final_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    cat << 'EOF'
 ╔═══════════════════════════════════════════════════════════════╗
 ║              INSTALACIÓN COMPLETADA                          ║
 ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    ok "Sistema instalado correctamente"
    echo ""
    echo -e "${CYAN}Lo que fue instalado:${NC}"
    echo "  • Arch Linux base + linux + linux-lts"
    echo "  • Btrfs con subvolúmenes: @, @home, @snapshots, @var, @tmp"
    echo "  • systemd-boot con entradas: arch-main y arch-lts"
    echo "  • zram (12 GB, zstd) — sin partición swap"
    echo "  • Hyprland + Waybar + Rofi + Kitty + Ranger + LazyVim"
    echo "  • Oh-My-Zsh + plugins (autosuggestions, syntax-highlighting)"
    echo "  • Dotfiles de github.com/darwin-garcia/Arch-Linux-Hyprland"
    echo "  • SDDM (display manager)"
    echo "  • Intel UHD 620 drivers (mesa, vulkan-intel)"
    echo "  • TLP + thermald (optimizado para i7-10610U)"
    echo "  • fprintd (lector de huellas ThinkPad)"
    echo "  • Miniconda + entorno mlenv (NumPy, sklearn, PyTorch-CPU)"
    echo ""
    echo -e "${YELLOW}Pasos post-instalación:${NC}"
    echo "  1. umount -R /mnt && reboot"
    echo "  2. Iniciar sesión como $USERNAME"
    echo "  3. Registrar huella: fprintd-enroll \$USER"
    echo "  4. Conectar WiFi: nmtui"
    echo "  5. Instalar kernel-bore: yay -S linux-bore linux-bore-headers"
    echo "     Luego agregar entrada en /boot/efi/loader/entries/arch-bore.conf"
    echo "  6. Activar entorno ML: conda activate mlenv"
    echo ""
    echo -e "${CYAN}Dotfiles ubicados en:${NC} /home/$USERNAME/.config/"
    echo -e "${CYAN}Repositorio:${NC} $DOTFILES_REPO"
    echo ""
}

# ---------------------------------------------------------------------------
# MENÚ INTERACTIVO
# ---------------------------------------------------------------------------
interactive_menu() {
    banner
    echo ""
    echo -e "${BOLD}Configuración detectada:${NC}"
    echo "  Disco:    $DISK"
    echo "  Hostname: $HOSTNAME"
    echo "  Usuario:  $USERNAME"
    echo "  Locale:   $LOCALE"
    echo "  Timezone: $TIMEZONE"
    echo ""
    echo -e "${YELLOW}¿Quieres cambiar algún valor antes de continuar? (s/N):${NC} "
    read -r CHANGE
    if [[ "$CHANGE" =~ ^[sS]$ ]]; then
        echo -n "Disco (actual: $DISK): "; read -r INPUT; [[ -n "$INPUT" ]] && DISK="$INPUT"
        echo -n "Hostname (actual: $HOSTNAME): "; read -r INPUT; [[ -n "$INPUT" ]] && HOSTNAME="$INPUT"
        echo -n "Usuario (actual: $USERNAME): "; read -r INPUT; [[ -n "$INPUT" ]] && USERNAME="$INPUT"
        echo -n "Timezone (actual: $TIMEZONE): "; read -r INPUT; [[ -n "$INPUT" ]] && TIMEZONE="$INPUT"
    fi

    echo ""
    echo -e "${CYAN}¿Instalar stack ML/Data Science? (scikit-learn, PyTorch, Polars) [S/n]:${NC} "
    read -r INSTALL_ML
    echo -e "${CYAN}¿Configurar lector de huellas ThinkPad? [S/n]:${NC} "
    read -r INSTALL_FP
}

# ---------------------------------------------------------------------------
# EJECUCIÓN PRINCIPAL
# ---------------------------------------------------------------------------
main() {
    # Requiere root
    [[ $EUID -eq 0 ]] || error "Ejecuta como root: sudo bash $0"

    interactive_menu
    pre_checks
    partition_disk
    format_partitions
    mount_partitions
    install_base
    generate_fstab
    configure_system
    install_desktop

    [[ ! "$INSTALL_ML" =~ ^[nN]$ ]] && install_ml_stack
    [[ ! "$INSTALL_FP" =~ ^[nN]$ ]] && setup_fingerprint

    final_summary
}

main "$@"
