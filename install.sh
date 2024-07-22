#!/bin/bash

#################
### VARIABLES ###
#################
log_root="/tmp/config-arch.log"
log_noroot="$HOME/config-arch.log"
DE=$(echo $XDG_CURRENT_DESKTOP)
VM=$(systemd-detect-virt)
ICI=$(dirname "$0")

if [[ "$VM" != "none" ]]
then
    pacman_list="pacman_main_vm.list"
    paru_list="paru_vm.list"
else
    pacman_list="pacman_main.list"
    paru_list="paru.list"
fi

#Coloration du texte
export RESET=$(tput sgr0)
export RED=$(tput setaf 1)
export GREEN=$(tput setaf 2)
export YELLOW=$(tput setaf 3)
export BLUE=$(tput setaf 4)

#Pauses
sleepquick=2
sleepmid=4
sleeplong=6

#################
### FONCTIONS ###
#################
check_pkg()
{
	pacman -Q "$1" > /dev/null 2>&1
}
add_pkg_pacman()
{
	pacman -S --needed --noconfirm "$1" >> "$log_root" 2>&1
}
del_pkg_pacman()
{
	pacman -Rs --noconfirm "$1" >> "$log_root" 2>&1
}

add_pkg_paru()
{
	paru -S --needed --noconfirm "$1" >> "$log_noroot" 2>&1
}
del_pkg_paru()
{
	paru -Rs --noconfirm "$1" >> "$log_noroot" 2>&1
}

check_flatpak()
{
	flatpak info "$1" > /dev/null 2>&1
}
add_flatpak()
{
	flatpak install flathub --noninteractive -y "$1" >> "$log_root" 2>&1
}
del_flatpak()
{
	flatpak uninstall --noninteractive -y "$1" >> "$log_root" 2>&1 && flatpak uninstall --unused  --noninteractive -y >> "$log_root" 2>&1
}

check_cmd()
{
if [[ $? -eq 0 ]]
then
    echo ${GREEN}"OK"${RESET}
else
    echo ${RED}"ERREUR"${RESET}
fi
}

check_systemd()
{
    systemctl status "$1" | grep "Loaded:" | cut -f2 -d ";" | sed "s/[[:space:]]//"
}

check_systemd_user()
{
    systemctl --user status "$1" | grep "Loaded:" | cut -f2 -d ";" | sed "s/[[:space:]]//"
}

#####################
### FIN FONCTIONS ###
#####################


####################
### DEBUT SCRIPT ###
####################

if [[ -z "$1" ]] # le premier argument est vide (./install.sh sans rien derrière)
    then
	echo "OK" > /dev/null
elif [[ "$1" == "arch" ]] || [[ "$1" == "user" ]] || [[ "$1" == "vm" ]] # exemple : ./install.sh arch
    then
	echo "OK" > /dev/null
else
	echo "Usage incorrect du script :" # $(basename $0) => nom du script lancé
	echo "- $(basename $0)       : Lance la config"
    echo "- $(basename $0) arch  : Une surprise vous attend..."
	echo "- $(basename $0) user  : Autres actions à lancer sans accès root"
	echo "- $(basename $0) vm    : Spécifique à virtualbox"
	exit 1;
fi

###################
#### PROGRAMME ####
###################
# Easter Egg
if [[ "$1" = "arch" ]]
    then
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

    echo "I use ${BLUE}${bold}Arch Linux${normal} btw..."${RESET}

	exit 0;
fi

# Seulement pour Arch
if [[ $(grep -c "ID=arch" /etc/os-release) -lt 1 ]]
then
    echo ${RED}"Ce script n'est fait que pour Arch Linux"${RESET}
    echo "\"ID=arch\" non trouvé dans /etc/os-release."
    exit 1;
fi

###################
######  VM  ######
###################
if [[ "$1" = "vm" ]]
then
    if [[ $(id -u) -ne "0" ]]
    then
        echo ${RED}"Lancer le script avec les droits root (sudo)"${RESET}
        exit 1;
    fi

    # Infos fichier log
    echo ${YELLOW}"Pour suivre la progression :"${RESET}
    echo ${bold}"tail -f $log_root"${normal}

    # Date dans le log
    echo '-------------------' >> "$log_root"
    date >> "$log_root"

    echo "1/ Paramètrage Virtualisation"
    if [[ "$VM" != "none" ]]
    then
        if ! check_pkg virtualbox-guest-utils
        then
            echo -n "- - - Installation du paquet des guests : "
            pacman -S --needed --noconfirm virtualbox-guest-utils >> "$log_root"
            check_cmd

            echo -n "- - - Activation de vboxservice.service : "
            systemctl enable --now vboxservice.service >> "$log_root" 2>&1
            check_cmd
        fi
	sleep $sleepquick
        if [[ $(grep vboxsf /etc/group | grep -c $SUDO_USER) -lt 1 ]]
        then
            echo -n "- - - Ajout du user au groupe vboxsf : "
            usermod -a -G vboxsf $SUDO_USER
            check_cmd

            echo -n "- - - Droits du dossier PartageVM : "
            chown -R $SUDO_USER:users /media/sf_PartageVM/
            check_cmd
        fi

        echo "2/ Chaotic aur"
	if [[ $(grep -c chaotic-mirrorlist /etc/pacman.conf) -lt 1 ]]
        then
            #https://aur.chaotic.cx/docs
            pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com >> "$log_root" 2>&1
            pacman-key --lsign-key 3056513887B78AEB >> "$log_root" 2>&1
            pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' >> "$log_root" 2>&1
            pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' >> "$log_root" 2>&1

            echo -n "- - - Statut de l'installation : "
            echo ""  | tee -a /etc/pacman.conf > /dev/null
            echo "[chaotic-aur]" | tee -a /etc/pacman.conf > /dev/null
            echo "Include = /etc/pacman.d/chaotic-mirrorlist" | tee -a /etc/pacman.conf > /dev/null
            check_cmd

            echo -n "- - - Mise à jour base de données chaotic-aur : "
            pacman -Syu --needed --noconfirm >> "$log_root"
            check_cmd
        fi
        exit 0;
    else
        echo "Nous ne sommes pas dans une machine virtuelle."
        exit 2;
    fi
fi

###################
#### USER ####
###################
if [[ "$1" = "user" ]]
then
    if [[ $(id -u) -eq "0" ]]
    then
        echo ${RED}"Lancer le script sans les droits root (su - root ou sudo)"${RESET}
        exit 1;
    fi

    if [[ "$VM" != "none" ]] && [[ $(grep -c chaotic-mirrorlist /etc/pacman.conf) -lt 1 ]] # VM et Chaotic AUR pas actif
    then
        echo "Relancer le script avec le paramètre \"vm\" pour notamment installer Chaotic AUR."
        exit 1;
    fi

    if [[ $(check_systemd cups.socket) != "enabled" ]] # Si désactivé c'est que le script en root n'a jamais été lancé.
    then
        "Tout d'abord, lancer ce script en root et sans paramère."
        exit 1;
    else
        # Infos fichier log
        echo ${YELLOW}"Pour suivre la progression :"${RESET}
        echo ${bold}"tail -f $log_noroot"${normal}

        # Date dans le log
        echo '-------------------' >> "$log_noroot"
        date >> "$log_noroot"

        #Resh
        echo "1/ Installation de resh"
        if ! pacman -Q zsh tar curl > /dev/null 2>&1
        then
            echo ${YELLOW}"Installer zsh, curl et tar avant RESH."${RESET}
        elif [[ ! -d ~/.resh/bin/ ]]
        # https://github.com/curusarn/resh
        then
            echo -n "- - - Statut de l'installation : "
            curl -fsSL https://raw.githubusercontent.com/curusarn/resh/master/scripts/rawinstall.sh | bash >> $log_noroot 2>&1
            check_cmd
        fi

        echo "2/ Installation de paru"
        if ! check_pkg paru && check_pkg git && check_pkg base-devel
        then
            echo "Installation de PARU"
            rustup default stable >> "$log_noroot" 2>&1
            git clone https://aur.archlinux.org/paru.git >> "$log_noroot" 2>&1
            cd paru >> "$log_noroot" 2>&1
            makepkg -si
            echo -n "- - - Statut de l'installation : "
            pacman -Q paru > /dev/null
            check_cmd
            echo -n "- - - Nettoyage de l'installation : "
            cd ..
            rm -rf paru
            check_cmd

            if check_pkg paru && [[ $(grep -c "^#NewsOnUpgrade" /etc/paru.conf) -lt 1 ]]
            then
                echo -n "- - - Correction de NewsOnUpgrade : "
                sudo sed -i 's/^#NewsOnUpgrade/NewsOnUpgrade/' /etc/paru.conf
                check_cmd
            fi
        fi

        echo "3/ Activation de syncthing.service"
        if check_pkg syncthing && [[ $(check_systemd_user syncthing.service) != "enabled" ]]
        then
            echo -n "Activation du service syncthing.service : "
            systemctl --user enable syncthing.service >> "$log_noroot" 2>&1
            check_cmd
        fi

        ### INSTALL/SUPPRESSION PAQUETS SELON LISTE
        echo "4/ Paquets PARU"
        if check_pkg paru
        then
            while read -r line
            do
                if [[ "$line" == add:* ]]
                then
                    p=${line#add:}
                    if ! check_pkg "$p"
                    then
                        echo -n "- - - Installation paquet $p : "
                        add_pkg_paru "$p"
                        check_cmd
                    fi
                fi

                if [[ "$line" == del:* ]]
                then
                    p=${line#del:}
                    if check_pkg "$p"
                    then
                        echo -n "- - - Suppression paquet $p : "
                        del_pkg_paru "$p"
                        check_cmd
                    fi
                fi
            done < "$paru_list"
        fi

        echo "5/ Gestion de NVM"
        if [[ $(which nvm 2>/dev/null | grep -c nvm) -lt 1 ]]
        then
            echo -n "- - - Installation de NVM : "
            wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash >> "$log_noroot" 2>&1
            # Check MAJ : https://github.com/nvm-sh/nvm?tab=readme-ov-file#installing-and-updating
            check_cmd

            echo -n "- - - Installation de la dernière version LTS : "
            nvm install --lts
            check_cmd
        fi

        echo "6/ Configuration shell"
        if check_pkg zsh && [[ ! -d ~/.oh-my-zsh ]]
        then
            echo "- - - Installation Oh My ZSH"
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" # >> "$log_noroot" 2>&1 # pas dans les logs pour le définir comme shell par défaut
            echo -n "- - - Installation Oh My ZSH : "
            check_pkg zsh
            check_cmd
        fi
        if check_pkg zsh && [[ ! -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]]
        then
            echo -n "- - - Installation zsh-autosuggestions : "
            git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions >> "$log_noroot" 2>&1
            check_cmd
        fi
        if check_pkg zsh && [[ ! -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]]
        then
            echo -n "- - - Installation zsh-syntax-highlighting : "
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting >> "$log_noroot" 2>&1
            check_cmd
        fi
        if check_pkg zsh && [[ ! -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]]
        then
            echo -n "- - - Installation powerlevel10k : "
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k >> "$log_noroot" 2>&1
            check_cmd
            echo -n "- - - Définir powerlevel10k par défaut : "
            sed -i 's/^ZSH_THEME.*$/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/' ~/.zshrc
            check_cmd
            echo -n "- - - Activer les plugins : "
            sed -i 's/^plugins=(git).*$/plugins=(\ngit\nzsh-autosuggestions\nzsh-syntax-highlighting\n)/' ~/.zshrc
            check_cmd
        fi
        if check_pkg zsh && [[ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]] && [[ $(fc-list | grep -c MesloLGS\ NF\ Regular.ttf 2>&1 ) -lt 1 ]]
        then
            echo -n "- - - Installation des polices : "
            sudo mkdir -p /usr/share/fonts/TTF
            sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -P /usr/share/fonts/TTF/ >> "$log_noroot" 2>&1
            sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -P /usr/share/fonts/TTF/ >> "$log_noroot" 2>&1
            sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -P /usr/share/fonts/TTF/ >> "$log_noroot" 2>&1
            sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -P /usr/share/fonts/TTF/ >> "$log_noroot" 2>&1
            check_cmd
            fc-cache -f -v >> "$log_noroot" 2>&1
        fi
        if check_pkg zsh && [[ $(echo $SHELL | grep -c "zsh") -lt 1 ]]
        then
            echo -n "- - - ZSH devient le shell par défaut : "
            chsh -s /usr/bin/zsh
            check_cmd
            echo ${YELLOW}"Déconnexion requise pour changer le shell par défaut"${RESET}
        fi

        if check_pkg zsh # && [[ $(grep -c "ALIAS - GENERAL" ~/.zshrc) -lt 1 ]]
        then
            echo -n "- - - Ajustement des alias : "
            if [ ! -f "$ICI/alias_listing" ]
            then
                echo "Le fichier source des alias n'existe pas."
            else
                # Ajoute chaque ligne du fichier source au fichier cible si elle n'existe pas déjà
                while IFS= read -r ligne; do
                    if ( ! grep -Fxq "$ligne" ~/.zshrc && [[ "$ligne" == "## "* ]] ) || ( ! grep -Fxq "$ligne" ~/.zshrc && [[ "$ligne" == "### "* ]] )
                    then
                        echo "" >> ~/.zshrc  # Ajoute une ligne vide avant d'ajouter la ligne commentée uniquement si la ligne à ajouter n'existe pas déjà
                        echo "$ligne" >> ~/.zshrc
                    elif ! grep -Fxq "$ligne" ~/.zshrc; then
                        echo "$ligne" >> ~/.zshrc
                    fi
                done < "$ICI/alias_listing"
            fi
            check_cmd
            echo "On bascule sur ZSH !"
            zsh
        fi
    fi

exit 0;
fi

###################
### MAIN - ROOT ###
###################
# Tester si root
if [[ $(id -u) -ne "0" ]]
then
    echo ${RED}"Lancer le script avec les droits root (su - root ou sudo)"${RESET}
	exit 1;
fi

# Tester si bien une base Arch
if ! check_pkg pacman #pacman installé ?
then
	echo ${RED}"Le paquet \"pacman\" n'est pas installé donc cette distribution n'est probablement pas être basée sur Arch :-("${RESET}
	exit 2;
fi

# Infos fichier log
echo ${YELLOW}"Pour suivre la progression :"${RESET}
echo ${bold}"tail -f $log_root"${normal}
echo ""

if [[ -f $log_root ]]
then
    echo -n "Suppression du fichier de log existant : "
    rm -f $log_root
    check_cmd
fi

# Date dans le log
echo '-------------------' >> "$log_root"
date >> "$log_root"

### CONF PACMAN
echo "1/ Vérification configuration PACMAN"
if [[ $(grep -c 'ILoveCandy' /etc/pacman.conf) -lt 1 ]]
then
	echo -n "- - - Correction ILoveCandy : "
	sed -i '/^#ParallelDownloads/a ILoveCandy' /etc/pacman.conf
	check_cmd
fi
if [[ $(grep -c "^ParallelDownloads" /etc/pacman.conf) -lt 1 ]]
then
	echo -n "- - - Correction téléchargements parallèles : "
	sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
	check_cmd
fi
if [[ $(grep -c "^Color" /etc/pacman.conf) -lt 1 ]]
then
	echo -n "- - - Correction des couleurs : "
	sed -i 's/^#Color/Color/' /etc/pacman.conf
	check_cmd
fi

### CONF MAKEPKG
echo "2/ Vérification configuration MAKEPKG"
if [[ $(grep -c "^PKGEXT='.pkg.tar'" /etc/makepkg.conf) -lt 1 ]]
then
	echo -n "- - - Correction de la compression : "
	sed -i "s/^PKGEXT='.pkg.tar.zst'/PKGEXT='.pkg.tar'/" /etc/makepkg.conf
	check_cmd
fi

if [[ $(grep -c "^MAKEFLAGS=\"-j\$(nproc)\"" /etc/makepkg.conf) -lt 1 ]]
then
	echo -n "- - - Correction de l'utilisation des coeurs : "
	sed -i 's/^#MAKEFLAGS=.*/MAKEFLAGS=\"-j$(nproc)\"/' /etc/makepkg.conf
	check_cmd
fi

### MAJ Système avec Pacman
echo -n "3/ Mise à jour du système Pacman : "
pacman -Syu --noconfirm >> "$log_root" 2>&1
check_cmd

### PAQUETS PACMAN
echo "4/ Gestion des paquets principaux PACMAN"
while read -r line
do
	if [[ "$line" == add:* ]]
	then
		p=${line#add:}
		if ! check_pkg "$p"
		then
			echo -n "- - - Installation paquet $p : "
			add_pkg_pacman "$p"
			check_cmd
		fi
	fi

	if [[ "$line" == del:* ]]
	then
		p=${line#del:}
		if check_pkg "$p"
		then
			echo -n "- - - Suppression paquet $p : "
			del_pkg_pacman "$p"
			check_cmd
		fi
	fi
done < "$pacman_list"

if [[ "$DE" = 'KDE' ]]
then
    echo "4.1/ Gestion des paquets Plasma"
    while read -r line
    do
        if [[ "$line" == add:* ]]
        then
            p=${line#add:}
            if ! check_pkg "$p"
            then
                echo -n "- - - Installation paquet $p : "
                add_pkg_pacman "$p"
                check_cmd
            fi
        fi

        if [[ "$line" == del:* ]]
        then
            p=${line#del:}
            if check_pkg "$p"
            then
                echo -n "- - - Suppression paquet $p : "
                del_pkg_pacman "$p"
                check_cmd
            fi
        fi
    done < "$ICI/pacman_plasma.list"
fi

if [[ "$DE" = 'XFCE' ]]
then
    echo "4.1/ Gestion des paquets XFCE"
    while read -r line
    do
        if [[ "$line" == add:* ]]
        then
            p=${line#add:}
            if ! check_pkg "$p"
            then
                echo -n "- - - Installation paquet $p : "
                add_pkg_pacman "$p"
                check_cmd
            fi
        fi

        if [[ "$line" == del:* ]]
        then
            p=${line#del:}
            if check_pkg "$p"
            then
                echo -n "- - - Suppression paquet $p : "
                del_pkg_pacman "$p"
                check_cmd
            fi
        fi
    done < "$ICI/pacman_xfce.list"
fi

echo "5/ Configuration Flatpak"
## FLATHUB
if check_pkg flatpak && [[ $(flatpak remotes | grep -c flathub) -ne 1 ]]
then
	echo -n "- - - Installation Flathub : "
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo > /dev/null
	check_cmd

elif ! check_pkg flatpak
then
    echo -n "- - - Installation de Flatkpak : "
    add_pkg_pacman flatpak
    check_cmd
    echo -n "- - - Installation de Flathub : "
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo > /dev/null
	check_cmd
fi

### MAJ Flatpak
#if check_pkg flatpak
#then
#    echo -n "- - - Mise à jour des Flatpaks : "
#    flatpak update --noninteractive >> "$log_root"  2>&1
#    check_cmd
#fi

### PAQUETS FLATPAK
echo "6/ Gestion des paquets FLATPAK (long si première installation)"
while read -r line
do
	if [[ "$line" == add:* ]]
	then
		p=${line#add:}
		if ! check_flatpak "$p"
		then
			echo -n "- - - Installation flatpak $p : "
			add_flatpak "$p"
			check_cmd
		fi
	fi

	if [[ "$line" == del:* ]]
	then
		p=${line#del:}
		if check_flatpak "$p"
		then
			echo -n "- - - Suppression flatpak $p : "
			del_flatpak "$p"
			check_cmd
		fi
	fi
done < "$ICI/flatpak.list"


### OSheden
read -p "7/ Besoin des spécificités pour OSheden ? (y/N) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo
    echo "7.1/ Gestion des paquets"
    while read -r line
    do
        if [[ "$line" == add:* ]]
        then
            p=${line#add:}
            if ! check_pkg "$p"
            then
                echo -n "- - - Installation paquet $p : "
                add_pkg_pacman "$p"
                check_cmd
            fi
        fi

        if [[ "$line" == del:* ]]
        then
            p=${line#del:}
            if check_pkg "$p"
            then
                echo -n "- - - Suppression paquet $p : "
                del_pkg_pacman "$p"
                check_cmd
            fi
        fi
    done < "$ICI/pacman_osheden.list"

    if [[ ! -d /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Alta ]] && [[ -d /home/$SUDO_USER/Thèmes/Alta/app/src/main/ ]]
    then
        echo -n "7.2/ Création des liens symboliques : "
        ln -s /home/$SUDO_USER/Thèmes/Alta/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Alta
        ln -s /home/$SUDO_USER/Thèmes/Altess/app/src/main /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Altess
        ln -s /home/$SUDO_USER/Thèmes/Azulox/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Azulox
        ln -s /home/$SUDO_USER/Thèmes/Black_Army_Diamond/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/BlackArmyDiamond
        ln -s /home/$SUDO_USER/Thèmes/Black_Army_Emerald/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/BlackArmyEmerald
        ln -s /home/$SUDO_USER/Thèmes/Black_Army_Omni/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/BlackArmyOmni
        ln -s /home/$SUDO_USER/Thèmes/Black_Army_Ruby/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/BlackArmyRuby
        ln -s /home/$SUDO_USER/Thèmes/Black_Army_Sapphire/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/BlackArmySapphire
        ln -s /home/$SUDO_USER/Thèmes/Caya/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Caya
        ln -s /home/$SUDO_USER/Thèmes/Ciclo/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Ciclo
        ln -s /home/$SUDO_USER/Thèmes/DarkArmyDiamond/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/DarkArmyDiamond
        ln -s /home/$SUDO_USER/Thèmes/DarkArmyEmerald/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/DarkArmyEmerald
        ln -s /home/$SUDO_USER/Thèmes/DarkArmyOmni/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/DarkArmyOmni
        ln -s /home/$SUDO_USER/Thèmes/DarkArmyRuby/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/DarkArmyRuby
        ln -s /home/$SUDO_USER/Thèmes/DarkArmySapphire/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/DarkArmySapphire
        ln -s /home/$SUDO_USER/Thèmes/Darky/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Darky
        ln -s /home/$SUDO_USER/Thèmes/Darly/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Darly
        ln -s /home/$SUDO_USER/Thèmes/Distraction_Free/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Distraction
        ln -s /home/$SUDO_USER/Thèmes/Ecliptic/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Ecliptic
        ln -s /home/$SUDO_USER/Thèmes/Friendly/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Friendly
        ln -s /home/$SUDO_USER/Thèmes/GIN/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/GIN
        ln -s /home/$SUDO_USER/Thèmes/GoldOx/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/GoldOx
        ln -s /home/$SUDO_USER/Thèmes/Goody/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Goody
        ln -s /home/$SUDO_USER/Thèmes/Lox/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Lox
        ln -s /home/$SUDO_USER/Thèmes/Luzicon/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Luzicon
        ln -s /home/$SUDO_USER/Thèmes/NubeReloaded/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/NubeReloaded
        ln -s /home/$SUDO_USER/Thèmes/Oscuro/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Oscuro
        ln -s /home/$SUDO_USER/Thèmes/Raya_Black/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/RayaBlack
        ln -s /home/$SUDO_USER/Thèmes/RayaReloaded/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/RayaReloaded
        ln -s /home/$SUDO_USER/Thèmes/Shapy/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Shapy
        ln -s /home/$SUDO_USER/Thèmes/Sinfonia/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Sinfonia
        ln -s /home/$SUDO_USER/Thèmes/Spark/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Spark
        ln -s /home/$SUDO_USER/Thèmes/Stony/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Stony
        ln -s /home/$SUDO_USER/Thèmes/Supernova/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Supernova
        ln -s /home/$SUDO_USER/Thèmes/Whirl/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Whirl
        ln -s /home/$SUDO_USER/Thèmes/WhirlBlack/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/WhirlBlack
        ln -s /home/$SUDO_USER/Thèmes/Whirless/app/src/main /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Whirless
        ln -s /home/$SUDO_USER/Thèmes/WhitArt/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/WhitArt
        ln -s /home/$SUDO_USER/Thèmes/Whity/app/src/main/ /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Whity
        check_cmd
    fi
fi

### Systemd
echo "8/ Paramètrage systemd"
if check_pkg timeshift && [[ $(check_systemd cronie.service) != "enabled" ]]
then
    echo -n "- - - Activation du service Timeshift : "
    systemctl enable cronie.service >> "$log_root" 2>&1
    check_cmd
fi

if ! check_pkg cups
then
    echo -n "- - - Installation du paquet cups : "
    add_pkg_pacman cups
    check_cmd
elif [[ $(check_systemd cups.socket) != "enabled" ]]
then
    echo -n "- - - Activation du service cups.socket : "
    systemctl enable --now cups.socket >> "$log_root" 2>&1
    check_cmd
fi

if [[ $(check_systemd cups.service) != "enabled" ]]
then
    echo -n "- - - Activation du service cups.service : "
    systemctl enable --now cups.service >> "$log_root" 2>&1
    check_cmd
fi

if [[ $(check_systemd bluetooth.service) != "enabled" ]]
then
    echo -n "- - - Activation du service bluetooth.service : "
    systemctl enable --now bluetooth.service >> "$log_root" 2>&1
    check_cmd
fi

if ! check_pkg pacman-contrib
then
    echo -n "- - - Installation du paquet pacman-contrib : "
    add_pkg_pacman pacman-contrib
    check_cmd
fi
if [[ $(check_systemd paccache.timer) != "enabled" ]]
then
    echo -n "- - - Activation du service paccache.timer : "
    systemctl enable paccache.timer >> "$log_root" 2>&1
    check_cmd
fi

echo "9/ Suppression du bruit lors de recherches"
if [[ ! -f /etc/modprobe.d/nobeep.conf ]]
then
    touch /etc/modprobe.d/nobeep.conf
fi

if [[ $(grep -c "blacklist pcspkr" /etc/modprobe.d/nobeep.conf) -lt 1 ]]
then
    echo -n "- - - Blacklist pcspkr : "
    echo "blacklist pcspkr" | tee -a /etc/modprobe.d/nobeep.conf > /dev/null
    check_cmd
fi
if [[ $(grep -c "blacklist snd_pcsp" /etc/modprobe.d/nobeep.conf) -lt 1 ]]
then
    echo -n "- - - Blacklist snd_pcsp : "
    echo "blacklist snd_pcsp" | tee -a /etc/modprobe.d/nobeep.conf > /dev/null
    check_cmd
fi

echo "10/ Pavé numérique"
# On crée les fichiers si besoin
if [ "$DE" = 'KDE' ] && [[ ! -f /etc/sddm.conf ]]
then
    touch /etc/sddm.conf
fi
if [ "$DE" = 'XFCE' ] && [[ ! -f /etc/lightdm/lightdm.conf ]]
then
    touch /etc/lightdm/lightdm.conf
fi

# On contrôle le contenu
if [ "$DE" = 'KDE' ] && [[ $(grep -c "Numlock=on" /etc/sddm.conf) -lt 1 ]]
then
    echo -n "- - - Activation pour KDE Plasma : "
    echo "[General]" | tee -a /etc/sddm.conf > /dev/null && echo "Numlock=on" | tee -a /etc/sddm.conf > /dev/null
    check_cmd
elif [ "$DE" = 'XFCE' ] && [[ $(grep -c "numlockx" /etc/lightdm/lightdm.conf) -lt 1 ]]
then
    echo -n "- - - Activation pour XFCE : "
    sed -i 's/^#greeter-setup-script=/greeter-setup-script=/usr/bin/numlockx on/' /etc/lightdm/lightdm.conf
    check_cmd
fi

echo "11/ Carte réseau Realtek"
#Gestion de la carte réseau Realtek RTL8821CE
if [[ "$VM" = "none" ]]
then
    if [[ $(lspci | grep -E -i 'network|ethernet|wireless|wi-fi' | grep -c RTL8821CE 2&>1) -eq 1 ]] && ! check_pkg rtl8821ce-dkms-git # Carte détectée mais paquet manquant
    then
        echo -n "- - - Installation du paquet AUR  : "
        add_pkg_paru rtl8821ce-dkms-git
        check_cmd

        if [[ $(grep -c "blacklist rtw88_8821ce" /etc/modprobe.d/blacklist.conf > /dev/null 2&>1) -lt 1 ]]
        then
            echo -n "- - - Configuration blacklist.conf  : "
            echo "# https://github.com/tomaspinho/rtl8821ce/tree/master#wi-fi-not-working-for-kernel--59" | tee -a /etc/modprobe.d/blacklist.conf > /dev/null
            echo "blacklist rtw88_8821ce" | tee -a /etc/modprobe.d/blacklist.conf > /dev/null
            check_cmd
        fi
    else
        echo ${YELLOW}"- - - Carte réseau Realtek RTL8821CE non détectée."${RESET}
    fi
fi

#NVIDIA
read -p "12/ Besoin des paquets NVIDIA ? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] && [[ "$VM" != "none" ]] && [[ $(lspci -vnn | grep -A 12 '\[030[02]\]' | grep -Ei "vga|3d|display|kernel" | grep -ic nvidia) -gt 0 ]]
then
    echo -n "- - - Installation des paquets NVIDIA : "
    pacman -S --needed --noconfirm pacman -S --needed nvidia nvidia-lts nvidia-utils nvidia-settings >> "$log_root" 2>&1
    check_cmd
fi


