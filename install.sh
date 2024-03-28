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

if [ -d ~/AndroidAll/Thèmes_Shorts/ ]
    then echo Creation des liens symboliques pour les thèmes
    ln -s /home/arnaud/Thèmes/Alta/app/src/main/ Alta
    ln -s /home/arnaud/Thèmes/Altess/app/src/main Altess
    ln -s /home/arnaud/Thèmes/Azulox/app/src/main/ Azulox
    ln -s /home/arnaud/Thèmes/Black_Army_Diamond/app/src/main/ BlackArmyDiamond
    ln -s /home/arnaud/Thèmes/Black_Army_Emerald/app/src/main/ BlackArmyEmerald
    ln -s /home/arnaud/Thèmes/Black_Army_Omni/app/src/main/ BlackArmyOmni
    ln -s /home/arnaud/Thèmes/Black_Army_Ruby/app/src/main/ BlackArmyRuby
    ln -s /home/arnaud/Thèmes/Black_Army_Sapphire/app/src/main/ BlackArmySapphire
    ln -s /home/arnaud/Thèmes/Caya/app/src/main/ Caya
    ln -s /home/arnaud/Thèmes/Ciclo/app/src/main/ Ciclo
    ln -s /home/arnaud/Thèmes/Darky/app/src/main/ Darky
    ln -s /home/arnaud/Thèmes/Darly/app/src/main/ Darly
    ln -s /home/arnaud/Thèmes/Distraction_Free/app/src/main/ Distraction
    ln -s /home/arnaud/Thèmes/Ecliptic/app/src/main/ Ecliptic
    ln -s /home/arnaud/Thèmes/Friendly/app/src/main/ Friendly
    ln -s /home/arnaud/Thèmes/GIN/app/src/main/ GIN
    ln -s /home/arnaud/Thèmes/GoldOx/app/src/main/ GoldOx
    ln -s /home/arnaud/Thèmes/Goody/app/src/main/ Goody
    ln -s /home/arnaud/Thèmes/Lox/app/src/main/ Lox
    ln -s /home/arnaud/Thèmes/Luzicon/app/src/main/ Luzicon
    ln -s /home/arnaud/Thèmes/NubeReloaded/app/src/main/ NubeReloaded
    ln -s /home/arnaud/Thèmes/Oscuro/app/src/main/ Oscuro
    ln -s /home/arnaud/Thèmes/Raya_Black/app/src/main/ RayaBlack
    ln -s /home/arnaud/Thèmes/RayaReloaded/app/src/main/ RayaReloaded
    ln -s /home/arnaud/Thèmes/Shapy/app/src/main/ Shapy
    ln -s /home/arnaud/Thèmes/Sinfonia/app/src/main/ Sinfonia
    ln -s /home/arnaud/Thèmes/Spark/app/src/main/ Spark
    ln -s /home/arnaud/Thèmes/Stony/app/src/main/ Stony
    ln -s /home/arnaud/Thèmes/Supernova/app/src/main/ Supernova
    ln -s /home/arnaud/Thèmes/Whirl/app/src/main/ Whirl
    ln -s /home/arnaud/Thèmes/WhirlBlack/app/src/main/ WhirlBlack
    ln -s /home/arnaud/Thèmes/Whirless/app/src/main Whirless
    ln -s /home/arnaud/Thèmes/WhitArt/app/src/main/ WhitArt
    ln -s /home/arnaud/Thèmes/Whity/app/src/main/ Whity
fi

echo Installation de divers utilitaires généraux
sudo pacman -S --needed bat btop duf element-desktop eza syncthing fastfetch firefox flameshot kdeconnect kio-admin meld ncdu obsidian pdfarranger samba simple-scan smbclient systemdgenie telegram-desktop thunar thunderbird timeshift transmission-qt yt-dlp

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
paru -S brave-bin cnijfilter2-mg7500 downgrade payload-dumper-go-bin protonmail-bridge-bin reflector-simple rtl8821ce-dkms-git uniutils pika-backup

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

echo Activation du pavé numérique
echo "[General]" | sudo tee -a /etc/sddm.conf > /dev/null
echo "Numlock=on" | sudo tee -a /etc/sddm.conf > /dev/null

echo Syncthing
sudo systemctl --user enable syncthing.service
sudo systemctl --user start syncthing.service

echo Config bash et zsh
cat <<EOF >> ~/.bashrc
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
EOF

echo "source $HOME/.bash_aliases" | sudo tee -a ~/.zshrc > /dev/null
echo "alias lsl='eza -la --color=always --group-directories-first'" | sudo tee -a ~/.zshrc > /dev/null
sed 's/^ZSH_THEME.*$/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/' ~/.zshrc
sed 's/^plugins=.*$/plugins=(\ngit\nzsh-autosuggestions\nzsh-syntax-highlighting\n)/' ~/.zshrc

echo Nettoyage de tuxinstall
rm -rf ~/tuxinstall
