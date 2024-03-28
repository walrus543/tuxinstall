#!/bin/bash

# On quitte tout de suite si le script est exécuté en tant que root
if [[ $(whoami) == 'root' ]]; then
    echo "\${RED}Do not run this script as root, use a user with sudo rights\${RESET}"
    exit 1
fi

echo ----------------------------------------------------
echo Assistant pour reconfigurer ARCH Plasma après un formatage
echo ----------------------------------------------------

echo Config pacman
sudo sed -i '/^#ParallelDownloads/a ILoveCandy' /etc/pacman.conf
sudo sed -i '/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf

echo Actualisation des dépôts et mises à jour
sudo pacman -Syu

echo Installation de paquets relatifs à OSHeden
sudo pacman -S --needed dos2unix xclip xsel npm fdupes

echo Installation de divers utilitaires généraux
sudo pacman -S --needed bat btop duf element-desktop eza fastfetch firefox flameshot kdeconnect kio-admin meld ncdu pdfarranger simple-scan systemdgenie telegram-desktop thunar thunderbird timeshift transmission-qt yt-dlp

echo Installation de divers paquets propres à Arch
sudo pacman -S --needed adobe-source-han-sans-cn-fonts adobe-source-han-sans-jp-fonts adobe-source-han-sans-kr-fonts android-tools cups dkms dosfstools firefox flatpak gwenview jre-openjdk-headless kcalc kimageformats kwallet libreoffice-{fresh,fresh-fr} linux-lts-headers man-pages ntfs-3g okular p7zip pacman-contrib perl-rename pkgfile print-manager qt5-imageformats xdg-desktop-portal-gtk

echo Installation de paru
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

echo Paru NewsOnUpdate
sudo sed -i '/^#NewsOnUpdate/NewsOnUpdate/' /etc/paru.conf

echo Installation de paquets avec paru
paru -S brave-bin cnijfilter2-mg7500 downgrade payload-dumper-go-bin protonmail-bridge-bin reflector-simple rtl8821ce-dkms-git uniutils

echo Gestion de la carte réseau Realtek
echo "# https://github.com/tomaspinho/rtl8821ce/tree/master#wi-fi-not-working-for-kernel--59" | sudo tee -a /etc/modprobe.d/blacklist.conf > /dev/null
echo "blacklist rtw88_8821ce" | sudo tee -a /etc/modprobe.d/blacklist.conf > /dev/null

echo "Activation de l'imprimante et du bluetooth au démarrage"
sudo systemctl enable --now cups.socket
sudo systemctl enable cups.service
sudo systemctl enable --now bluetooth.service

echo Installation de VirtualBox pour linux et linux-lts
sudo pacman -S virtualbox virtualbox-guest-iso virtualbox-host-modules-arch virtualbox-host-dkms

echo Activation du nettoyage du cache des paquets
sudo systemctl enable paccache.timer

echo Installation de paquets pour carte graphique NVIDIA
sudo pacman -S --needed nvidia nvidia-lts nvidia-utils nvidia-settings vulkan-icd-loader

echo Installation du dépôt officiel Flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo Installation de ZSH et configuration
sudo pacman -S zsh
#definir zsh par défaut

echo Installation Oh My ZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo Installation zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

echo Installation zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo Installation du thème powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo Désactiver le bruit lors de la recherche
echo "blacklist pcspkr" | sudo tee -a /etc/modprobe.d/nobeep.conf > /dev/null
echo "blacklist snd_pcsp" | sudo tee -a /etc/modprobe.d/nobeep.conf > /dev/null

echo Nettoyage de tuxinstall
rm -rf ~/tuxinstall

#TODO
#Anomalie Wifi Realtek Lenovo L340
#pika - source actuelle ?
#obsidian
#syncthing
#pavé numérique
#samba/smb
#zsh: config du fichier, activation plugin, thème...

#sudo pacman -S --needed git base-devel && git clone https://github.com/Cardiacman13/Architect.git ~/Architect && cd ~/Architect && chmod +x ./architect.sh && ./architect.sh
