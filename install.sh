#!/bin/bash

#Coloration du texte
export RESET=$(tput sgr0)
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export BLUE=$(tput setaf 4)

sleepquick=1
sleepmid=3
sleeplong=6

# On quitte tout de suite si le script est exécuté en tant que root
if [[ $(whoami) == 'root' ]]; then
    echo ""
    echo ${RED}----------------------------------------------------
    echo "Interdiction de lancer ce script avec le compte root"
    echo ----------------------------------------------------${RESET}
    echo ""
    cd ~
    rm -rf ~/tuxinstall && echo "Dossier tuxinstall supprimé"
    exit 1
fi

# Seulement pour Arch
if [[ $(grep -c "ID=arch" /etc/os-release) -lt 1 ]]
then
    echo "Ce script n'est fait que pour Arch Linux"
    exit 1
fi

# Afficher le logo Arch Linux
cat << "EOF"
                   -`
                  .o+`
                 `ooo/
                `+oooo:
               `+oooooo:
               -+oooooo+:
             `/:-:++oooo+:
            `/++++/+++++++:
           `/++++++++++++++:
          `/+++ooooooooooooo/`
         ./ooosssso++osssssso+`
        .oossssso-````/ossssss+`
       -osssssso.      :ssssssso.
      :osssssss/        osssso+++.
     /ossssssss/        +ssssooo/-
   `/ossssso+/:-        -:/+osssso+-
  `+sso+:-`                 `.-/+oso:
 `++:.                           `-/+/
 .`                                 `/
EOF

echo "Bienvenue sur ${BLUE}${bold}Arch Linux!${normal}"${RESET}
sleep $sleepmid

OSvm=$(systemd-detect-virt)
#Autre commande : sudo dmidecode -s system-product-name
if [[ "$OSvm" != "none" ]]
then
    echo ${YELLOW}"VirtualBox détecté"${RESET}
    sleep $sleepquick

    read -p "Besoin de configurer les dossiers partagés ? (y/N) " -n 1 -r
    echo 
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        sudo usermod -a -G vboxsf $USER
        sudo chown -R $USER:users /media/
        sudo chown -R $USER:users /media/sf_PartageVM/
        echo ${YELLOW}"Fonctionnel après redémarrage"${RESET}
        sleep $sleepquick
    fi
fi

read -p "Prêt à faire la post install de Arch ? (y/N) " -n 1 -r
echo 
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo "Config pacman"
    echo ----------------------------------------------------${RESET}
    echo "Configuration ILoveCandy"
    if [[ $(grep -c "ILoveCandy" /etc/pacman.conf) -eq 1 ]]
    then
        echo ${GREEN}"ILoveCandy déjà configuré"${RESET}
    else
        sudo sed -i '/^#ParallelDownloads/a ILoveCandy' /etc/pacman.conf
        echo ${GREEN}"Modification effectuée avec succès"${RESET}
        sleep $sleepquick
    fi
    echo "Configuration Téléchargements parallèles"
    sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/w changelog.txt' /etc/pacman.conf
        if [ -s changelog.txt ]; then
            echo ${GREEN}"Modification effectuée avec succès"${RESET}
            sleep $sleepquick
        else
            echo ${RED}"Modification NON effectuée !"${RESET}
            sleep $sleepmid
        fi
        rm changelog.txt
        
    echo "Configuration des couleurs"
    sudo sed -i 's/^#Color/Color/w changelog.txt' /etc/pacman.conf
        if [ -s changelog.txt ]; then
            echo ${GREEN}"Modification effectuée avec succès"${RESET}
            sleep $sleepquick
        else
            echo ${RED}"Modification NON effectuée !"${RESET}
            sleep $sleepmid
        fi
        rm changelog.txt
        
    echo "Configuration pacman terminée"
    sleep $sleepquick

    echo ""
    echo ${BLUE}----------------------------------------------------
    echo "Config makepkg"
    echo ----------------------------------------------------${RESET}
    echo "On ne compresse plus"
    # le flag w ci-dessous permet d'écrire les modifications dans le fichier changelog.txt
    sudo sed -i "s/^PKGEXT='.pkg.tar.zst'/PKGEXT='.pkg.tar'/w changelog.txt" /etc/makepkg.conf 
        if [ -s changelog.txt ]; then # -s permet de savoir si le fichier a une taille > 0 Ko
            echo ${GREEN}"Modification effectuée avec succès"${RESET}
            sleep $sleepquick
        else
            echo ${RED}"Modification NON effectuée !"${RESET}
            sleep $sleepmid
        fi
        rm changelog.txt
    
    echo "Utilisation de tous les coeurs du processeur pour compiler"
    sudo sed -i 's/^MAKEFLAGS=.*/MAKEFLAGS=\"-j$(nproc)\"/w .txt' /etc/makepkg.conf
        if [ -s changelog.txt ]; then # -s permet de savoir si le fichier a une taille > 0 Ko
            echo ${GREEN}"Modification effectuée avec succès"${RESET}
            sleep $sleepquick
        else
            echo ${RED}"Modification NON effectuée !"${RESET}
            sleep $sleepmid
        fi
        rm changelog.txt

    echo ""
    echo ${BLUE}----------------------------------------------------
    echo "Actualisation des dépôts et mises à jour"
    echo ----------------------------------------------------${RESET}
    sleep $sleepquick
    sudo pacman -Syu
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo "Installation de paquets relatifs à OSHeden"
    echo ----------------------------------------------------${RESET}

    read -p "Besoin des paquets pour OSheden ? (y/N) " -n 1 -r
    echo 
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        sudo pacman -S --needed dos2unix xclip xsel fdupes
        # npm retiré et remplacé par ceci :

        #NVM / NodeJS
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        # Check MAJ : https://github.com/nvm-sh/nvm?tab=readme-ov-file#installing-and-updating
        echo "On teste la bonne installation de nvm pour NodeJS..."
        source ~/.bashrc
        if [[ $(command -v nvm) = nvm ]]
        then
            echo "Installation de la dernière version LTS de NodeJS"
            sleep $sleepquick
            nvm install --lts
        else
            echo ${YELLOW}"Échec de l'installation de nvm!"${RESET}
        fi
        sleep $sleepmid
    fi
        
    if [ -d ~/AndroidAll/Thèmes_Shorts/ ]
        then
            echo ""
            echo ${BLUE}----------------------------------------------------
            echo Creation des liens symboliques pour les thèmes
            echo ----------------------------------------------------${RESET}
            sleep $sleepquick
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
            ln -s /home/arnaud/Thèmes/DarkArmyDiamond/app/src/main/ /AndroidAll/Thèmes_Shorts/DarkArmyDiamond
            ln -s /home/arnaud/Thèmes/DarkArmyEmerald/app/src/main/ /AndroidAll/Thèmes_Shorts/DarkArmyEmerald
            ln -s /home/arnaud/Thèmes/DarkArmyOmni/app/src/main/ /AndroidAll/Thèmes_Shorts/DarkArmyOmni
            ln -s /home/arnaud/Thèmes/DarkArmyRuby/app/src/main/ /AndroidAll/Thèmes_Shorts/DarkArmyRuby
            ln -s /home/arnaud/Thèmes/DarkArmySapphire/app/src/main/ /AndroidAll/Thèmes_Shorts/DarkArmySapphire
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
    sleep $sleepquick
    dekde=$(echo $DESKTOP_SESSION)
    
    if [[ "$OSvm" != "none" ]]
    then
        sudo pacman -S --needed bat btop duf eza fastfetch firefox firefox-i18n-fr flameshot spectacle kio-admin meld ncdu pdfarranger tailspin trash-cli
        if [[ "$dekde" = 'plasma' ]]
        then
            sudo pacman -S --needed systemdgenie
        fi
    else
        sudo pacman -S --needed bat btop duf element-desktop eza syncthing fastfetch firefox firefox-i18n-fr flameshot spectacle meld tailspin ncdu obsidian pdfarranger samba simple-scan smbclient telegram-desktop thunar protonmail-bridge thunderbird thunderbird-i18n-fr timeshift qbittorrent yt-dlp trash-cli
        # Systemd pour la planification de Timeshift
        v_timeshift=$(systemctl status cronie.service | grep "Loaded:" | cut -f2 -d ";" | sed "s/[[:space:]]//")
        if [[ "$v_timeshift" = "enabled" ]]
        then
            echo "cronie.service déjà actif pour Timeshift"
        else
            systemctl enable cronie.service
            echo "cronie.service activé pour Timeshift"
        fi
        
        if [[ "$dekde" = 'plasma' ]]
        then
            sudo pacman -S --needed kdeconnect kio-admin systemdgenie partitionmanager
        elif [[ "$dekde" = 'xfce' ]]
        then
            sudo pacman -S --needed network-manager-applet font-manager gvfs-smb
        else
            echo ${YELLOW}"DE non supporté. Aucun utilitaire général ne sera installé"${RESET}
        fi
    fi

    if [[ $(command -v resh) = resh ]]
    # https://github.com/curusarn/resh
    then
        echo "Resh déjà installé"
    else
        echo "Installation de resh"
        curl -fsSL https://raw.githubusercontent.com/curusarn/resh/master/scripts/rawinstall.sh | bash
        sleep $sleepquick
        if [[ $(command -v resh) = resh ]]
        then
            echo ${GREEN}"Resh installé avec succès"${RESET}
        else
            echo ${YELLOW}"Échec de l'installation de resh"${RESET}
        fi
    fi
    sleep $sleepmid
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Installation de divers paquets propres à Arch
    echo ----------------------------------------------------${RESET}
    sleep $sleepquick
    if [[ "$OSvm" != "none" ]]
    then
        sudo pacman -S --needed adobe-source-han-sans-cn-fonts adobe-source-han-sans-jp-fonts adobe-source-han-sans-kr-fonts android-tools dkms dosfstools flatpak linux-lts-headers man-db man-pages ntfs-3g p7zip pacman-contrib perl-rename pkgfile print-manager xdg-desktop-portal-gtk
        if [[ "$dekde" = 'plasma' ]]
        then
            sudo pacman -S --needed gwenview kimageformats kwallet okular qt5-imageformats
        else
            echo ${YELLOW}"DE non supporté. Aucun paquet propre à Arch ne sera installé"${RESET}
        fi   
    else
        sudo pacman -S --needed adobe-source-han-sans-cn-fonts adobe-source-han-sans-jp-fonts adobe-source-han-sans-kr-fonts android-tools cups dkms dosfstools flatpak jre-openjdk-headless linux-lts-headers man-db man-pages ntfs-3g p7zip pacman-contrib perl-rename pkgfile print-manager xdg-desktop-portal-gtk
        if [[ "$dekde" = 'plasma' ]]
        then
            sudo pacman -S --needed gwenview kcalc kimageformats kwallet okular qt5-imageformats
        else
            echo ${YELLOW}"DE non supporté. Aucun paquet propre à Arch ne sera installé"${RESET}
        fi  
    fi
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Installation de paru
    echo ----------------------------------------------------${RESET}
    sleep $sleepquick
    
    whereisparu=$(command -v paru | cut -f4 -d "/")
    if [[ "$whereisparu" != 'paru' ]]; then
    
        read -p "Voulez-vous installer paru ? (y/N) " -n 1 -r
        echo 
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            sudo pacman -S --needed git base-devel
            git clone https://aur.archlinux.org/paru.git
            cd paru
            makepkg -si
            
            # Contrôler les news
            echo ${BLUE}"Paru NewsOnUpgrade"${RESET}
            sleep $sleepquick
            sudo sed -i 's/^#NewsOnUpgrade/NewsOnUpgrade/' /etc/paru.conf
        fi
    else
        echo ${GREEN}"=> paru déjà installé"${RESET}
        
        # Contrôler les news
        echo ${BLUE}"Paru NewsOnUpgrade"${RESET}
        sleep $sleepquick
        sudo sed -i 's/^#NewsOnUpgrade/NewsOnUpgrade/' /etc/paru.conf
    fi

    whereisparu2=$(command -v paru | cut -f4 -d "/")
    if [[ "$whereisparu2" != 'paru' ]]; then
        echo ${YELLOW}----------------------------------------------------
        echo "Paru n'étant pas installé, aucun paquet AUR ne sera traité..."
        echo ----------------------------------------------------${RESET}
        sleep $sleepquick
    else
        echo ""
        echo ${BLUE}----------------------------------------------------
        echo Installation de paquets avec paru
        echo ----------------------------------------------------${RESET}
        sleep $sleepquick
        if [[ "$OSvm" != "none" ]]
        then
            paru -S --needed brave-bin downgrade reflector-simple uniutils onlyoffice-bin
        else
            paru -S --needed brave-bin mullvad-browser-bin cnijfilter2-mg7500 downgrade payload-dumper-go-bin reflector-simple uniutils proton-vpn-gtk-app onlyoffice-bin

            read -p "Besoin de pika ? (y/N) " -n 1 -r
            echo 
            if [[ $REPLY =~ ^[Yy]$ ]]
            then
                paru -S --needed pika-backup
            fi

            read -p "Besoin de ventoy ? (y/N) " -n 1 -r
            echo 
            if [[ $REPLY =~ ^[Yy]$ ]]
            then
                paru -S --needed ventoy-bin
            fi
        fi
    fi
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Gestion de la carte réseau Realtek RTL8821CE
    echo ----------------------------------------------------${RESET}
    sleep $sleepquick
    realtek=$(lspci | grep -E -i --color 'network|ethernet|wireless|wi-fi' | grep RTL8821CE)
    if [[ "$realtek" == *"RTL8821CE"* ]];
    then
        echo "=> Carte réseau Realtek RTL8821CE détectée"*
        sleep $sleepquick

        whereisparu3=$(which paru | cut -f2 -d " ")
        if [[ "$whereisparu3" -eq 'not' ]]; then
            echo ${YELLOW}"paru non installé donc le paquet rtl8821ce-dkms-git ne sera pas installé"${RESET}
            sleep $sleepquick
        else
            echo "=> Installation du paquet rtl8821ce-dkms-git"
            sleep $sleepquick
            paru -S rtl8821ce-dkms-git
        fi

        if [[ -f /etc/modprobe.d/blacklist.conf ]]
        then
            blacklistrealtek=$(grep "blacklist rtw88_8821ce" /etc/modprobe.d/blacklist.conf)
            if [[ "$blacklistrealtek" == *"rtw88_8821ce"* ]];
            then
                echo ${GREEN}"=> Fichier blacklist.conf déjà à jour"${RESET}
                sleep $sleepquick
            else   
                echo "# https://github.com/tomaspinho/rtl8821ce/tree/master#wi-fi-not-working-for-kernel--59" | sudo tee -a /etc/modprobe.d/blacklist.conf > /dev/null
                echo "blacklist rtw88_8821ce" | sudo tee -a /etc/modprobe.d/blacklist.conf > /dev/null
                echo "=> Fichier blacklist.conf mis à jour"
                sleep $sleepquick
            fi
        else
            echo "=> Création du fichier blacklist.conf"
            echo "# https://github.com/tomaspinho/rtl8821ce/tree/master#wi-fi-not-working-for-kernel--59" | sudo tee -a /etc/modprobe.d/blacklist.conf > /dev/null
            echo "blacklist rtw88_8821ce" | sudo tee -a /etc/modprobe.d/blacklist.conf > /dev/null
            sleep $sleepquick
        fi
    else
        echo "Etape ignorée. Carte réseau Realtek RTL8821CE non détectée"
        sleep $sleepquick
    fi
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo "Activation de l'imprimante et du bluetooth au démarrage"
    echo ----------------------------------------------------${RESET}
    sleep $sleepquick
    if [[ "$OSvm" != "none" ]]
    then
        echo "VM non concernée"
    else
        sudo systemctl enable --now cups.socket
        sudo systemctl enable cups.service
        sudo systemctl enable --now bluetooth.service
        echo Configuration terminée
    fi

    echo ""
    echo ${BLUE}----------------------------------------------------
    echo "Installation de VirtualBox + Guest + Host DKMS"
    echo ----------------------------------------------------${RESET}
    sleep $sleepquick
        
    if [[ "$OSvm" != "none" ]]
    then
        echo "VM non concernée"
        sleep $sleepquick
    else
        echo "=> Installation des paquets pour VirtualBox"
        sleep $sleepquick
        sleep $sleepquick
        sudo pacman -S --needed virtualbox virtualbox-guest-iso virtualbox-host-dkms
        
    fi
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Activation du nettoyage du cache des paquets
    echo ----------------------------------------------------${RESET}
    sudo systemctl enable paccache.timer
    echo ${GREEN}"Configuration terminée"${RESET}
    sleep $sleepquick
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Installation de paquets pour carte graphique NVIDIA
    echo ----------------------------------------------------${RESET}

    if [[ "$OSvm" != "none" ]]
    then
        echo "VM non concernée"
        sleep $sleepquick
    else
        echo 
        read -p "Besoin des paquets pour NVIDIA ? (y/N) " -n 1 -r
        echo 
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo "=> Installation de nividia pour kernel Linux et Linux LTS"
            sleep $sleepquick
            sudo pacman -S --needed nvidia nvidia-lts nvidia-utils nvidia-settings vulkan-icd-loader
        fi
    fi
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo "Installation du dépôt officiel Flatpak"
    echo ----------------------------------------------------${RESET}
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    echo ${GREEN}"Configuration terminée"${RESET}
    sleep $sleepquick
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Installation de ZSH et configuration
    echo ----------------------------------------------------${RESET}
    sleep $sleepquick
    sudo pacman -S --needed zsh
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Oh My ZSH
    echo ----------------------------------------------------${RESET}
    sleep $sleepquick
    [[ -d ~/.oh-my-zsh ]] && echo ${GREEN}=> Oh My ZSH déjà installé${RESET} || sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && echo ${GREEN}"=> Installation de Oh My ZSH terminée"${RESET}
    
    echo ${BLUE}"Installation zsh-autosuggestions"${RESET}
    [[ -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]] && echo ${GREEN}=> zsh-autosuggestions déjà installé${RESET} || git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && echo ${GREEN}"=> Installation de zsh-autosuggestions terminée"${RESET}
    sleep $sleepquick
    
    echo ${BLUE}"Installation zsh-syntax-highlighting"${RESET}
    [[ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]] && echo ${GREEN}=> zsh-syntax-highlighting déjà installé${RESET} || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && echo ${GREEN}"=> Installation de zsh-syntax-highlighting terminée"${RESET}
    sleep $sleepquick
    
    echo ${BLUE}"Installation du thème powerlevel10k"${RESET}
    if [[ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]]
    then
        echo ${GREEN}"=> powerlevel10k déjà installé"${RESET}
        sleep $sleepquick
    else
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
        echo ${GREEN}"=> Installation du thème powerlevel10k terminée"${RESET}
        echo ${YELLOW}"=> Téléchargement des polices sur le bureau. À installer manuellement !"${RESET}
        echo ${YELLOW}"=> Voir le dossier sur le Bureau"${RESET}
        sleep $sleeplong
        
        if [[ -d ~/Bureau ]]
        then
            PathDesktop=$HOME'/Bureau'
        else
            PathDesktop=$HOME'/Desktop'
        fi
        mkdir -p $PathDesktop/Polices_a_installer
        wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -P $PathDesktop/Polices_a_installer
        wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -P $PathDesktop/Polices_a_installer
        wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -P $PathDesktop/Polices_a_installer
        wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -P $PathDesktop/Polices_a_installer
        echo ""
        echo ${GREEN}"=> Téléchargement des polices terminé"${RESET}
        sleep $sleepquick
    fi
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Désactiver le bruit lors de la recherche
    echo ----------------------------------------------------${RESET}
    sleep $sleepquick
    if grep -q "blacklist pcspkr" /etc/modprobe.d/nobeep.conf;
    then echo ${GREEN}"=> Blacklist pcspkr déjà configuré"${RESET}
    else echo "blacklist pcspkr" | sudo tee -a /etc/modprobe.d/nobeep.conf > /dev/null
    fi
    if grep -q "blacklist snd_pcsp" /etc/modprobe.d/nobeep.conf;
    then echo ${GREEN}"=> Blacklist snd_pcsp déjà configuré"${RESET}
    else echo "blacklist snd_pcsp" | sudo tee -a /etc/modprobe.d/nobeep.conf > /dev/null
    fi
    echo Configuration terminée
    sleep $sleepquick
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Activation du pavé numérique
    echo ----------------------------------------------------${RESET}
    sleep $sleepquick
    if [[ "$dekde" = 'plasma' ]]
        then
            if [[ $(grep -c "Numlock=on" /etc/sddm.conf) -eq 1 ]]
            then
                echo ${GREEN}"=> Pavé numérique déjà configuré"${RESET}
            else
                echo "[General]" | sudo tee -a /etc/sddm.conf > /dev/null && echo "Numlock=on" | sudo tee -a /etc/sddm.conf > /dev/null
            fi
    elif [[ "$dekde" = 'xfce' ]]
        then
            if [[ $(grep -c "numlockx" /etc/lightdm/lightdm.conf) -eq 1 ]]
            then
                echo ${GREEN}"=> Pavé numérique déjà configuré"${RESET}
            else
                echo "Installation de numlockx pour XFCE puis configuration de lightdm"
                sudo pacman -S --needed numlockx
                sudo sed -i 's/^#greeter-setup-script=/greeter-setup-script=/usr/bin/numlockx on/' /etc/lightdm/lightdm.conf
            fi
    else
        echo ${YELLOW}"DE non supporté. Le pavé numérique ne sera pas configuré."${RESET}
    fi
    echo ${GREEN}"Configuration terminée"${RESET}
    sleep $sleepquick
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Syncthing au démarrage
    echo ----------------------------------------------------${RESET}
    sleep $sleepquick

    if [[ "$OSvm" != "none" ]]
    then
        echo "VM non concernée"
    else
        synchtingrun=$(systemctl --user status syncthing.service | grep enabled)
        if [[ "$synchtingrun" == *"enabled"* ]];
        then
            echo ${GREEN}"Syncthing est déjà actif"${RESET}
            sleep $sleepquick
        else
            echo "Activation du service"
            sleep $sleepquick
            sudo systemctl --user enable syncthing.service
            sudo systemctl --user start syncthing.service
        fi
        echo ${GREEN}"Configuration terminée"${RESET}
        sleep $sleepquick
    fi
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Config bash et zsh
    echo ----------------------------------------------------${RESET}
    sleep $sleepquick
    if grep -q "bash_aliases" ~/.bashrc;
    then
        echo ${GREEN}"=> config bashrc ok"${RESET}
    else
        echo "if [ -f ~/.bash_aliases ]; then . ~/.bash_aliases; fi" | sudo tee -a ~/.bashrc > /dev/null
        echo "=> ajout bash_aliases dans .bashrc"
        sleep $sleepquick
    fi

    if [[ "$OSvm" != "none" ]]
    then
        echo "VM non concernée"
    else
        if grep -q "bash_aliases" ~/.zshrc;
        then
            echo ${GREEN}"=> source bash_aliases déjà ok dans .zshrc"${RESET}
            sleep $sleepquick
        else
            echo "source $HOME/.bash_aliases" | sudo tee -a ~/.zshrc > /dev/null
            echo "=> bash_aliases ajouté en source dans .zshrc"
            sleep $sleepquick
        fi
        
        if grep -q "alias lsl" ~/.zshrc;
        then
            echo ${GREEN}"=> l'alias lsl existe déjà dans .zshrc"${RESET}
            sleep $sleepquick
        else
            echo "alias lsl='eza -la --color=always --group-directories-first'" | sudo tee -a ~/.zshrc > /dev/null
            sleep $sleepquick
        fi
    fi
    
    sed -i 's/^ZSH_THEME.*$/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/' ~/.zshrc
    sed -i 's/^plugins=(git).*$/plugins=(\ngit\nzsh-autosuggestions\nzsh-syntax-highlighting\n)/' ~/.zshrc
    echo "Thème powerlevel10k et plugins activés"
    sleep $sleepquick

    echo ${GREEN}"Configuration terminée"${RESET}
    sleep $sleepquick
    
    echo ""
    echo ${BLUE}----------------------------------------------------
    echo Nettoyage de tuxinstall
    echo ----------------------------------------------------${RESET}
    sleep $sleepquick
    cd ~
    rm -rf ~/tuxinstall && echo "Dossier tuxinstall supprimé"

    echo ""
    echo ${GREEN}----------------------------------------------------
    echo "Fin du process. Merci et bonne journée."
    echo "Pour rappel : installer les polices et redémarrer."
    echo ----------------------------------------------------${RESET}
else
    echo ${YELLOW}"Pas de soucis, on s'arrête là :-)"${RESET}
    cd ~
    rm -rf ~/tuxinstall && echo "Dossier tuxinstall supprimé"
fi
