#!/usr/bin/env bash

#################
### VARIABLES ###
#################
log_root="/tmp/config-arch.log"
log_noroot="$HOME/config-arch.log"
DE=$(echo $XDG_CURRENT_DESKTOP)
VM=$(systemd-detect-virt)
ICI=$(dirname "$0")

if [[ "$VM" != "none" ]]; then
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
export BOLD=$(tput bold)

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
    if pacman -Si "$1" > /dev/null 2>&1
    then
        pacman -S --needed --noconfirm "$1" >> "$log_root" 2>&1
    else
        echo ${RED}"*** Inexistant *** "${RESET}
        pacman_status='false'
    fi
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
if [[ "$pacman_status" != 'false' ]]; then
    if [[ $? -eq 0 ]]; then
        echo ${GREEN}"OK"${RESET}
    else
        echo ${RED}"ERREUR"${RESET}
    fi
fi
pacman_status=''
}

check_systemd()
{
    systemctl is-enabled "$1"
}

check_systemd_user()
{
    systemctl --user is-enabled "$1"
}

msg_bold_blue() {
    echo "${BLUE}${BOLD}$1${RESET}"
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
elif [[ "$1" == "arch" ]] || [[ "$1" == "user" ]] # exemple : ./install.sh arch
    then
	echo "OK" > /dev/null
else
	echo "Usage incorrect du script :" # $(basename $0) => nom du script lancé
	echo "- $(basename $0)       : Lance la config"
    echo "- $(basename $0) arch  : Une surprise vous attend..."
	echo "- $(basename $0) user  : Autres actions à lancer sans accès root"
	exit 1;
fi

# Tester la connexion Internet
if ! ping -c 1 google.com &> /dev/null; then
    echo "Pas de connexion Internet"
    exit 2;
fi

###################
#### PROGRAMME ####
###################
# Easter Egg
if [[ "$1" = "arch" ]]; then
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

    echo "I use ${BLUE}${BOLD}Arch Linux${RESET} btw..."

	exit 0;
fi

# Seulement pour Arch
if [[ $(grep -c "ID=arch" /etc/os-release) -lt 1 ]]; then
    echo ${RED}"Ce script n'est fait que pour Arch Linux"${RESET}
    echo "\"ID=arch\" non trouvé dans /etc/os-release."
    exit 1;
fi

###################
#### USER ####
###################
if [[ "$1" = "user" ]]; then
    if [[ $(id -u) -eq "0" ]]; then
        echo ${RED}"Lancer le script sans les droits root (su - root ou sudo)"${RESET}
        exit 1;
    fi

    if [[ "$VM" != "none" ]] && [[ $(grep -c chaotic-mirrorlist /etc/pacman.conf) -lt 1 ]] # VM et Chaotic AUR pas actif
    then
        echo "Relancer le script avec le paramètre \"vm\" pour notamment installer Chaotic AUR."
        exit 1;
    fi

    if [[ $(check_systemd cups.socket 2>/dev/null) != "enabled" ]] # Si désactivé c'est que le script en root n'a jamais été lancé.
    then
        echo ${RED}"Tout d'abord, lancer ce script en root et sans paramètre."${RESET}
        exit 1;
    else
        # Infos fichier log
        echo ${YELLOW}"Pour suivre la progression :"${RESET}
        echo ${BOLD}"tail -f $log_noroot"${RESET}
        echo

        # Date dans le log
        echo '-------------------' >> "$log_noroot"
        date >> "$log_noroot"
    fi

        #Resh
	msg_bold_blue "➜ Installation de resh"
        if ! pacman -Q zsh tar curl > /dev/null 2>&1; then
            echo ${YELLOW}"Installer zsh, curl et tar avant RESH."${RESET}
        elif [[ ! -d ~/.resh/bin/ ]]; then
	# https://github.com/curusarn/resh
            curl -fsSL https://raw.githubusercontent.com/curusarn/resh/master/scripts/rawinstall.sh | bash
        fi

        msg_bold_blue "➜ Installation de paru"
        if ! check_pkg paru && check_pkg git && check_pkg base-devel; then
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

            if check_pkg paru && [[ $(grep -c "^#NewsOnUpgrade" /etc/paru.conf) -lt 1 ]]; then
                echo -n "- - - Correction de NewsOnUpgrade : "
                sudo sed -i 's/^#NewsOnUpgrade/NewsOnUpgrade/' /etc/paru.conf
                check_cmd
            fi
        fi

        msg_bold_blue "➜ Activation de syncthing.service"
        if check_pkg syncthing && [[ $(check_systemd_user syncthing.service 2>/dev/null) != "enabled" ]]; then
            echo -n "Activation du service syncthing.service : "
            systemctl --user enable syncthing.service >> "$log_noroot" 2>&1
            check_cmd
        fi

        ### INSTALL/SUPPRESSION PAQUETS SELON LISTE
        msg_bold_blue "➜ Paquets paru"
        if check_pkg paru; then
            while read -r line
            do
                if [[ "$line" == add:* ]]; then
                    p=${line#add:}
                    if ! check_pkg "$p"; then
                        echo -n "- - - Installation paquet $p : "
                        add_pkg_paru "$p"
                        check_cmd
                    fi
                fi

                if [[ "$line" == del:* ]]; then
                    p=${line#del:}
                    if check_pkg "$p"; then
                        echo -n "- - - Suppression paquet $p : "
                        del_pkg_paru "$p"
                        check_cmd
                    fi
                fi
            done < "packages/$paru_list"
        fi

        msg_bold_blue "➜ Configuration shell"
        if check_pkg zsh && [[ ! -d ~/.oh-my-zsh ]]; then
            echo "- - - Installation Oh My ZSH"
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" # >> "$log_noroot" 2>&1 # pas dans les logs pour le définir comme shell par défaut
            echo -n "- - - Installation Oh My ZSH : "
            check_pkg zsh
            check_cmd
        fi
        if check_pkg zsh && [[ ! -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]]; then
            echo -n "- - - Installation zsh-autosuggestions : "
            git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions >> "$log_noroot" 2>&1
            check_cmd
        fi
        if check_pkg zsh && [[ ! -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]]; then
            echo -n "- - - Installation zsh-syntax-highlighting : "
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting >> "$log_noroot" 2>&1
            check_cmd
        fi
        if check_pkg zsh && [[ ! -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]]; then
            echo -n "- - - Installation powerlevel10k : "
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k >> "$log_noroot" 2>&1
            check_cmd
            echo -n "- - - Définir powerlevel10k par défaut : "
            sed -i 's/^ZSH_THEME.*$/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/' ~/.zshrc
            check_cmd
        fi
        if check_pkg zsh && [[ $(grep -c 'zsh-syntax-highlighting' ~/.zshrc) -lt 1 ]]; then
            echo -n "- - - Activation des plugins : "
            sed -E -i 's/plugins=\((.*?)\)/plugins=(colored-man-pages copyfile copypath eza git gradle safe-paste web-search zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
            check_cmd
        fi
        if check_pkg zsh && [[ -d ~/.oh-my-zsh/custom/themes/powerlevel10k ]] && [[ $(fc-list | grep -c MesloLGS\ NF\ Regular.ttf 2>&1 ) -lt 1 ]]; then
            echo -n "- - - Installation des polices : "
            sudo mkdir -p /usr/share/fonts/TTF
            sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -P /usr/share/fonts/TTF/ >> "$log_noroot" 2>&1
            sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -P /usr/share/fonts/TTF/ >> "$log_noroot" 2>&1
            sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -P /usr/share/fonts/TTF/ >> "$log_noroot" 2>&1
            sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -P /usr/share/fonts/TTF/ >> "$log_noroot" 2>&1
            check_cmd
            fc-cache -f -v >> "$log_noroot" 2>&1
        fi
        if check_pkg zsh && [[ $(echo $SHELL | grep -c "zsh") -lt 1 ]]; then
            echo -n "- - - ZSH devient le shell par défaut : "
            chsh -s /usr/bin/zsh
            check_cmd
            echo ${YELLOW}"Déconnexion requise pour changer le shell par défaut"${RESET}
        fi

        if check_pkg zsh # && [[ $(grep -c "ALIAS - GENERAL" ~/.zshrc) -lt 1 ]]
        then
            echo -n "- - - Ajustement des alias par comparatif : "
            if [ ! -f "$ICI/config/alias_listing" ]; then
                echo "Le fichier source des alias n'existe pas."
            else
                # Ajoute chaque ligne du fichier source au fichier cible si elle n'existe pas déjà
                while IFS= read -r ligne; do
                    if ( ! grep -Fxq "$ligne" ~/.zshrc && [[ "$ligne" == "## "* ]] ) || ( ! grep -Fxq "$ligne" ~/.zshrc && [[ "$ligne" == "### "* ]] ); then
                        echo "" >> ~/.zshrc  # Ajoute une ligne vide avant d'ajouter la ligne commentée uniquement si la ligne à ajouter n'existe pas déjà
                        echo "$ligne" >> ~/.zshrc
                    elif ! grep -Fxq "$ligne" ~/.zshrc; then
                        echo "$ligne" >> ~/.zshrc
                    fi
                done < "$ICI/config/alias_listing"
            fi
            check_cmd
        fi

	if [[ "$VM" != "none" ]]; then
	 	msg_bold_blue "➜ Gestion nvm"
	        if [[ ! -f ~/.nvm/nvm.sh ]]; then
	            echo -n "- - - Installation de NVM : "
	            wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash >> "$log_noroot" 2>&1
	            # Check MAJ : https://github.com/nvm-sh/nvm?tab=readme-ov-file#installing-and-updating
	            check_cmd
	
	            echo -n "- - - Nettoyage .zshrc : "
	            sed -i '/NVM_DIR/d' ~/.zshrc
	            check_cmd
	
	            echo -n "- - - Paramètrage .zshrc : "
	            echo "" >> ~/.zshrc
	            echo 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"' >> ~/.zshrc
	            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm' >> ~/.zshrc
	            check_cmd
	
	            echo ${YELLOW}${BOLD}"- - - Coller ces commandes dans un NOUVEAU terminal : "${RESET}
	            echo "déjà dans le presse-papier"
	            sleep $sleepmid
	            echo "nvm install --lts && nvm use --lts && nvm install --reinstall-packages-from=current 'lts/*'" | xclip -selection clipboard
	            sleep $sleepmid
	        fi
	 fi

	
    if [[ "$DE" = 'KDE' ]]; then
        msg_bold_blue "➜ KDE Dolphin services menu"
        if check_pkg meld && [[ ! -f ~/.local/share/kio/servicemenus/compare-using-meld.desktop ]]; then
        echo -n "- - - Comparer avec Meld : "
            if [ ! -f "$ICI/config/compare-using-meld.desktop" ]; then
            mkdir -p ~/.local/share/kio/servicemenus
            cp "$ICI/config/compare-using-meld.desktop" ~/.local/share/kio/servicemenus
            check_cmd
            fi
        fi
    fi
exit 0
fi

###################
### MAIN - ROOT ###
###################
# Tester si root
if [[ $(id -u) -ne "0" ]]; then
    echo ${RED}"Lancer le script avec les droits root (su - root ou sudo)"${RESET}
	exit 1;
fi

# Tester si bien une base Arch
if ! check_pkg pacman; then
	echo ${RED}"Le paquet \"pacman\" n'est pas installé donc cette distribution n'est probablement pas être basée sur Arch :-("${RESET}
	exit 2;
fi

# Infos fichier log
echo ${YELLOW}"Pour suivre la progression :"${RESET}
echo ${BOLD}"tail -f $log_root"${RESET}
if ! check_pkg xclip; then pacman -S --noconfirm xclip >> "$log_root" 2>&1; fi
echo "tail -f $log_root"  | xclip -selection clipboard
echo "(commande copiée dans le presse-papier)"
echo

if [[ -f $log_root ]]; then
    echo -n "Suppression du fichier de log existant : "
    rm -f $log_root
    check_cmd
fi

# Date dans le log
echo '-------------------' >> "$log_root"
date >> "$log_root"

#Si VM
if [[ "$VM" != "none" ]]; then
    if [[ $(id -u) -ne "0" ]]; then
        echo ${RED}"Lancer le script avec les droits root (sudo)"${RESET}
        exit 1;
    fi

    msg_bold_blue "➜ Paramètrage Virtualisation"
    if [[ "$VM" != "none" ]]; then
        if ! check_pkg virtualbox-guest-utils; then
            echo -n "- - - Installation du paquet des guests : "
            pacman -S --needed --noconfirm virtualbox-guest-utils >> "$log_root"
            check_cmd

            echo -n "- - - Activation de vboxservice.service : "
            systemctl enable --now vboxservice.service >> "$log_root" 2>&1
            check_cmd

            echo ${YELLOW}"Pensez à redémarrer."${RESET}
            sleep $sleepmid
        fi
	sleep $sleepquick
        if [[ $(grep vboxsf /etc/group | grep -c $SUDO_USER) -lt 1 ]]; then
            echo -n "- - - Ajout du user au groupe vboxsf : "
            usermod -a -G vboxsf $SUDO_USER
            check_cmd

            echo -n "- - - Droits du dossier PartageVM : "
            chown -R $SUDO_USER:users /media/sf_PartageVM/
            check_cmd
        fi

    msg_bold_blue "➜ Chaotic aur"
    if [[ $(grep -c chaotic-mirrorlist /etc/pacman.conf) -lt 1 ]]; then
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
    fi
fi

### CONF PACMAN
msg_bold_blue "➜ Configuration pacman"
if [[ $(grep -c 'ILoveCandy' /etc/pacman.conf) -lt 1 ]]; then
    echo -n "- - - Correction ILoveCandy : "
    sed -i '/^#ParallelDownloads/a ILoveCandy' /etc/pacman.conf
    check_cmd
fi
if [[ $(grep -c "^ParallelDownloads" /etc/pacman.conf) -lt 1 ]]; then
    echo -n "- - - Correction téléchargements parallèles : "
    sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    check_cmd
fi
if [[ $(grep -c "^Color" /etc/pacman.conf) -lt 1 ]]; then
    echo -n "- - - Correction des couleurs : "
    sed -i 's/^#Color/Color/' /etc/pacman.conf
    check_cmd
fi

### CONF MAKEPKG
msg_bold_blue "➜ Configuration makepkg"
if [[ $(grep -c "^PKGEXT='.pkg.tar'" /etc/makepkg.conf) -lt 1 ]]; then
    echo -n "- - - Correction de la compression : "
    sed -i "s/^PKGEXT='.pkg.tar.zst'/PKGEXT='.pkg.tar'/" /etc/makepkg.conf
    check_cmd
fi

if [[ $(grep -c "^MAKEFLAGS=\"-j\$(nproc)\"" /etc/makepkg.conf) -lt 1 ]]; then
    echo -n "- - - Correction de l'utilisation des coeurs : "
    sed -i 's/^#MAKEFLAGS=.*/MAKEFLAGS=\"-j$(nproc)\"/' /etc/makepkg.conf
    check_cmd
fi

### CONF JOURNALD
msg_bold_blue "➜ Configuration journald.conf"
if [[ $(grep -c "SystemMaxUse=512M" /etc/systemd/journald.conf) -lt 1 ]]; then
    echo -n "- - - Correction de la taille maximale autorisée : "
    sed -i 's/^#SystemMaxUse=.*$/SystemMaxUse=512M/; s/^SystemMaxUse=.*$/SystemMaxUse=512M/' /etc/systemd/journald.conf
    check_cmd
fi

### CONF SYSTEMD-BOOT ou GRUB
if [[ -f /boot/loader/loader.conf ]] && [[ $(grep -c "timeout 1" /boot/loader/loader.conf) -lt 1 ]]; then
    msg_bold_blue "➜ Configuration menu systemd-boot"
    echo -n "- - - Kernel dernier sauvegardé sélectionné : "
    sed -i 's/^default .*$/default @saved/' /boot/loader/loader.conf
    check_cmd

    echo -n "- - - Timeout de 1s : "    
    sed -i 's/^timeout .*$/timeout 1/' /boot/loader/loader.conf
    check_cmd
fi

if [[ -f /etc/default/grub ]] && [[ $(grep -c "GRUB_TIMEOUT=1" /etc/default/grub) -lt 1 ]]; then
    msg_bold_blue "➜ Configuration menu grub"
    echo -n "- - - Timeout de 1s : "    
    sed -i 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=1/' /etc/default/grub
    check_cmd

    echo -n "- - - Regénérer grub.cfg : "
    grub-mkconfig -o /boot/grub/grub.cfg  >> "$log_root" 2>&1
    check_cmd
fi

### MAJ Système avec Pacman
echo -n ${BLUE}${BOLD}"➜ Mise à jour du système Pacman : "${RESET}
pacman -Syu --noconfirm >> "$log_root" 2>&1
check_cmd

### PAQUETS PACMAN
msg_bold_blue "➜ Gestion des paquets principaux pacman"
while read -r line
do
	if [[ "$line" == add:* ]]; then
		p=${line#add:}
		if ! check_pkg "$p"; then
			echo -n "- - - Installation paquet $p : "
			add_pkg_pacman "$p"
			check_cmd
		fi
	fi

	if [[ "$line" == del:* ]]; then
		p=${line#del:}
		if check_pkg "$p"; then
			echo -n "- - - Suppression paquet $p : "
			del_pkg_pacman "$p"
			check_cmd
		fi
	fi
done < "packages/$pacman_list"

if [[ "$DE" = 'KDE' ]]; then
    echo ${BLUE}"➜➜ Gestion des paquets Plasma"${RESET}
    while read -r line
    do
        if [[ "$line" == add:* ]]; then
            p=${line#add:}
            if ! check_pkg "$p"; then
                echo -n "- - - Installation paquet $p : "
                add_pkg_pacman "$p"
                check_cmd
            fi
        fi

        if [[ "$line" == del:* ]]; then
            p=${line#del:}
            if check_pkg "$p"; then
                echo -n "- - - Suppression paquet $p : "
                del_pkg_pacman "$p"
                check_cmd
            fi
        fi
    done < "$ICI/packages/pacman_plasma.list"
fi

if [[ "$DE" = 'XFCE' ]]; then
    echo ${BLUE}"➜➜ Gestion des paquets XFCE"${RESET}
    while read -r line
    do
        if [[ "$line" == add:* ]]; then
            p=${line#add:}
            if ! check_pkg "$p"; then
                echo -n "- - - Installation paquet $p : "
                add_pkg_pacman "$p"
                check_cmd
            fi
        fi

        if [[ "$line" == del:* ]]; then
            p=${line#del:}
            if check_pkg "$p"; then
                echo -n "- - - Suppression paquet $p : "
                del_pkg_pacman "$p"
                check_cmd
            fi
        fi
    done < "$ICI/packages/pacman_xfce.list"
fi

msg_bold_blue "➜ Configuration Flatpak"
## FLATHUB
if check_pkg flatpak && [[ $(flatpak remotes | grep -c flathub) -ne 1 ]]; then
	echo -n "- - - Installation Flathub : "
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo > /dev/null
	check_cmd

elif ! check_pkg flatpak; then
    echo -n "- - - Installation de Flatkpak : "
    add_pkg_pacman flatpak
    check_cmd
    echo -n "- - - Installation de Flathub : "
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo > /dev/null
    check_cmd
    echo -n "- - - Eviter le crénelage des polices : "
    add_pkg_pacman xdg-desktop-portal-gtk
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
msg_bold_blue "➜ Gestion des paquets FLATPAK (long si première installation)"
while read -r line
do
	if [[ "$line" == add:* ]]; then
		p=${line#add:}
		if ! check_flatpak "$p"; then
			echo -n "- - - Installation flatpak $p : "
			add_flatpak "$p"
			check_cmd
		fi
	fi

	if [[ "$line" == del:* ]]; then
		p=${line#del:}
		if check_flatpak "$p"; then
			echo -n "- - - Suppression flatpak $p : "
			del_flatpak "$p"
			check_cmd
		fi
	fi
done < "$ICI/packages/flatpak.list"

### NPM
if [[ "$VM" != "none" ]]; then
	msg_bold_blue "➜ Paquets Node.js via npm"
	if check_pkg npm && [[ $(npm list -g | grep -c 'clipboard-cli') -lt 1 ]]; then
	    echo -n "- - - Installation de clipboard-cli : "
	    npm install --global clipboard-cli >> "$log_root" 2>&1
	    check_cmd
	fi
fi

### Systemd
msg_bold_blue "➜ Paramètrage systemd"
if check_pkg timeshift && [[ $(check_systemd cronie.service 2>/dev/null) != "enabled" ]]; then
    echo -n "- - - Activation du service Timeshift : "
    systemctl enable cronie.service >> "$log_root" 2>&1
    check_cmd
fi

if ! check_pkg cups; then
    echo -n "- - - Installation du paquet cups : "
    add_pkg_pacman cups
    check_cmd
elif [[ $(check_systemd cups.socket 2>/dev/null) != "enabled" ]]; then
    echo -n "- - - Activation de cups.socket : "
    systemctl enable --now cups.socket >> "$log_root" 2>&1
    check_cmd
fi

if [[ $(check_systemd cups.service 2>/dev/null) != "enabled" ]]; then
    echo -n "- - - Activation de cups.service : "
    systemctl enable --now cups.service >> "$log_root" 2>&1
    check_cmd
fi

#fstrim pour SSD
#DISC_GRAN et DISC_MAX ne doivent pas avoir de valeur égale à 0
#Activé par défaut avec archinstall
device_name=$(lsblk | grep part | grep -v boot | awk '{print $1}' | head -n 1 | sed 's/└─//' )
disc_gran=$(lsblk --discard | grep $device_name | awk '{print $3}')
disc_max=$(lsblk --discard | grep $device_name | awk '{print $4}')

if [[ "$disc_gran" != '0B' ]] && [[ "$disc_max" != '0B' ]]; then
    add_pkg_pacman util-linux
    if [[ $(check_systemd fstrim.timer 2>/dev/null) != "enabled" ]]; then
        echo -n "- - - Activation du timer fstrim pour $device_name : "
        systemctl enable fstrim.timer >> "$log_root" 2>&1
        check_cmd
    fi
else
    echo "- - - Activation du timer fstrim : "
    echo "$device_name ne semble pas supporter fstrim."
fi

if ! check_pkg pacman-contrib; then
    echo -n "- - - Installation du paquet pacman-contrib : "
    add_pkg_pacman pacman-contrib
    check_cmd
fi
if [[ $(check_systemd paccache.timer 2>/dev/null) != "enabled" ]]; then
    echo -n "- - - Activation de paccache.timer : "
    systemctl enable paccache.timer >> "$log_root" 2>&1
    check_cmd
fi
if check_pkg openssh && [[ $(check_systemd sshd.service 2>/dev/null) != "enabled" ]]; then
    echo -n "- - - Activation du service sshd.service : "
    systemctl enable sshd.service >> "$log_root" 2>&1
    check_cmd
    if [[ $(grep -c "^#ListenAddress 0.0.0.0" /etc/ssh/sshd_config) -eq 1 ]]; then
        echo -n "- - - Limiter SSH au réseau local : "
        local_ip=$(ip a | grep wlan0 | grep inet | awk '{print $2}' | cut -f1 -d '/')
	check_local_ip=$(echo "$local_ip" | cut -f1 -d '.')
	if [[ "$check_local_ip" -eq 192 ]]; then
            sed -i 's/^#ListenAddress 0.0.0.0/ListenAddress $local_ip' /etc/ssh/sshd_config
            check_cmd
	else
            echo ${RED}"ERREUR"${RESET}
 	fi
    fi
fi

#Sauvegarde perso
msg_bold_blue "➜ Service et timer systemd pour sauvegarde perso"
if [[ "$VM" = "none" ]]; then # Uniquement si on n'est PAS dans une VM
    if [[ ! -f ~/Documents/Linux/backup_nettoyage.sh ]] && [[ "$DE" = 'KDE' ]]; then
        echo ${YELLOW}"/!\ ~/Documents/Linux/backup_nettoyage.sh manquant"${RESET}
        sleep $sleepmid
    elif [[ -f ~/Documents/Linux/backup_nettoyage.sh ]]; then
        if [[ ! -f /etc/systemd/system/backup_nettoyage.service ]]; then
            echo -n "- - - Copie backup_nettoyage.service : "
            mv $ICI/config/backup_nettoyage.service /etc/systemd/system/
            check_cmd
        fi
        if [[ ! -f /etc/systemd/system/backup_nettoyage.timer ]]; then
            echo -n "- - - Copie backup_nettoyage.timer : "
            mv $ICI/config/backup_nettoyage.timer /etc/systemd/system/
            check_cmd
        fi
        if [[ $(check_systemd backup_nettoyage.timer 2>/dev/null) != "enabled" ]]; then
            echo -n "- - - Activation du service backup_nettoyage.timer : "
            systemctl enable backup_nettoyage.timer >> "$log_root" 2>&1
            check_cmd
        fi
    fi
fi

msg_bold_blue "➜ Presse-papier Clipse"
#clipse doit avoir un service lancé au démarrage pour alimenter le presse-papier
if check_pkg clipse && check_pkg wl-clipboard && [[ ! -f /home/$SUDO_USER/.config/autostart/clipse.desktop ]] && [[ $(echo $XDG_SESSION_TYPE) = 'wayland' ]]; then
    echo -n "- - - Ajout clipse.desktop : "
    cp "$ICI/config/clipse.desktop" /home/$SUDO_USER/.config/autostart/clipse.desktop
    chmod +r /home/$SUDO_USER/.config/autostart/clipse.desktop
    check_cmd
    echo : "Commande pour raccourci clavier : ${BOLD}alacritty -e clipse${RESET}"
    
    if [[ $(cat /home/$SUDO_USER/.config/clipse/config.json | grep 'maxHistory' | grep -c '500') -lt 1 ]]; then
    	echo -n "- - - Nombre max d'entrées dans l'historique : "
     	sed -i 's/"maxHistory":.*/"maxHistory": 500,/' /home/$SUDO_USER/.config/clipse/config.json
     	check_cmd
    fi
fi

msg_bold_blue "➜ Fichiers de configuration"
if check_pkg alacritty && [[ ! -f /home/$SUDO_USER/.config/alacritty/alacritty.toml ]]; then
    echo -n "- - - Ajout alacritty.toml : "
    mkdir -p /home/$SUDO_USER/.config/alacritty
    cp "$ICI/config/alacritty.toml" /home/$SUDO_USER/.config/alacritty
    check_cmd
    if [[ "$VM" != "none" ]]; then
        sed -i 's/^decorations =.*/decorations = \"Full\"/' ~/.config/alacritty/alacritty.toml
    fi
    echo -n "- - - Propriétaire du dossier alacritty : "
    chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.config/alacritty
    check_cmd
fi

if check_pkg vim && [[ $(grep -c "syntax" /home/$SUDO_USER/.vimrc 2>/dev/null) -lt 1 ]]; then
    echo -n "- - - .vimrc : "
    cp "$ICI/config/vimrc" /home/$SUDO_USER/.vimrc
    check_cmd
fi

if [[ ! -f /home/$SUDO_USER/.hidden ]]; then
    echo -n "- - - Ajout .hidden pour masquer des dossiers du \$HOME : "
    printf "%s\n" "Modèles" "Musique" "Public" "Sync" "UpdateInfo" > /home/$SUDO_USER/.hidden
    check_cmd
fi

msg_bold_blue "➜ Suppression du bruit lors de recherches"
if [[ ! -f /etc/modprobe.d/nobeep.conf ]]; then
    touch /etc/modprobe.d/nobeep.conf
fi

if [[ $(grep -c "blacklist pcspkr" /etc/modprobe.d/nobeep.conf) -lt 1 ]]; then
    echo -n "- - - Blacklist pcspkr : "
    echo "blacklist pcspkr" | tee -a /etc/modprobe.d/nobeep.conf > /dev/null
    check_cmd
fi
if [[ $(grep -c "blacklist snd_pcsp" /etc/modprobe.d/nobeep.conf) -lt 1 ]]; then
    echo -n "- - - Blacklist snd_pcsp : "
    echo "blacklist snd_pcsp" | tee -a /etc/modprobe.d/nobeep.conf > /dev/null
    check_cmd
fi

# Rétention cache des paquets avec paccache
msg_bold_blue "➜ Paccache : cache des paquets"
if check_pkg pacman-contrib && [[ $(paccache -dv | grep -v .sig | awk -F'-[0-9]' '{print $1}' | sort | uniq -c | sort -nr | head -n 1 | awk '{print $1}') -gt 1 ]]
#Explication variable dans l'ordre : lister tous les paquets conservés, exclure les .sig, ne pas prendre en compte sur les numéros de version, trier, garder la valeur max, afficher la 1ère colonne 
then
	echo -n "- - - Ajustement de paccache à 1 version : "
	paccache -rk1
	check_cmd
fi

msg_bold_blue "➜ Pavé numérique"
# On crée les fichiers si besoin
if [ "$DE" = 'KDE' ] && [[ ! -f /etc/sddm.conf ]]; then
    touch /etc/sddm.conf
fi
if [ "$DE" = 'XFCE' ] && [[ ! -f /etc/lightdm/lightdm.conf ]]; then
    touch /etc/lightdm/lightdm.conf
fi

if [ "$DE" = 'KDE' ] && [[ $(grep -c "Numlock=on" /etc/sddm.conf) -lt 1 ]]; then
    echo -n "- - - Activation pour KDE Plasma : "
    echo "[General]" | tee -a /etc/sddm.conf > /dev/null && echo "Numlock=on" | tee -a /etc/sddm.conf > /dev/null
    check_cmd
elif [ "$DE" = 'XFCE' ] && [[ $(grep -c "numlockx" /etc/lightdm/lightdm.conf) -lt 1 ]]; then
    echo -n "- - - Activation pour XFCE : "
    sed -i 's/^#greeter-setup-script=/greeter-setup-script=\/usr\/bin\/numlockx on/' /etc/lightdm/lightdm.conf
    check_cmd
fi

msg_bold_blue "➜ Carte réseau Realtek"
#Gestion de la carte réseau Realtek RTL8821CE
if [[ "$VM" = "none" ]]; then
    if [[ $(lspci | grep -E -i 'network|ethernet|wireless|wi-fi' | grep -c RTL8821CE 2&>1) -eq 1 ]] && ! check_pkg rtl8821ce-dkms-git; then # Carte détectée mais paquet manquant
        echo -n "- - - Installation du paquet AUR  : "
        add_pkg_paru rtl8821ce-dkms-git
        check_cmd

        if [[ $(grep -c "blacklist rtw88_8821ce" /etc/modprobe.d/blacklist.conf > /dev/null 2&>1) -lt 1 ]]; then
            echo -n "- - - Configuration blacklist.conf  : "
            echo "# https://github.com/tomaspinho/rtl8821ce/tree/master#wi-fi-not-working-for-kernel--59" | tee -a /etc/modprobe.d/blacklist.conf > /dev/null
            echo "blacklist rtw88_8821ce" | tee -a /etc/modprobe.d/blacklist.conf > /dev/null
            check_cmd
        fi

        # Modifier les fichiers linux/linux-lts.conf pour ne pas avoir de remonter d'anomalie dans dmesg
        # On ajoute pci=noaer à la fin de la ligne qui commence par options root= (paramètre du noyau)
        # Définir le répertoire cible et les patterns des noms de fichiers
	# Ça reste visible avec journalctl -b --priority=3
        DIR="/boot/loader/entries"
        PATTERNS=("linux.conf" "linux-lts.conf")

        # Fonction pour ajouter ou modifier la ligne dans le fichier
        modify_file() {
            local file="$1"
            local tempfile=$(mktemp)

            if [ -f "$file" ]; then
                # Lire le fichier et ajouter/modifier la ligne
                while IFS= read -r line; do
                    if [[ "$line" =~ ^options\ root= ]]; then
                        if [[ "$line" != *"pci=noaer"* ]]; then
                            echo "${line} pci=noaer" >> "$tempfile"
                        else
                            echo "$line" >> "$tempfile"
                        fi
                    else
                        echo "$line" >> "$tempfile"
                    fi
                done < "$file"
            else
                # Créer le fichier avec la ligne par défaut
                echo "options root= pci=noaer" > "$tempfile"
            fi

            # Remplacer l'ancien fichier par le nouveau
            mv "$tempfile" "$file"
        }

        # Parcourir les motifs de fichiers cibles
        for pattern in "${PATTERNS[@]}"; do
            # Rechercher les fichiers correspondant au motif
            for filepath in "$DIR"/*_"$pattern"; do
                if [ -f "$filepath" ]; then
                    modify_file "$filepath"
                fi
            done
        done
	
    else
        echo ${YELLOW}"- - - Carte réseau Realtek RTL8821CE non détectée."${RESET}
    fi
fi

#########################
# Uncomplicated FireWall
#########################
msg_bold_blue "➜ Pare-Feu UFW"
if check_pkg ufw && [[ $(ufw status | grep -c active) -lt 1 ]]; then
    echo " - - - Paramétrage des règles par défaut"
    ufw reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow to 192.168.1.0/24
    ufw allow from 192.168.1.0/24
    ufw deny 22 # SSH - uniquement local autorisé
    ufw enable
    systemctl enable ufw.service >> "$log_root" 2>&1
    check_cmd

    if [[ $(grep -c 'IPV6=no' /etc/default/ufw) -lt 1 ]]; then
        echo -n "- - - Désactivation IPV6 : "
        sed -i sed -i 's/^IPV6=.*/IPV6=no/' /etc/default/ufw
        check_cmd
	ufw reload
    fi

    if [[ $(grep -c 'DEFAULT_FORWARD_POLICY=ACCEPT' /etc/default/ufw) -lt 1 ]]; then
        echo -n "- - - Autoriser la police de transfert (VPN...) : "
        sed -i sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY=ACCEPT/' /etc/default/ufw
        check_cmd
	ufw reload
    fi
fi

#NVIDIA
read -p ${BLUE}${BOLD}"➜ Besoin des paquets NVIDIA ? (y/N) "${RESET} -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]] && [[ "$VM" != "none" ]] && [[ $(lspci -vnn | grep -A 12 '\[030[02]\]' | grep -Ei "vga|3d|display|kernel" | grep -ic nvidia) -gt 0 ]]; then
    echo -n "- - - Installation des paquets NVIDIA : "
    pacman -S --needed --noconfirm pacman -S --needed nvidia nvidia-lts nvidia-utils nvidia-settings >> "$log_root" 2>&1
    check_cmd
fi

### OSheden
read -p ${BLUE}${BOLD}"➜ Besoin des spécificités pour OSheden ? (y/N) "${RESET} -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    echo ${BLUE}"➜➜ Gestion des paquets"${RESET}
    while read -r line
    do
        if [[ "$line" == add:* ]]; then
            p=${line#add:}
            if ! check_pkg "$p"; then
                echo -n "- - - Installation paquet $p : "
                add_pkg_pacman "$p"
                check_cmd
            fi
        fi

        if [[ "$line" == del:* ]]; then
            p=${line#del:}
            if check_pkg "$p"; then
                echo -n "- - - Suppression paquet $p : "
                del_pkg_pacman "$p"
                check_cmd
            fi
        fi
    done < "$ICI/packages/pacman_osheden.list"

    if [[ ! -d /home/$SUDO_USER/AndroidAll/Thèmes_Shorts/Alta ]] && [[ -d /home/$SUDO_USER/Thèmes/Alta/app/src/main/ ]]; then
        echo -n "➜➜ Création des liens symboliques : "
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

######################
# Android Studio
######################
read -p ${BLUE}${BOLD}"➜ Installer Android Studio ? (y/N) "${RESET} -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
    printf "\n- - - Test de la connexion au site\n"

    url="https://developer.android.com/studio?hl=fr"

    # Effectuer la requête HTTPS avec curl
    response=$(curl -sS -o /dev/null -w "%{http_code}" "$url")
    # -s pour mode silencieux
    # -S pour afficher les erreurs
    # -o /dev/null pour rediriger la sortie vers null
    # -w "%{http_code}" pour récupérer uniquement le code de statut HTTP

    #Contrôler la disponibilité du site
    if [[ $response -ne 200 ]]; then
        echo "${RED}- - - Impossible de se connecter au site $url${RESET}"
    else
        # Récupérer le contenu de la page
        page_content=$(curl -s "https://developer.android.com/studio?hl=fr")

        # Extraire l'URL de téléchargement pour Linux
        download_url=$(echo "$page_content" | grep -oP 'https://.*?android-studio-.*?-linux.tar.gz' | head -n 1)

        # Vérifier si l'URL a été trouvée
        if [[ -z "$download_url" ]]; then
            echo "${RED}- - - Impossible de trouver l'URL de téléchargement.${RESET}"
        else
            # Télécharger le fichier
            echo "- - - Téléchargement : "
            wget -P /tmp -q --show-progress "$download_url"

            filename=$(basename $(ls -1 /tmp/android-studio*))
            filesize=$(du /tmp/$filename | awk '{print $1}')
            path_install="/usr/local/android-studio"

            if [[ "$filesize" -lt 1000000 ]]; then
                echo "${RED}- - - Taille du fichier /tmp/$filename anormalement basse...${RESET}"
            else
                printf "\nInstallation lancée...\n"
                echo -n "- - - Création du dossier final : "
                mkdir -p $path_install
                check_cmd

                echo -n "- - - Décompresssion $filename : "
                tar -xzf /tmp/$filename -C $path_install --strip-components=1
                check_cmd

                echo -n "- - - Rendre studio.sh exécutable : "
                chmod +x $path_install/bin/studio.sh
                check_cmd

                echo -n "- - - Suppression du fichier original $filename : "
                rm -f "/tmp/$filename"
                check_cmd
                echo -n "- - - Changement du propriétaire et du groupe : "
                chown -R $SUDO_USER:$SUDO_USER $path_install
                check_cmd

                echo "${GREEN}${BOLD}Installation terminée.${RESET}"
                echo "Prêt pour ajouter le raccourci $path_install/bin/studio.sh"
		echo "Lancer Android Studio pour télécharger le SDK dans ~/Android/Sdk"
		sleep $sleepquick
            fi
        fi
    fi
fi

#Actions manuelles
echo
echo "${YELLOW}${BOLD}*******************"
echo "Actions manuelles"
echo "*******************${RESET}"
if [[ ! -d /home/$SUDO_USER/.local/share/plasma/look-and-feel/Colorful-Dark-Global-6/ ]]; then
    if [[ ! -d .local/share/plasma/desktoptheme/Colorful-Dark-Plasma ]]; then
	    echo "➜ Installer le thème ${BOLD}Colorful-Dark-Global-6${RESET}"
	    echo "Avec une opacité du tableau de bord : **translucide**"
     fi
fi

printf "\nConfigurer TIMESHIFT\n"
