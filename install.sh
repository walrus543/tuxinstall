#!/bin/bash

#Coloration du texte
export RESET=$(tput sgr0)
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export BLUE=$(tput setaf 4)

# On quitte tout de suite si le script est exécuté en tant que root
if [[ $(whoami) == 'root' ]]; then
    echo ""
    echo ${RED}----------------------------------------------------
    echo Interdiction de lancer ce script avec le compte root.
    echo ----------------------------------------------------${RESET}
    echo ""
    cd ..
    rm -rf tuxinstall
    exit 1
fi

echo ""
echo ${BLUE}----------------------------------------------------
echo Assistant pour configurer ARCH Plasma après un formatage
echo ----------------------------------------------------${RESET}
echo ""

# get confirmation
read -t 15 -N 1 -p "Prêt à faire la post install de Arch sur KDE Plasma? (y/N) " start
echo 
 
# if answer is yes within 15 seconds start installing...
if [ "${start,,}" == "y" ]
then
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Config pacman
    echo ----------------------------------------------------${RESET}
    sudo sed -i '/^#ParallelDownloads/a ILoveCandy' /etc/pacman.conf
    sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
    echo "Configuration pacman terminée"

    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Actualisation des dépôts et mises à jour
    echo ----------------------------------------------------${RESET}
    sudo pacman -Syu
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Installation de paquets relatifs à OSHeden
    echo ----------------------------------------------------${RESET}
    sudo pacman -S --needed dos2unix xclip xsel npm fdupes
    
    if [ -d ~/AndroidAll/Thèmes_Shorts/ ]
        then
            echo ""
            echo ${BLUE}----------------------------------------------------
            echo Creation des liens symboliques pour les thèmes
            echo ----------------------------------------------------${RESET}
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
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Installation de divers utilitaires généraux
    echo ----------------------------------------------------${RESET}
    sudo pacman -S --needed bat btop duf element-desktop eza syncthing fastfetch firefox flameshot kdeconnect kio-admin meld ncdu obsidian pdfarranger samba simple-scan smbclient systemdgenie telegram-desktop thunar thunderbird timeshift transmission-qt yt-dlp
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Installation de divers paquets propres à Arch
    echo ----------------------------------------------------${RESET}
    sudo pacman -S --needed adobe-source-han-sans-cn-fonts adobe-source-han-sans-jp-fonts adobe-source-han-sans-kr-fonts android-tools cups dkms dosfstools firefox flatpak gwenview jre-openjdk-headless kcalc kimageformats kwallet libreoffice-{fresh,fresh-fr} linux-lts-headers man-pages ntfs-3g okular p7zip pacman-contrib perl-rename pkgfile print-manager qt5-imageformats xdg-desktop-portal-gtk

    whereisparu=$(which paru | cut -f2 -d " ")
    if [[ "$whereisparu" -eq 'not' ]]; then

        # get confirmation
        echo ""
        read -t 15 -N 1 -p "Voulez-vous installer paru ? (y/N) " paruinstall
        echo 
         
        # if answer is yes within 15 seconds start installing...
        if [ "${paruinstall,,}" == "y" ]
            then
            echo ""
            echo ${BLUE}----------------------------------------------------
            echo Installation de paru
            echo ----------------------------------------------------${RESET}
                sudo pacman -S --needed git base-devel
                git clone https://aur.archlinux.org/paru.git
                cd paru
                makepkg -si
            # Contrôler les news
            echo ${BLUE}Paru NewsOnUpdate${RESET}
            sudo sed -i 's/^#NewsOnUpdate/NewsOnUpdate/' /etc/paru.conf
        fi
    else
        echo ${GREEN}=> paru déjà installé${RESET}
        # Contrôler les news
        echo ${BLUE}Paru NewsOnUpdate${RESET}
        sudo sed -i 's/^#NewsOnUpdate/NewsOnUpdate/' /etc/paru.conf
    fi

    whereisparu2=$(which paru | cut -f2 -d " ")
    if [[ "$whereisparu2" -eq 'not' ]]; then
        echo ${YELLOW}----------------------------------------------------
        echo "Paru n'étant pas installé, aucun paquet AUR ne sera traité..."
        echo ----------------------------------------------------${RESET}
    else
        echo ""
        echo ${BLUE}----------------------------------------------------
        echo Installation de paquets avec paru
        echo ----------------------------------------------------${RESET}
        paru -S --needed brave-bin cnijfilter2-mg7500 downgrade payload-dumper-go-bin protonmail-bridge-bin reflector-simple rtl8821ce-dkms-git uniutils pika-backup
    fi
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Gestion de la carte réseau Realtek
    echo ----------------------------------------------------${RESET}
    echo "# https://github.com/tomaspinho/rtl8821ce/tree/master#wi-fi-not-working-for-kernel--59" | sudo tee -a /etc/modprobe.d/blacklist.conf > /dev/null
    echo "blacklist rtw88_8821ce" | sudo tee -a /etc/modprobe.d/blacklist.conf > /dev/null
    echo Configuration terminée
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo "Activation de l'imprimante et du bluetooth au démarrage"
    echo ----------------------------------------------------${RESET}
    sudo systemctl enable --now cups.socket
    sudo systemctl enable cups.service
    sudo systemctl enable --now bluetooth.service
    echo Configuration terminée
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo "Installation de VirtualBox + Guest + Host DKMS"
    echo ----------------------------------------------------${RESET}
    sudo pacman -S --needed virtualbox virtualbox-guest-iso virtualbox-host-dkms
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Activation du nettoyage du cache des paquets
    echo ----------------------------------------------------${RESET}
    sudo systemctl enable paccache.timer
    echo Configuration terminée
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Installation de paquets pour carte graphique NVIDIA
    echo ----------------------------------------------------${RESET}
    sudo pacman -S --needed nvidia nvidia-lts nvidia-utils nvidia-settings vulkan-icd-loader
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Installation du dépôt officiel Flatpak
    echo ----------------------------------------------------${RESET}
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    echo Configuration terminée
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Installation de ZSH et configuration
    echo ----------------------------------------------------${RESET}
    sudo pacman -S --needed zsh
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Oh My ZSH
    echo ----------------------------------------------------${RESET}
    [[ -d ~/.oh-my-zsh ]] && echo ${GREEN}=> Oh My ZSH déjà installé${RESET} || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && echo ${GREEN}"=> Installation de Oh My ZSH terminée"${RESET}
    
    echo ${BLUE}Installation zsh-autosuggestions${RESET}
    [[ -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]] && echo ${GREEN}=> zsh-autosuggestions déjà installé${RESET} || git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && echo ${GREEN}"=> Installation de zsh-autosuggestions terminée"${RESET}
    
    echo ${BLUE}Installation zsh-syntax-highlighting${RESET}
    [[ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]] && echo ${GREEN}=> zsh-syntax-highlighting déjà installé${RESET} || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && echo ${GREEN}"=> Installation de zsh-syntax-highlighting terminée"${RESET}
    
    echo ${BLUE}Installation du thème powerlevel10k${RESET}
    [[ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]] && echo ${GREEN}=> powerlevel10k déjà installé${RESET} || git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k && echo ${GREEN}"=> Installation du thème powerlevel10k terminée"${RESET}
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Désactiver le bruit lors de la recherche
    echo ----------------------------------------------------${RESET}
    if grep -Fxq "blacklist pcspkr" /etc/modprobe.d/nobeep.conf;
    then echo ${GREEN}"=> Blacklist pcspkr déjà configuré"${RESET}
    else echo "blacklist pcspkr" | sudo tee -a /etc/modprobe.d/nobeep.conf > /dev/null
    fi
    if grep -Fxq "blacklist snd_pcsp" /etc/modprobe.d/nobeep.conf;
    then echo ${GREEN}"=> Blacklist snd_pcsp déjà configuré"${RESET}
    else echo "blacklist snd_pcsp" | sudo tee -a /etc/modprobe.d/nobeep.conf > /dev/null
    fi
    echo Configuration terminée
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Activation du pavé numérique pour SDDM
    echo ----------------------------------------------------${RESET}
    if grep -Fxq "Numlock=on" /etc/sddm.conf;
    then echo ${GREEN}"=> Pavé numérique déjà configuré"${RESET}
    else echo "[General]" | sudo tee -a /etc/sddm.conf > /dev/null && echo "Numlock=on" | sudo tee -a /etc/sddm.conf > /dev/null
    fi
    echo Configuration terminée
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Syncthing au démarrage
    echo ----------------------------------------------------${RESET}
    synchtingrun=$(systemctl --user status syncthing.service | grep enabled)
    if [[ "$synchtingrun" == *"enabled"* ]];
    then
        echo "Syncthing est déjà actif"
    else
        echo "Activation du service"
        sudo systemctl --user enable syncthing.service
        sudo systemctl --user start syncthing.service
    fi
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Config bash et zsh
    echo ----------------------------------------------------${RESET}
    if grep -Fxq "if [ -f ~/.bash_aliases ]; then" ~/.bashrc;
    then
        echo ${GREEN}=> config bash ok${RESET}
    else
        echo "if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi" | sudo tee -a ~/.bashrc > /dev/null
    fi
    
    if grep -Fxq "source $HOME/.bash_aliases" ~/.zshrc;
    then echo ${GREEN}=> source bash_aliases déjà ok${RESET}
    else echo "source $HOME/.bash_aliases" | sudo tee -a ~/.zshrc > /dev/null && echo bash_aliases ajouté dans le fichier de configuration .zshrc
    fi
    
    if grep -Fxq "alias lsl" ~/.zshrc;
    then echo ${GREEN}"=> l'alias lsl existe déjà"${RESET}
    else echo "alias lsl='eza -la --color=always --group-directories-first'" | sudo tee -a ~/.zshrc > /dev/null
    fi
    
    sed -i 's/^ZSH_THEME.*$/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/' ~/.zshrc
    sed -i 's/^plugins=(git).*$/plugins=(\ngit\nzsh-autosuggestions\nzsh-syntax-highlighting\n)/' ~/.zshrc

    echo Configuration terminée
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Nettoyage de tuxinstall
    echo ----------------------------------------------------${RESET}
    cd ~
    rm -rf ~/tuxinstall && echo "Dossier tuxinstall supprimé"

    echo ""
    echo ${GREEN}----------------------------------------------------
    echo "Fin du process. Merci et bonne journée."
    echo ----------------------------------------------------${RESET}
else
    echo ${YELLOW}"Pas de soucis, on s'arrête là :-)"${RESET}
    rm -rf ~/tuxinstall
fi
