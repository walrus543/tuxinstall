#!/bin/bash

# On quitte tout de suite si le script est exécuté en tant que root
if [[ $(whoami) == 'root' ]]; then
    echo "\${RED}Do not run this script as root, use a user with sudo rights\${RESET}"
    exit 1
fi

#Coloration du texte
export RESET=$(tput sgr0)
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export BLUE=$(tput setaf 4)

echo ""
echo ${BLUE}----------------------------------------------------
echo Assistant pour reconfigurer ARCH Plasma après un formatage
echo ----------------------------------------------------${RESET}
echo ""

# get confirmation
read -t 15 -N 1 -p "Prêt à faire la post install de Arch sur KDE Plasma?. On continue? (y/N) " start
echo 
 
# if answer is yes within 15 seconds start installing...
if [ "${start,,}" == "y" ]
then
    echo ${BLUE}Config pacman${RESET}
    sudo sed -i '/^#ParallelDownloads/a ILoveCandy' /etc/pacman.conf
    sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
    
    echo ${BLUE}Actualisation des dépôts et mises à jour${RESET}
    sudo pacman -Syu
    
    echo ${BLUE}Installation de paquets relatifs à OSHeden${RESET}
    sudo pacman -S --needed dos2unix xclip xsel npm fdupes
    
    if [ -d ~/AndroidAll/Thèmes_Shorts/ ]
        then echo ${BLUE}Creation des liens symboliques pour les thèmes${RESET}
        ln -s /home/arnaud/Thèmes/Alta/app/src/main/ /AndroidAll/Thèmes_Shorts/Alta
        ln -s /home/arnaud/Thèmes/Altess/app/src/main /AndroidAll/Thèmes_Shorts/Altess
        ln -s /home/arnaud/Thèmes/Azulox/app/src/main/ /AndroidAll/Thèmes_Shorts/Azulox
        ln -s /home/arnaud/Thèmes/Black_Army_Diamond/app/src/main/ /AndroidAll/Thèmes_Shorts/BlackArmyDiamond
        ln -s /home/arnaud/Thèmes/Black_Army_Emerald/app/src/main/ /AndroidAll/Thèmes_Shorts/BlackArmyEmerald
        ln -s /home/arnaud/Thèmes/Black_Army_Omni/app/src/main/ /AndroidAll/Thèmes_Shorts/BlackArmyOmni
        ln -s /home/arnaud/Thèmes/Black_Army_Ruby/app/src/main/ /AndroidAll/Thèmes_Shorts/BlackArmyRuby
        ln -s /home/arnaud/Thèmes/Black_Army_Sapphire/app/src/main/ /AndroidAll/Thèmes_Shorts/BlackArmySapphire
        ln -s /home/arnaud/Thèmes/Caya/app/src/main/ /AndroidAll/Thèmes_Shorts/Caya
        ln -s /home/arnaud/Thèmes/Ciclo/app/src/main/ /AndroidAll/Thèmes_Shorts/Ciclo
        ln -s /home/arnaud/Thèmes/Darky/app/src/main/ /AndroidAll/Thèmes_Shorts/Darky
        ln -s /home/arnaud/Thèmes/Darly/app/src/main/ /AndroidAll/Thèmes_Shorts/Darly
        ln -s /home/arnaud/Thèmes/Distraction_Free/app/src/main/ /AndroidAll/Thèmes_Shorts/Distraction
        ln -s /home/arnaud/Thèmes/Ecliptic/app/src/main/ /AndroidAll/Thèmes_Shorts/Ecliptic
        ln -s /home/arnaud/Thèmes/Friendly/app/src/main/ /AndroidAll/Thèmes_Shorts/Friendly
        ln -s /home/arnaud/Thèmes/GIN/app/src/main/ /AndroidAll/Thèmes_Shorts/GIN
        ln -s /home/arnaud/Thèmes/GoldOx/app/src/main/ /AndroidAll/Thèmes_Shorts/GoldOx
        ln -s /home/arnaud/Thèmes/Goody/app/src/main/ /AndroidAll/Thèmes_Shorts/Goody
        ln -s /home/arnaud/Thèmes/Lox/app/src/main/ /AndroidAll/Thèmes_Shorts/Lox
        ln -s /home/arnaud/Thèmes/Luzicon/app/src/main/ /AndroidAll/Thèmes_Shorts/Luzicon
        ln -s /home/arnaud/Thèmes/NubeReloaded/app/src/main/ /AndroidAll/Thèmes_Shorts/NubeReloaded
        ln -s /home/arnaud/Thèmes/Oscuro/app/src/main/ /AndroidAll/Thèmes_Shorts/Oscuro
        ln -s /home/arnaud/Thèmes/Raya_Black/app/src/main/ /AndroidAll/Thèmes_Shorts/RayaBlack
        ln -s /home/arnaud/Thèmes/RayaReloaded/app/src/main/ /AndroidAll/Thèmes_Shorts/RayaReloaded
        ln -s /home/arnaud/Thèmes/Shapy/app/src/main/ /AndroidAll/Thèmes_Shorts/Shapy
        ln -s /home/arnaud/Thèmes/Sinfonia/app/src/main/ /AndroidAll/Thèmes_Shorts/Sinfonia
        ln -s /home/arnaud/Thèmes/Spark/app/src/main/ /AndroidAll/Thèmes_Shorts/Spark
        ln -s /home/arnaud/Thèmes/Stony/app/src/main/ /AndroidAll/Thèmes_Shorts/Stony
        ln -s /home/arnaud/Thèmes/Supernova/app/src/main/ /AndroidAll/Thèmes_Shorts/Supernova
        ln -s /home/arnaud/Thèmes/Whirl/app/src/main/ /AndroidAll/Thèmes_Shorts/Whirl
        ln -s /home/arnaud/Thèmes/WhirlBlack/app/src/main/ /AndroidAll/Thèmes_Shorts/WhirlBlack
        ln -s /home/arnaud/Thèmes/Whirless/app/src/main /AndroidAll/Thèmes_Shorts/Whirless
        ln -s /home/arnaud/Thèmes/WhitArt/app/src/main/ /AndroidAll/Thèmes_Shorts/WhitArt
        ln -s /home/arnaud/Thèmes/Whity/app/src/main/ /AndroidAll/Thèmes_Shorts/Whity
    fi
    
    echo ${BLUE}Installation de divers utilitaires généraux${RESET}
    sudo pacman -S --needed bat btop duf element-desktop eza syncthing fastfetch firefox flameshot kdeconnect kio-admin meld ncdu obsidian pdfarranger samba simple-scan smbclient systemdgenie telegram-desktop thunar thunderbird timeshift transmission-qt yt-dlp
    
    echo ${BLUE}Installation de divers paquets propres à Arch${RESET}
    sudo pacman -S --needed adobe-source-han-sans-cn-fonts adobe-source-han-sans-jp-fonts adobe-source-han-sans-kr-fonts android-tools cups dkms dosfstools firefox flatpak gwenview jre-openjdk-headless kcalc kimageformats kwallet libreoffice-{fresh,fresh-fr} linux-lts-headers man-pages ntfs-3g okular p7zip pacman-contrib perl-rename pkgfile print-manager qt5-imageformats xdg-desktop-portal-gtk
    
    paru --version; if echo $? = 0;
    then
        echo ${GREEN}paru déjà installé${RESET}
    else
        echo ${BLUE}Installation de paru${RESET}
        sudo pacman -S --needed git base-devel
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si
    fi
        # Que paru soit installé ou pas, on contrôle les news
        echo ${BLUE}Paru NewsOnUpdate${RESET}
        sudo sed -i 's/^#NewsOnUpdate/NewsOnUpdate/' /etc/paru.conf
        
    echo ${BLUE}Installation de paquets avec paru${RESET}
    paru -S --needed brave-bin cnijfilter2-mg7500 downgrade payload-dumper-go-bin protonmail-bridge-bin reflector-simple rtl8821ce-dkms-git uniutils pika-backup
    
    echo ${BLUE}Gestion de la carte réseau Realtek${RESET}
    echo "# https://github.com/tomaspinho/rtl8821ce/tree/master#wi-fi-not-working-for-kernel--59" | sudo tee -a /etc/modprobe.d/blacklist.conf > /dev/null
    echo "blacklist rtw88_8821ce" | sudo tee -a /etc/modprobe.d/blacklist.conf > /dev/null
    
    echo ${BLUE}"Activation de l'imprimante et du bluetooth au démarrage"${RESET}
    sudo systemctl enable --now cups.socket
    sudo systemctl enable cups.service
    sudo systemctl enable --now bluetooth.service
    
    echo ${BLUE}Installation de VirtualBox pour linux et linux-lts${RESET}
    sudo pacman -S --needed virtualbox virtualbox-guest-iso virtualbox-host-dkms
    
    echo ${BLUE}Activation du nettoyage du cache des paquets${RESET}
    sudo systemctl enable paccache.timer
    
    echo ${BLUE}Installation de paquets pour carte graphique NVIDIA${RESET}
    sudo pacman -S --needed nvidia nvidia-lts nvidia-utils nvidia-settings vulkan-icd-loader
    
    echo ${BLUE}Installation du dépôt officiel Flatpak${RESET}
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    
    echo ${BLUE}Installation de ZSH et configuration${RESET}
    sudo pacman -S --needed zsh
    
    echo ${BLUE}Oh My ZSH${RESET}
    [[ -d ~/.oh-my-zsh ]] && echo ${GREEN}Oh My ZSH déjà installé${RESET} || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    
    echo ${BLUE}Installation zsh-autosuggestions${RESET}
    [[ -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]] && echo ${GREEN}zsh-autosuggestions déjà installé${RESET} || git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    
    echo ${BLUE}Installation zsh-syntax-highlighting${RESET}
    [[ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]] && echo ${GREEN}zsh-syntax-highlighting déjà installé${RESET} || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    
    echo ${BLUE}Installation du thème powerlevel10k${RESET}
    [[ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]] && echo ${GREEN}powerlevel10k déjà installé${RESET} || git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    
    echo ${BLUE}Désactiver le bruit lors de la recherche${RESET}
    if grep -Fxq "blacklist pcspkr" /etc/modprobe.d/nobeep.conf;
    then echo ${GREEN}"Blacklist pcspkr déjà configuré"${RESET}
    else echo "blacklist pcspkr" | sudo tee -a /etc/modprobe.d/nobeep.conf > /dev/null
    fi
    if grep -Fxq "blacklist snd_pcsp" /etc/modprobe.d/nobeep.conf;
    then echo ${GREEN}"Blacklist snd_pcsp déjà configuré"${RESET}
    else echo "blacklist snd_pcsp" | sudo tee -a /etc/modprobe.d/nobeep.conf > /dev/null
    fi
    
    echo ${BLUE}Activation du pavé numérique pour SDDM${RESET}
    if grep -Fxq "Numlock=on" /etc/sddm.conf;
    then echo ${GREEN}"Pavé numérique déjà configuré"${RESET}
    else echo "[General]" | sudo tee -a /etc/sddm.conf > /dev/null && echo "Numlock=on" | sudo tee -a /etc/sddm.conf > /dev/null
    fi
    
    echo ${BLUE}Syncthing au démarrage${RESET}
    sudo systemctl --user enable syncthing.service
    sudo systemctl --user start syncthing.service
    
    echo ${BLUE}Config bash et zsh${RESET}
    if grep -Fxq "if [ -f ~/.bash_aliases ]; then" ~/.bashrc;
    then
        echo ${GREEN}config bash ok${RESET}
    else
        echo "if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi" | sudo tee -a ~/.bashrc > /dev/null
    fi
    
    if grep -Fxq "source $HOME/.bash_aliases" ~/.zshrc;
    then echo source bash_aliases déjà ok${RESET}
    else echo "source $HOME/.bash_aliases" | sudo tee -a ~/.zshrc > /dev/null && echo bash_aliases ajouté dans le fichier de configuration .zshrc
    fi
    
    if grep -Fxq "alias lsl" ~/.zshrc;
    then echo ${GREEN}"l'alias lsl existe déjà"${RESET}
    else echo "alias lsl='eza -la --color=always --group-directories-first'" | sudo tee -a ~/.zshrc > /dev/null
    fi
    
    sed -i 's/^ZSH_THEME.*$/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/' ~/.zshrc
    sed -i 's/^plugins=(git).*$/plugins=(\ngit\nzsh-autosuggestions\nzsh-syntax-highlighting\n)/' ~/.zshrc
    
    echo ${BLUE}Nettoyage de tuxinstall${RESET}
    rm -rf ~/tuxinstall
else
    echo "Pas de soucis, on s'arrête là :-)"
fi
