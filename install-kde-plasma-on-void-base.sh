#!/usr/bin/env bash
# A simple script to get a vanilla KDE Plasma desktop on Void Linux
# Version 1.0.1, updated 14-12-2022
# Original version at https://github.com/asifakonjee/Void-Linux-KDE
#
# Improved version by Hotodogo (Thanks to u/WanderinChild)
# Version 2.0.1, updated 05-05-2026
# To output a run of the script to a log, invoke with "bash /path/to/this-script.sh | tee KDElog.txt"

NC="\033[0m"
WHITE="\033[1;37m"
CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
YELLOW_BOLD="\033[1;33m"
RED="\033[0;31m"
PURPLE="\033[0;35m"

qmsg() {
  local type="$1"
  shift
  local msg="$*"
  case "$type" in
    -e|--error)     printf "${WHITE}[ ${RED}ERRO${WHITE} ] ${RED}%s${NC}\n" "$msg" >&2 ;;
    -w|--warning)   printf "${WHITE}[ ${YELLOW}WARN${WHITE} ] ${YELLOW}%s${NC}\n" "$msg" >&2 ;;
    -i|--info)      printf "${WHITE}[ ${CYAN}INFO${WHITE} ] ${CYAN}%s${NC}\n" "$msg" >&2 ;;
    -s|--success)   printf "${WHITE}[ ${GREEN}SUCC${WHITE} ] ${GREEN}%s${NC}\n" "$msg" >&2 ;;
    -H|--header)    printf "${WHITE}[ ${YELLOW}HEAD${WHITE} ] ${YELLOW_BOLD}%s${NC}\n" "$msg" >&2 ;;
    -I|--important) printf "${WHITE}[ ${YELLOW}IMPT${WHITE} ] ${YELLOW}%s${NC}\n" "$msg" >&2 ;;
    -c|--cmd)       printf "${WHITE}[ ${PURPLE}CMDS${WHITE} ] ${PURPLE}%s${NC}\n" "$msg" >&2 ;;
    -o|--ok)        printf "${WHITE}[ ${GREEN} OK ${WHITE} ] ${WHITE}%s${NC}\n" "$msg" >&2 ;;
    -C|--caution)   printf "${WHITE}[ ${RED}CAUT${WHITE} ] ${RED}%s${NC}\n" "$msg" >&2 ;;
    -p|--plain)     printf "${WHITE}%s${NC}\n" "$msg" >&2 ;;
    *)              printf "%s\n" "$msg" ;;
  esac
}

bypass() {
  sudo -v
  while true;
  do
    sudo -n true
    sleep 45
    kill -0 "$$" || exit
  done 2>/dev/null &
}

ask_yes_no() {
  local prompt="$1"
  local default="$2"
  local ans=""
  if [ -t 0 ] && [ -t 1 ] && [ -e /dev/tty ]; then
    printf "${CYAN}%s${NC} " "$prompt" >/dev/tty
    read -r ans < /dev/tty 2>/dev/tty || true
  fi
  if [ -z "$ans" ]; then
    [ "$default" = "y" ]
    return
  fi
  [[ "$ans" =~ ^[Yy] ]]
}

install_pkgs() {
  local pkgs=("$@")
  if [ "${#pkgs[@]}" -eq 0 ]; then
    qmsg -e "No packages to install."
    return
  fi
  for p in "${pkgs[@]}"; do
    qmsg -i "Installing $p"
    if ! sudo xbps-install -y "$p"; then
      qmsg -e "Failed to install $p"
    fi
  done
}

if ask_yes_no "Welcome to a simple script to get a vanilla KDE Plasma Desktop on Void Linux. Would you like to continue [y/N]?" "N"; then

  if ask_yes_no "Would you like to perform a system upgrade before continuing [y/N]?" "N"; then
    qmsg -H "Upgrading system..."
    sudo xbps-install -Su
  else
    qmsg -w "Skipping system upgrade."
  fi

  qmsg -i "Installing xmirror"
  install_pkgs xmirror
  
  if ask_yes_no "Run xmirror to switch repository mirror? [Y/n] " "y"; then
    echo -H "Running xmirror"
    sudo xmirror
    qmsg -H "Upgrading system..."
    sudo xbps-install -Su
  fi

  qmsg -H "Installing non-free and multilib repos..."
  install_pkgs void-repo-nonfree
  # install_pkgs void-repo-multilib void-repo-multilib-nonfree
  
  qmsg -H "Preparing to install packages..."
  
  qmsg -H "Installing build essentials and kernel headers..."
  install_pkgs base-devel make cmake
  
  qmsg -H "Installing language libraries..."
  sudo xbps-insyall -y rust cargo python3 python3-pip ruby
  
  qmsg -H "Installing fonts..."
  install_pkgs fontconfig font-iosevka ttf-material-icons nerd-fonts ttf-ubuntu-font-family terminus-font dejavu-fonts-ttf
  
  qmsg -H "Installing audio packages..."
  install_pkgs pipewire wireplumber alsa-utils alsa-pipewire libjack-pipewire ffmpeg ffmpegthumbs
  
  qmsg -H "Installing desktop environment (KDE Plasma)..."
  install_pkgs xorg xdg-user-dirs xdg-utils xtools kde-plasma kde-baseapps NetworkManager
  
  qmsg -H "Installing graphics drivers (Intel Core CPU)..."
  install_pkgs intel-video-accel mesa-intel-dri mesa-vulkan-intel vulkan-loader
  
  # install_pkgs mesa-vaapi mesa-vdpau
  qmsg -H "Installing utilities and system tools..."
  install_pkgs linux-firmware
  install_pkgs zsh rsync openssh git rsync newt ntp eza curl wget plymouth preload bluez nss-mdns avahi polkit acl acl-progs psmisc elogind perl-rename dbus bash-completion htop ncdu bat fastfetch aria2 dos2unix shellcheck progress jpegoptim
  install_pkgs procps-ng udisks2 partclone exfatprogs gvfs gvfs-mtp gzip unzip zip p7zip xz zstd ntfs-3g
  
  qmsg -H "Installing additional applications..."
  install_pkgs figlet pandoc
  install_pkgs filelight kcalc kcharselect kdeconnect partitionmanager kfind kwalletmanager
  install_pkgs alacritty ark kvantum timeshift qt5-devel grub-customizer fbv telegram-desktop hplip octoxbps qbittorrent papirus-icon-theme
  # Edit the following list of additional applications or replace them with your own preferences
  if ask_yes_no "Do you want to install fcitx5 stuff? [y/N]" "N"; then
    install_pkgs fcitx5 fcitx5-chinese-addons fcitx5-rime fcitx5-im fcitx5-qt fcitx5-gtk fcitx5-gtk+3 fcitx5-gtk4 fcitx5-chinese-addons fcitx5-lua unicode-cldr fcitx5-configtool
  fi

  # Code editor
  qmsg -H "Installing Text Editors..."
  install_pkgs nano kwrite micro kate neovim nano
  
  # PDF reader
  qmsg -H "Installing PDF Reader..."
  install_pkgs okular
  
  # Web browser
  qmsg -H "Installing Firefox..."
  install_pkgs firefox
  
  # Screenshot utility
  qmsg -H "Installing Spectacle..."
  install_pkgs spectacle
  
  # Image viewer
  qmsg -H "Installing Gwenview..."
  install_pkgs gwenview

  # Office suite
  # qmsg -H "Installing LibreOffice..."
  # install_pkgs libreoffice
  # Audio and video player
  
  qmsg -H "Installing Video Player..."
  install_pkgs mpv

  if ask_yes_no "Do you want to install qemu guest tools? [y/N]" "N"; then
    # install_pkgs qemu libvirt virt-manager bridge-utils
    install_pkgs qemu-ga libguestfs spice-vdagent xf86-video-qxl
  fi

  qmsg -H "Configuring system..."
  qmsg -H "Setting up services (dbus, sddm, NetworkManager, bluetoothd)..."
  sudo sed -i "s/--noclear/--noclear\ --skip-login\ --login-options=$USER/g" /etc/sv/agetty-tty1/conf
  sudo rm -f /var/service/agetty-tty{3,4,5,6}
  sudo ln -s /etc/sv/dbus /var/service/
  sudo ln -s /etc/sv/sddm /var/service/
  sudo ln -s /etc/sv/NetworkManager /var/service/
  sudo ln -s /etc/sv/bluetoothd /var/service/

  # Starting services shouldn't be necessary, so commenting out all service start commands.
  # qmsg -H "Starting services..."
  # sudo sv up dbus
  # sudo sv up sddm
  # sudo sv up NetworkManager

  # Set up PipeWire and PulseAudio
  qmsg -H "Setting up PipeWire and PulseAudio..."
  sudo mkdir -p /etc/pipewire/pipewire.conf.d
  sudo ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
  sudo ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/
  sudo ln -s /usr/share/applications/pipewire.desktop /etc/xdg/autostart/

  qmsg -I "All done! Please reboot for all changes to take effect."

  # User does not want to continue installation.
else
  qmsg -i "Thanks for trying, Goodbye!"
fi
