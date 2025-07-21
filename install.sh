#!/usr/bin/env bash

###############################################################################
# install.sh — Post-installation & personnalisation Arch Linux                 #
###############################################################################

set -euo pipefail
mkdir -p "$HOME/Tmp"
source variables.sh

#####################
### Contrôles de base
#####################

### Vérification des arguments / Easter egg
if [[ -n "${1:-}" && "$1" != "arch" ]]; then
    echo "Usage : $(basename "$0") [arch]"
    exit 1
fi

# Easter egg visuel sur ./install.sh arch
if [[ "${1-}" == "arch" ]]; then
    cat << "EOF"
           .-'
       .o+'
      'oooo/
     +oooooo:
    -+oooooo+:
    `/    +oooo+:
    `/   ++++++++:
    `/++++++++++++++:
    `/+++ooooooooooooo/`
   ./ooosssso++osssssso+`
  .oossssso-```
 -osssssso.      :ssssssso.
:osssssss/        osssso+++.
/ossssssss/        +ssssooo/-
`/ossssso+/:-      -:/+osssso+-
  `+sso+:-`        `.-/+oso:
    `++:.                `-/+/
      .`                   `/
EOF
    echo -e "${BLUE}${BOLD}I use Arch Linux btw...${RESET}"
    exit 0
fi

# Tester la connexion Internet
if ! ping -c 1 google.com &> /dev/null; then
    echo "Pas de connexion Internet"
    exit 1;
fi

path_pacman=$(command -v pacman)
if [[ -z "$path_pacman" ]]; then
    msg_bold_red "Le paquet \"pacman\" n'est pas installé. Cette distribution n'est probablement pas Arch…"
    exit 1
fi

#####################
### Root first
#####################
if [[ $(id -u) -eq 0 ]]; then
    msg_bold_red "Ne PAS lancer ce script en root (ni sudo, ni su - root) !"
    exit 1
fi

sudo ./root_only.sh

### Nettoyage des anciens fichiers (log, post_install)
[[ -f $log_file ]] && rm -f "$log_file"
[[ -f $HOME/Tmp/post_installation.txt ]] && rm -f "$HOME/Tmp/post_installation.txt"

### Lecture du type d'installation (complète/lite)
if [[ ! -f "$ICI/type_install.txt" ]]; then
    msg_bold_red "Type d'installation inconnue"
    exit 1
fi
install_type=$(cat "$ICI/type_install.txt")
if [[ "$install_type" != "1" && "$install_type" != "2" ]]; then
    msg_bold_red "Anomalie dans le type d'installation"
    exit 1
fi
rm -f "$ICI/type_install.txt"

msg_bold_yellow "Pour suivre la progression :"
echo ${BOLD}"tail -f $log_file"${RESET}
if ! check_pkg xclip; then sudo pacman -S --noconfirm xclip &>> "$log_file" ; fi
echo "tail -f $log_file" | xclip -selection clipboard
echo "(commande copiée dans le presse-papier)"
echo

echo '-------------------' >> "$log_file"
date >> "$log_file"

#++++++++++++++++++++++++++++++++++++++
# [DEBUT] VM ONLY
#++++++++++++++++++++++++++++++++++++++
if [[ "$VM" != "none" ]]; then
    msg_bold_blue "➜ Paramètrage Virtualisation"
    if ! check_pkg virtualbox-guest-utils; then
        echo -n "- - Installation du paquet des guests : "
        sudo pacman -S --needed --noconfirm virtualbox-guest-utils >> "$log_file"
        check_cmd
        echo -n "- - Activation de vboxservice.service : "
        sudo systemctl enable --now vboxservice.service &>> "$log_file"
        check_cmd
    fi
    if [[ $(grep vboxsf /etc/group | grep -c $USER) -lt 1 ]]; then
        echo -n "- - Ajout du user au groupe vboxsf : "
        sudo usermod -a -G vboxsf $USER
        check_cmd
        echo -n "- - Droits du dossier PartageVM : "
        if [[ -d /media/sf_PartageVM ]]; then
            sudo chown -R $USER:$USER /media/sf_PartageVM/
            check_cmd
        else
            msg_bold_red "Le dossier habituel PartageVM n'a pas été trouvé"
        fi
        msg_bold_yellow "Penser à redémarrer."
        sleep $sleepmid
    fi
fi
#--------------------------------------
# [FIN] VM ONLY
#--------------------------------------

#++++++++++++++++++++++++++++++++++++++
# [DEBUT] POUR TOUS
#++++++++++++++++++++++++++++++++++++++
msg_bold_blue "➜ Configuration système de base"
if [[ $(grep -c "^ParallelDownloads" /etc/pacman.conf) -lt 1 ]]; then
    echo -n "- - [Pacman] Téléchargements parallèles : "
    sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
    check_cmd
fi
if [[ $(grep -c 'ILoveCandy' /etc/pacman.conf) -lt 1 ]]; then
    echo -n "- - [Pacman] ILoveCandy : "
    sudo sed -i '/^ParallelDownloads/a ILoveCandy' /etc/pacman.conf
    check_cmd
fi
if [[ $(grep -c "^VerbosePkgLists" /etc/pacman.conf) -lt 1 ]]; then
    echo -n "- - [Pacman] Listing des paquets verbeux : "
    sudo sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf
    check_cmd
fi
if [[ $(grep -c "^Color" /etc/pacman.conf) -lt 1 ]]; then
    echo -n "- - [Pacman] Couleurs : "
    sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
    check_cmd
fi
if [[ $(grep -c "^PKGEXT='.pkg.tar'" /etc/makepkg.conf) -lt 1 ]]; then
    echo -n "- - [Makepkg] Compression : "
    sudo sed -i "s/^PKGEXT='.pkg.tar.zst'/PKGEXT='.pkg.tar'/" /etc/makepkg.conf
    check_cmd
fi
if [[ $(grep -c "^MAKEFLAGS=\"-j\$(nproc)\"" /etc/makepkg.conf) -lt 1 ]]; then
    echo -n "- - [Makepkg] Utilisation des coeurs : "
    sudo sed -i 's/^#MAKEFLAGS=.*/MAKEFLAGS=\"-j$(nproc)\"/' /etc/makepkg.conf
    check_cmd
fi
if [[ $(grep -c "SystemMaxUse=512M" /etc/systemd/journald.conf) -lt 1 ]]; then
    echo -n "- - [Journald] Taille maximale : "
    sudo sed -i 's/^#SystemMaxUse=.*$/SystemMaxUse=512M/; s/^SystemMaxUse=.*$/SystemMaxUse=512M/' /etc/systemd/journald.conf
    check_cmd
fi
if [[ -f /boot/loader/loader.conf ]] && [[ $(grep -c "timeout 1" /boot/loader/loader.conf) -lt 1 ]]; then
    echo -n "- - [Systemd boot] Kernel dernier sauvegardé sélectionné : "
    sudo sed -i 's/^default .*$/default @saved/' /boot/loader/loader.conf
    check_cmd

    echo -n "- - [Systemd boot] Timeout de 1s : "
    sudo sed -i 's/^timeout .*$/timeout 1/' /boot/loader/loader.conf
    check_cmd
fi
if [[ -f /etc/default/grub ]] && [[ $(grep -c "GRUB_TIMEOUT=1" /etc/default/grub) -lt 1 ]]; then
    echo -n "- - [Grub] Timeout de 1s : "
    sudo sed -i 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=1/' /etc/default/grub
    check_cmd

    echo -n "- - [Grub] Regénérer grub.cfg : "
    sudo grub-mkconfig -o /boot/grub/grub.cfg  &>> "$log_file"
    check_cmd
fi

msg_bold_blue "➜ Mise à jour du système Pacman"
sudo pacman -Syu --noconfirm &>> "$log_file"

msg_bold_blue "➜ Paquets PACMAN par défaut"
while read -r line; do
    # Par défaut
    if [[ "$line" == add_defaut:* ]]; then
        p=${line#add_defaut:}
        if ! check_pkg "$p"; then
            echo -n "$sign_green $p : "
            add_pkg_pacman "$p"; check_pacman_status_install
        fi
    fi
    if [[ "$line" == del_defaut:* ]]; then
        p=${line#del_defaut:}
        if check_pkg "$p"; then
            echo -n "$sign_red $p : "
            del_pkg_pacman "$p"; check_pacman_status_uninstall
        fi
    fi

    # NON VM
    if [[ "$VM" = "none" ]]; then
        if [[ "$line" == add_not_vm:* ]]; then
            p=${line#add_not_vm:}
            if ! check_pkg "$p"; then
                echo -n "$sign_green $p : "
                add_pkg_pacman "$p"; check_pacman_status_install
            fi
        fi
        if [[ "$line" == del_not_vm:* ]]; then
            p=${line#del_not_vm:}
            if check_pkg "$p"; then
                echo -n "$sign_red $p : "
                del_pkg_pacman "$p"; check_pacman_status_uninstall
            fi
        fi

    # VM
    else
        if [[ "$line" == add_vm:* ]]; then
            p=${line#add_vm:}
            if ! check_pkg "$p"; then
                echo -n "$sign_green 'VM' $p : "
                add_pkg_pacman "$p"; check_pacman_status_install
            fi
        fi
        if [[ "$line" == del_vm:* ]]; then
            p=${line#del_vm:}
            if check_pkg "$p"; then
                echo -n "$sign_red 'VM' $p : "
                del_pkg_pacman "$p"; check_pacman_status_uninstall
            fi
        fi
    fi

    # DE = PLASMA
    if [[ "$DE" = 'KDE' ]]; then
        if [[ "$line" == add_plasma:* ]]; then
            p=${line#add_plasma:}
            if ! check_pkg "$p"; then
                echo -n "$sign_green 'Plasma' $p : "
                add_pkg_pacman "$p"; check_pacman_status_install
            fi
        fi
        if [[ "$line" == del_plasma:* ]]; then
            p=${line#del_plasma:}
            if check_pkg "$p"; then
                echo -n "$sign_red 'Plasma' $p : "
                del_pkg_pacman "$p"; check_pacman_status_uninstall
            fi
        fi

    # DE = XFCE
    elif [[ "$DE" = 'XFCE' ]]; then
        if [[ "$line" == add_xfce:* ]]; then
            p=${line#add_xfce:}
            if ! check_pkg "$p"; then
                echo -n "$sign_green 'Xfce' $p : "
                add_pkg_pacman "$p"; check_pacman_status_install
            fi
        fi
        if [[ "$line" == del_xfce:* ]]; then
            p=${line#del_xfce:}
            if check_pkg "$p"; then
                echo -n "$sign_red 'Xfce' $p : "
                del_pkg_pacman "$p"; check_pacman_status_uninstall
            fi
        fi
    fi
done < "packages/pacman.list"

msg_bold_blue "➜ Configuration Flatpak"
if check_pkg flatpak && [[ $(flatpak remotes | grep -c flathub) -ne 1 ]]; then
	echo -n "- - Installation Flathub : "
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo > /dev/null; check_cmd
elif check_pkg flatpak && [[ $(flatpak remotes | grep -c flathub) -eq 1 ]] && ! check_pkg xdg-desktop-portal-gtk; then
    echo -n "- - Eviter le crénelage des polices : "
    add_pkg_pacman xdg-desktop-portal-gtk; check_cmd
fi

msg_bold_blue "➜ Paquets FLATPAK par défaut"
if [[ $(grep -e "^add" "$ICI/packages/flatpak.list" | wc -l) -gt 0 ]] && [[ $(flatpak list | grep -c 'org.freedesktop.Platform.GL.default') -lt 1 ]]; then
    echo "(besoin d'installer des paquets système en plus)"
fi

while read -r line; do
    # Par défaut
	if [[ "$line" == add_defaut:* ]]; then
		p=${line#add_defaut:}
		if ! check_flatpak "$p"; then
			echo -n "$sign_green $p : "
			add_flatpak "$p"; check_flatpak_status_install
		fi
	fi
	if [[ "$line" == del_defaut:* ]]; then
		p=${line#del_defaut:}
		if check_flatpak "$p"; then
			echo -n "$sign_red $p : "
			del_flatpak "$p"; check_flatpak_status_uninstall
		fi
	fi

    # NON VM
    if [[ "$VM" = "none" ]]; then
        if [[ "$line" == add_not_vm:* ]]; then
            p=${line#add_not_vm:}
            if ! check_flatpak "$p"; then
                echo -n "$sign_green $p : "
                add_flatpak "$p"; check_flatpak_status_install
            fi
        fi
        if [[ "$line" == del_not_vm:* ]]; then
            p=${line#del_not_vm:}
            if check_flatpak "$p"; then
                echo -n "$sign_red $p : "
                del_flatpak "$p"; check_flatpak_status_uninstall
            fi
        fi

    # VM
    else
        if [[ "$line" == add_vm:* ]]; then
            p=${line#add_vm:}
            if ! check_flatpak "$p"; then
                echo -n "$sign_green $p : "
                add_flatpak "$p"; check_flatpak_status_install
            fi
        fi
        if [[ "$line" == del_vm:* ]]; then
            p=${line#del_vm:}
            if check_flatpak "$p"; then
                echo -n "$sign_red $p : "
                del_flatpak "$p"; check_flatpak_status_uninstall
            fi
        fi
    fi
done < "$ICI/packages/flatpak.list"

msg_bold_blue "➜ Configuration système additionnelle"
if [[ -f /etc/sudoers.d/00_$USER ]] && check_pkg plocate && [[ $(sudo grep -c "/usr/bin/updatedb" /etc/sudoers.d/00_$USER) -lt 1 ]] ; then
    echo -n "- - [Sudoers] Commande updatedb sans mot de passe : "
    sudo echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/updatedb" >> /etc/sudoers.d/00_$USER; check_cmd
fi

if [[ $(check_systemd paccache.timer 2>/dev/null) != "enabled" ]]; then
    echo -n "- - [Paccache] Activation du timer : "
    sudo systemctl enable paccache.timer &>> "$log_file"; check_cmd
fi
if check_pkg openssh && [[ $(check_systemd sshd.service 2>/dev/null) != "enabled" ]]; then
    echo -n "- - [SSH] Activation du service : "
    sudo systemctl enable sshd.service &>> "$log_file"; check_cmd
fi


# Rétention cache des paquets avec paccache
if check_pkg pacman-contrib && [[ $(paccache -dv | grep -v .sig | awk -F'-[0-9]' '{print $1}' | sort | uniq -c | sort -nr | head -n 1 | awk '{print $1}') -gt 1 ]]; then
#Explication variable dans l'ordre : lister tous les paquets conservés, exclure les .sig, ne pas prendre en compte sur les numéros de version, trier, garder la valeur max, afficher la 1ère colonne
    if [[ "$VM" != "none" ]]; then
        echo -n "- - [Paccache] Ajustement à 1 version : " && sudo paccache -rk1
    else
        echo -n "- - [Paccache] Ajustement à 0 version : " && sudo paccache -rk0
    fi
    check_cmd
fi

if check_pkg syncthing && [[ $(check_systemd_user syncthing.service 2>/dev/null) != "enabled" ]]; then
    echo -n "[Syncthing] Activation du service : "
    systemctl --user enable syncthing.service &>> "$log_file"; check_cmd
fi

#Nerd Font
#Github => https://github.com/source-foundry/Hack?tab=readme-ov-file#quick-installation
if [[ $(fc-list | grep -c "Hack" 2>&1 ) -lt 1 ]]; then
    echo -n "- - [Nerd Font] Téléchargement de la police HACK : "
    derniere_version=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    url_telechargement="https://github.com/ryanoasis/nerd-fonts/releases/download/${derniere_version}/Hack.zip"
    curl -L -o $HOME/Tmp/Hack.zip "$url_telechargement" &>> "$log_file"; check_cmd

    if [[ -f $HOME/Tmp/Hack.zip ]]; then
        echo -n "- - [Nerd Font] Décompression de l'archive : "
        sudo unzip $HOME/Tmp/Hack.zip -d /usr/share/fonts &>> "$log_file"; check_cmd

        echo -n "- - [Nerd Font] Regénération du cache des polices : "
        fc-cache -f -v &>> "$log_file"; check_cmd
        echo -n "- - [Nerd Font] Contrôle de l'installation : "
        if [[ $(fc-list | grep -c "Hack" 2>&1) -gt 0 ]]; then msg_bold_green "OK"; else msg_bold_red "ERREUR"; fi
    fi
fi

msg_bold_blue "➜ Configuration shell"
if check_pkg zsh && [[ ! -d $HOME/.oh-my-zsh ]]; then
    echo "- - [Oh My ZSH] Installation"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" # &>> "$log_file"  # pas dans les logs pour le définir comme shell par défaut
fi
if check_pkg zsh && [[ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]]; then
    echo -n "- - [ZSH Plugin] Installation zsh-autosuggestions : "
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions &>> "$log_file"; check_cmd
fi
if check_pkg zsh && [[ ! -d $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]]; then
    echo -n "- - [ZSH Plugin] Installation zsh-syntax-highlighting : "
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting &>> "$log_file"; check_cmd
fi
if check_pkg zsh && [[ ! -d $HOME/.oh-my-zsh/custom/themes/powerlevel10k ]]; then
    echo -n "- - [ZSH Thème] Installation powerlevel10k : "
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k &>> "$log_file"; check_cmd
    echo -n "- - [ZSH Thème] Définir powerlevel10k par défaut : "
    sed -i 's/^ZSH_THEME.*$/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/' $HOME/.zshrc; check_cmd
fi
if check_pkg zsh && [[ $(grep -c 'zsh-syntax-highlighting' $HOME/.zshrc) -lt 1 ]]; then
    if [[ -f $HOME/.zshrc ]]; then
        echo -n "- - [ZSH Plugins] Activation des plugins : "
        sed -E -i 's/plugins=\((.*?)\)/plugins=(colored-man-pages copyfile copypath eza git gradle safe-paste web-search zsh-autosuggestions zsh-syntax-highlighting)/' $HOME/.zshrc; check_cmd
    else
        msg_bold_red "$HOME/.zshrc manquant"
    fi
fi
#Normalement non requis car déjà défini précédemment
#if check_pkg zsh && [[ $(echo $SHELL | grep -c "zsh") -lt 1 ]]; then
#    echo -n "- - ZSH devient le shell par défaut : "
#    chsh -s /usr/bin/zsh
#    check_cmd
#    echo ${YELLOW}"Déconnexion requise pour changer le shell par défaut"${RESET}
#fi

if check_pkg zsh; then
    echo "- - [ZSHRC] Ajout des personnalisations"
    if [ ! -f "$ICI/config/alias_listing" ]; then
        echo "Le fichier source des alias n'existe pas."
    elif [ ! -f "$HOME/.zshrc" ]; then
        msg_bold_red "$HOME/.zshrc manquant"
    else
        if [[ $(grep -c "#BEGIN_Perso" "$HOME/.zshrc" ) -eq 1 ]]; then
            msg_bold_yellow "Les personnalisations sont déjà en place"
        else
            awk '/#BEGIN_Perso/,/#END_Perso/' "$ICI/config/alias_listing" >> "$HOME/.zshrc"
            msg_bold_green "Personnalisations ajoutées"
        fi
    fi

    if [[ ! -f $HOME/Documents/Linux/Divers_Scripts/uarch.sh ]]; then
        echo -n "- - - Déplacement de uarch.sh : "
        mkdir -p $HOME/Documents/Linux/Divers_Scripts && cp $ICI/config/uarch.sh $HOME/Documents/Linux/Divers_Scripts ; check_cmd
        echo -n "- - - Déplacement de shared.sh : "
        mkdir -p $HOME/Documents/Linux/Divers_Scripts && cp $ICI/config/shared.sh $HOME/Documents/Linux/Divers_Scripts; check_cmd
    fi
fi

if ! check_pkg paru && check_pkg git && check_pkg base-devel; then
    msg_bold_blue "➜ Installation de paru"
    #rustup default stable &>> "$log_file"
    cd "$ICI"
    git clone https://aur.archlinux.org/paru.git &>> "$log_file"
    cd paru &>> "$log_file" && makepkg -si
    echo -n "- - Statut de l'installation : "
    pacman -Q paru > /dev/null; check_cmd
    echo -n "- - Nettoyage de l'installation : "
    cd "$ICI" && rm -rf "$ICI/paru"; check_cmd

    if check_pkg paru && [[ $(grep -c "^#NewsOnUpgrade" /etc/paru.conf) -lt 1 ]]; then
        echo -n "- - Correction de NewsOnUpgrade : "
        sudo sed -i 's/^#NewsOnUpgrade/NewsOnUpgrade/' /etc/paru.conf; check_cmd
    fi
fi

msg_bold_blue "➜ Paquets PARU"
if check_pkg paru; then
    while read -r line; do
        # Par défaut
        if [[ "$line" == add_defaut:* ]]; then
            p=${line#add_defaut:}
            if ! check_pkg "$p"; then
                echo -n "$sign_green $p : "
                add_pkg_paru "$p"; check_pacman_status_install
            fi
        fi
        if [[ "$line" == del_defaut:* ]]; then
            p=${line#del_defaut:}
            if check_pkg "$p"; then
                echo -n "$sign_red $p : "
                del_pkg_paru "$p"; check_pacman_status_uninstall
            fi
        fi

        #Si NON VM
        if [[ "$VM" = "none" ]]; then
            if [[ "$line" == add_not_vm:* ]]; then
                p=${line#add_not_vm:}
                if ! check_pkg "$p"; then
                    echo -n "$sign_green $p : "
                    add_pkg_paru "$p"; check_pacman_status_install
                fi
            fi
            if [[ "$line" == del_not_vm:* ]]; then
                p=${line#del_not_vm:}
                if check_pkg "$p"; then
                    echo -n "$sign_red $p : "
                    del_pkg_paru "$p"; check_pacman_status_uninstall
                fi
            fi
        fi
    done < "packages/paru.list"
fi

msg_bold_blue "➜ Fichiers de configuration"
if ! check_pkg xdg-user-dirs || [[ ! -d "$HOME"/Documents ]]; then
    echo -n "- - [xdg-user-dirs] Installation : "
    add_pkg_pacman xdg-user-dirs; check_cmd
    echo -n "- - [xdg-user-dirs] Génération des dossiers : "
    xdg-user-dirs-update; check_cmd
fi

if [[ ! -f "$HOME"/.hidden ]]; then
    echo -n "- - Ajout .hidden pour masquer des dossiers du \$HOME : "
    printf "%s\n" "Modèles" "Musique" "Public" "Sync" "UpdateInfo" > "$HOME"/.hidden; check_cmd
fi

if check_pkg kitty && [[ ! -f "$HOME"/.config/kitty/kitty.conf ]]; then
    echo -n "- - [Kitty] Fichier de configuration : "
    mkdir -p "$HOME"/.config/kitty && cp "$ICI/config/kitty.conf" "$HOME"/.config/kitty; check_cmd
    echo -n "- - [Kitty] Thème catppuccin Mocha : "
    kitten theme catppuccin-mocha; check_cmd
    echo -n "- - [Kitty] Background : "
    cp "$ICI/config/background.png" "$HOME"/.config/kitty; check_cmd
fi

if check_pkg neovim && [[ $(grep -c "nocompatible" "$HOME"/.config/nvim/init.vim 2>/dev/null) -lt 1 ]]; then
    echo -n "- - [NeoVim] Config de base : "
    mkdir -p "$HOME"/.config/nvim/ && cp "$ICI/config/neovim" "$HOME"/.config/nvim/init.vim; check_cmd

    echo -n "- - [NeoVim] Plugin manager vim-plug : "
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' &>> "$log_file"; check_cmd
    echo "${YELLOW}Taper \"PlugInstall\" en mode commande pour activer les plugins${RESET}" | tee -a $HOME/Tmp/post_installation.txt
    ask_continue
fi

#--------------------------------------
# [FIN] POUR TOUS
#--------------------------------------


#++++++++++++++++++++++++++++++++++++++
# [DEBUT] FAUT PAS ETRE DANS UNE VM
#++++++++++++++++++++++++++++++++++++++
if [[ "$VM" = "none" ]]; then
    if [[ ! -f /etc/samba/smb.conf ]]; then
        echo -n "- - [SAMBA] Fichier smb.conf : "
        sudo cp "$ICI/config/smb.conf" /etc/samba; check_cmd
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
            echo -n "- - [fstrim] Activation du timer $device_name : "
            sudo systemctl enable fstrim.timer &>> "$log_file"; check_cmd
        fi
    else
        echo "- - [fstrim] Activation du timer : "
        msg_bold_red "$device_name ne semble pas supporter fstrim."
    fi

    #Suppression du bruit lors de recherches"
    if [[ ! -f /etc/modprobe.d/nobeep.conf ]]; then
        echo -n "- - [Bruit recherche] Création du fichier de configuration : "
        sudo touch /etc/modprobe.d/nobeep.conf; check_cmd
    fi

    if [[ $(grep -c "blacklist pcspkr" /etc/modprobe.d/nobeep.conf) -lt 1 ]]; then
        echo -n "- - [Bruit recherche] Blacklist pcspkr : "
        sudo echo "blacklist pcspkr" | sudo tee -a /etc/modprobe.d/nobeep.conf > /dev/null; check_cmd
    fi
    if [[ $(grep -c "blacklist snd_pcsp" /etc/modprobe.d/nobeep.conf) -lt 1 ]]; then
        echo -n "- - [Bruit recherche] Blacklist snd_pcsp : "
        sudo echo "blacklist snd_pcsp" | sudo tee -a /etc/modprobe.d/nobeep.conf > /dev/null; check_cmd
    fi

    # Pavé numérique
    if [ "$DE" = 'KDE' ] && [[ ! -f /etc/sddm.conf ]]; then
        echo -n "- - [Pavé numérique] Création du fichier de configuration SDDM : "
        sudo touch /etc/sddm.conf; check_cmd
    fi
    if [ "$DE" = 'XFCE' ] && [[ ! -f /etc/lightdm/lightdm.conf ]]; then
        echo -n "- - [Pavé numérique] Création du fichier de configuration LIGHTDM : "
        sudo touch /etc/lightdm/lightdm.conf; check_cmd
    fi

    if [ "$DE" = 'KDE' ] && [[ $(grep -c "Numlock=on" /etc/sddm.conf) -lt 1 ]]; then
        echo -n "- - [Pavé numérique] Activation pour KDE Plasma : "
        sudo echo "[General]" | sudo tee -a /etc/sddm.conf > /dev/null && echo "Numlock=on" | sudo tee -a /etc/sddm.conf > /dev/null; check_cmd
    elif [ "$DE" = 'XFCE' ] && [[ $(grep -c "numlockx" /etc/lightdm/lightdm.conf) -lt 1 ]]; then
        echo -n "- - [Pavé numérique] Activation pour XFCE : "
        sudo sed -i 's/^#greeter-setup-script=/greeter-setup-script=\/usr\/bin\/numlockx on/' /etc/lightdm/lightdm.conf; check_cmd
    fi

    msg_bold_blue "➜ Pacman hooks"
    if [[ ! -f /usr/share/libalpm/hooks/z_pacnew.hook ]]; then
        echo -n "- - Ajout de z_pacnew.hook : "
        sudo cp $ICI/config/z_pacnew.hook /usr/share/libalpm/hooks; check_cmd
        if [[ ! -f $HOME/Documents/Linux/Divers_Scripts/pacman_pacnew.hook ]]; then
            echo -n "- - - Déplacement de pacman_pacnew.hook : "
            mkdir -p $HOME/Documents/Linux/Divers_Scripts && cp $ICI/config/pacman_pacnew.hook $HOME/Documents/Linux/Divers_Scripts; check_cmd
        fi
    fi

    if ! check_pkg nvidia && ! check_pkg nvidia-lts && [[ $(lspci -vnn | grep -A 12 '\[030[02]\]' | grep -Ei "vga|3d|display|kernel" | grep -ic nvidia) -gt 0 ]]; then
        msg_bold_blue "➜ Paquets Nvidia"
        sudo pacman -S --needed --noconfirm nvidia nvidia-lts nvidia-utils nvidia-settings &>> "$log_file"; check_cmd
    fi
fi

#--------------------------------------
# [FIN] FAUT PAS ETRE DANS UNE VM
#--------------------------------------

#++++++++++++++++++++++++++++++++++++++
# [DEBUT] Desktop Environment
#++++++++++++++++++++++++++++++++++++++
if [[ "$DE" = 'KDE' ]]; then
    msg_bold_blue "➜ KDE Dolphin services menu"
    if check_pkg meld && [[ ! -f $HOME/.local/share/kio/servicemenus/compare-using-meld.desktop ]]; then
    echo -n "- - Comparer avec Meld : "
        if [ -f "$ICI/config/compare-using-meld.desktop" ]; then
        mkdir -p $HOME/.local/share/kio/servicemenus && cp "$ICI/config/compare-using-meld.desktop" $HOME/.local/share/kio/servicemenus; check_cmd
        fi
    fi
fi

#--------------------------------------
# [FIN] Desktop Environment
#--------------------------------------

#++++++++++++++++++++++++++++++++++++++
# [DEBUT] VERSION COMPLÈTE OU LITE
#++++++++++++++++++++++++++++++++++++++
if [ "$install_type" = 1 ]; then
    msg_bold_blue "➜ Paquets PACMAN supplémentaires FULL"
    while read -r line; do
        if [[ "$line" == add_full:* ]]; then
            p=${line#add_full:}
            if ! check_pkg "$p"; then
                echo -n "$sign_green $p : "
                add_pkg_pacman "$p"; check_pacman_status_install
            fi
        fi

        if [[ "$line" == del_full:* ]]; then
            p=${line#del_full:}
            if check_pkg "$p"; then
                echo -n "$sign_red $p : "
                del_pkg_pacman "$p"; check_pacman_status_uninstall
            fi
        fi
    done < "packages/pacman.list"

    if check_pkg virtualbox-host-dkms; then
        msg_bold_blue "➜ Extension pack pour Virtualbox"
        latest=$(wget -qO- https://download.virtualbox.org/virtualbox/LATEST.TXT | tr -d '\r\n')
        if [[ -n "$latest" ]]; then
            url="https://download.virtualbox.org/virtualbox/${latest}/Oracle_VirtualBox_Extension_Pack-${latest}.vbox-extpack"
            if [[ -n "$url" ]]; then
                echo "Téléchargement de la version ${latest}"
                wget -P $HOME/Tmp -q --show-progress "$url" && \
                msg_bold_green "Téléchargement réussi." && \
                printf "\n- Installer le VirtualBox Extension pack ${latest}, disponible dans ~/Tmp.\n" >> $HOME/Tmp/post_installation.txt
            else
                msg_bold_red "Échec de la résolution de l'URL de téléchargement"
            fi
            ask_continue
        else
            msg_bold_red "Impossible de récupérer la dernière version connue"
        fi
    fi

    msg_bold_blue "➜ Paquets PARU supplémentaires FULL"
    if check_pkg paru; then
        while read -r line; do
            # Par défaut
            if [[ "$line" == add_full:* ]]; then
                p=${line#add_full:}
                if ! check_pkg "$p"; then
                    echo -n "$sign_green $p : "
                    add_pkg_paru "$p"; check_pacman_status_install
                fi
            fi
            if [[ "$line" == del_full:* ]]; then
                p=${line#del_full:}
                if check_pkg "$p"; then
                    echo -n "$sign_red $p : "
                    del_pkg_paru "$p"; check_pacman_status_uninstall
                fi
            fi
        done < "packages/paru.list"
    fi

    msg_bold_blue "➜ Paquets FLATPAK supplémentaires FULL"
    while read -r line; do
        if [[ "$line" == add_full:* ]]; then
            p=${line#add_full:}
            if ! check_flatpak "$p"; then
                echo -n "$sign_green $p : "
                add_flatpak "$p"; check_flatpak_status_install
            fi
        fi
        if [[ "$line" == del_full:* ]]; then
            p=${line#del_full:}
            if check_flatpak "$p"; then
                echo -n "$sign_red $p : "
                del_flatpak "$p"; check_flatpak_status_uninstall
            fi
        fi
    done < "$ICI/packages/flatpak.list"

    if [[ "$VM" = "none" ]]; then
        msg_bold_blue "➜ Service et timer systemd pour sauvegarde perso"
        if [[ ! -f $HOME/Documents/Linux/backup_nettoyage.sh ]]; then
            echo ${YELLOW}"/!\ $HOME/Documents/Linux/backup_nettoyage.sh manquant"${RESET}
            ask_continue
        elif [[ -f $HOME/Documents/Linux/backup_nettoyage.sh ]]; then
            if [[ ! -f /etc/systemd/system/backup_nettoyage.service ]]; then
                echo -n "- - Copie backup_nettoyage.service : "
                sudo mv $ICI/config/backup_nettoyage.service /etc/systemd/system/; check_cmd
            fi
            if [[ ! -f /etc/systemd/system/backup_nettoyage.timer ]]; then
                echo -n "- - Copie backup_nettoyage.timer : "
                sudo mv $ICI/config/backup_nettoyage.timer /etc/systemd/system/; check_cmd
            fi
            if [[ $(check_systemd backup_nettoyage.timer 2>/dev/null) != "enabled" ]]; then
                echo -n "- - Activation du service backup_nettoyage.timer : "
                sudo systemctl enable backup_nettoyage.timer &>> "$log_file"; check_cmd
            fi
        fi

        msg_bold_blue "➜ Configuration pour installation ${BOLD}Complète${RESET}"
        if check_pkg timeshift && [[ $(check_systemd cronie.service 2>/dev/null) != "enabled" ]]; then
            echo -n "- - [Timeshift] Activation du service : "
            sudo systemctl enable cronie.service &>> "$log_file"; check_cmd
        fi

        if check_pkg cups && [[ $(check_systemd cups.socket 2>/dev/null) != "enabled" ]]; then
            echo -n "- - [Cups] Activation de cups.socket : "
            sudo systemctl enable --now cups.socket &>> "$log_file"; check_cmd
        fi
        if [[ $(check_systemd cups.service 2>/dev/null) != "enabled" ]]; then
            echo -n "- - [Cups] Activation de cups.service : "
            sudo systemctl enable --now cups.service &>> "$log_file"; check_cmd
        fi
        if check_pkg protonmail-bridge-core && [[ ! -f "$HOME"/.config/autostart/protonmail.desktop ]]; then
            echo -n "- - [ProtonMail Bridge Core] Démarrage auto : "
            mkdir -p "$HOME"/.config/autostart && cp "$ICI/config/protonmail.desktop" "$HOME"/.config/autostart/protonmail.desktop; check_cmd
            printf "\nUtiliser protonmail-bridge pour avoir le mot de passe pour Thunderbird puis supprimer le paquet !\n" >> $HOME/Tmp/post_installation.txt
        fi
        if check_pkg rust; then
            if [[ ! -f "$HOME"/.cargo/bin/cargo-install-update ]]; then
                echo -n "- - [Cargo] Installation de cargo-update : "
                cargo install cargo-update &>> "$log_file"; check_cmd
            fi
            if [[ ! -f "$HOME"/.cargo/bin/arx ]]; then
                echo -n "- - [Cargo] Installation de arx : "
                cargo install arx &>> "$log_file"; check_cmd
            fi
        fi

        msg_bold_blue "➜ Carte réseau Realtek RTL8821CE"
        if [[ $(lspci | grep -E -i 'network|ethernet|wireless|wi-fi' | grep -c RTL8821CE) -eq 1 ]]; then # Carte détectée mais paquet manquant
            if ! check_pkg rtl8821ce-dkms-git; then
                echo -n "- - Installation du paquet AUR  : "
                add_pkg_paru rtl8821ce-dkms-git; check_cmd
            fi

            if [[ $(grep -c "blacklist rtw88_8821ce" /etc/modprobe.d/blacklist.conf) -lt 1 ]]; then
                echo -n "- - Configuration blacklist.conf  : "
                sudo echo "# https://github.com/tomaspinho/rtl8821ce/tree/master#wi-fi-not-working-for-kernel--59" | sudo tee -a /etc/modprobe.d/blacklist.conf > /dev/null
                sudo echo "blacklist rtw88_8821ce" | sudo tee -a /etc/modprobe.d/blacklist.conf > /dev/null; check_cmd
            fi

#            # Modifier les fichiers linux/linux-lts.conf pour ne pas avoir de remonter d'anomalie dans dmesg
#            # On ajoute pci=noaer à la fin de la ligne qui commence par options root= (paramètre du noyau)
#            # Définir le répertoire cible et les patterns des noms de fichiers
#            # Ça reste visible avec journalctl -b --priority=3
#            DIR="/boot/loader/entries"
#            PATTERNS=("linux.conf" "linux-lts.conf")
#
#            # Fonction pour ajouter ou modifier la ligne dans le fichier
#            modify_file() {
#                local file="$1"
#                local tempfile=$(mktemp)
#
#                if [ -f "$file" ]; then
#                    # Lire le fichier et ajouter/modifier la ligne
#                    while IFS= read -r line; do
#                        if [[ "$line" =~ ^options\ root= ]]; then
#                            if [[ "$line" != *"pci=noaer"* ]]; then
#                                echo "${line} pci=noaer" >> "$tempfile"
#                            else
#                                echo "$line" >> "$tempfile"
#                            fi
#                        else
#                            echo "$line" >> "$tempfile"
#                        fi
#                    done < "$file"
#                else
#                    # Créer le fichier avec la ligne par défaut
#                    echo "options root= pci=noaer" > "$tempfile"
#                fi
#
#                # Remplacer l'ancien fichier par le nouveau
#                sudo mv "$tempfile" "$file"
#            }
#
#            # Parcourir les motifs de fichiers cibles
#            for pattern in "${PATTERNS[@]}"; do
#                # Rechercher les fichiers correspondant au motif
#                for filepath in "$DIR"/*_"$pattern"; do
#                    if [ -f "$filepath" ]; then
#                        modify_file "$filepath"
#                    fi
#                done
#            done

        else
            echo ${YELLOW}"- - Carte réseau Realtek RTL8821CE non détectée."${RESET}
        fi

        # OSheden
        if [[ ! -d "$HOME"/AndroidAll/Thèmes_Shorts/Alta ]] && [[ -d "$HOME"/Thèmes/Alta/app/src/main/ ]]; then
            msg_bold_blue "➜ Création des liens symboliques pour les packs d'icônes"
            declare -A themes=(
                [Alta]=Alta
                [Altess]=Altess
                [Azulox]=Azulox
                [Black_Army_Diamond]=BlackArmyDiamond
                [Black_Army_Emerald]=BlackArmyEmerald
                [Black_Army_Omni]=BlackArmyOmni
                [Black_Army_Ruby]=BlackArmyRuby
                [Black_Army_Sapphire]=BlackArmySapphire
                [Caya]=Caya
                [Ciclo]=Ciclo
                [DarkArmyDiamond]=DarkArmyDiamond
                [DarkArmyEmerald]=DarkArmyEmerald
                [DarkArmyOmni]=DarkArmyOmni
                [DarkArmyRuby]=DarkArmyRuby
                [DarkArmySapphire]=DarkArmySapphire
                [Darky]=Darky
                [Darly]=Darly
                [Distraction_Free]=Distraction
                [Ecliptic]=Ecliptic
                [EclipticBrown]=EclipticBrown
                [EclipticPink]=EclipticPink
                [EclipticRed]=EclipticRed
                [EclipticWhite]=EclipticWhite
                [Focus]=Focus
                [Friendly]=Friendly
                [GIN]=GIN
                [GoldOx]=GoldOx
                [Goody]=Goody
                [Lox]=Lox
                [Luzicon]=Luzicon
                [NubeReloaded]=NubeReloaded
                [Oscuro]=Oscuro
                [Raya_Black]=RayaBlack
                [RayaReloaded]=RayaReloaded
                [Shapy]=Shapy
                [Sinfonia]=Sinfonia
                [Spark]=Spark
                [Stony]=Stony
                [Supernova]=Supernova
                [Whirl]=Whirl
                [WhirlBlack]=WhirlBlack
                [Whirless]=Whirless
                [WhitArt]=WhitArt
                [Whity]=Whity
            )

            for src_theme in "${!themes[@]}"; do
                src="$HOME/Thèmes/$src_theme/app/src/main"
                dest="$HOME/AndroidAll/Thèmes_Shorts/${themes[$src_theme]}"
                ln -s "$src" "$dest"
            done
        fi

        # Android Studio
        path_install="/usr/local/android-studio"

        if [[ ! -d "$path_install" ]]; then
            msg_bold_blue "➜ Installation Android Studio"
            printf "\n- - Test de la connexion au site\n"

            url="https://developer.android.com/studio?hl=fr"

            # Effectuer la requête HTTPS avec curl
            response=$(curl -sS -o /dev/null -w "%{http_code}" "$url")
            # -s pour mode silencieux
            # -S pour afficher les erreurs
            # -o /dev/null pour rediriger la sortie vers null
            # -w "%{http_code}" pour récupérer uniquement le code de statut HTTP

            #Contrôler la disponibilité du site
            if [[ $response -ne 200 ]]; then
                echo "${RED}- - Impossible de se connecter au site $url${RESET}"
            else
                # Récupérer le contenu de la page
                page_content=$(curl -s "https://developer.android.com/studio?hl=fr")

                # Extraire l'URL de téléchargement pour Linux
                download_url=$(echo "$page_content" | grep -oP 'https://.*?android-studio-.*?-linux.tar.gz' | head -n 1)

                # Vérifier si l'URL a été trouvée
                if [[ -z "$download_url" ]]; then
                    echo "${RED}- - Impossible de trouver l'URL de téléchargement.${RESET}"
                else
                    # Télécharger le fichier
                    echo "- - Téléchargement : "
                    wget -P $HOME/Tmp -q --show-progress "$download_url"

                    filename=$(basename $(ls -1 $HOME/Tmp/android-studio*))
                    filesize=$(du $HOME/Tmp/$filename | awk '{print $1}')

                    if [[ "$filesize" -lt 1000000 ]]; then
                        echo "${RED}- - Taille du fichier $HOME/Tmp/$filename anormalement basse...${RESET}"
                    else
                        printf "\nInstallation lancée...\n"
                        echo -n "- - Création du dossier final : "
                        sudo mkdir -p $path_install; check_cmd

                        echo -n "- - Décompresssion $filename : "
                        sudo tar -xzf $HOME/Tmp/$filename -C $path_install --strip-components=1; check_cmd

                        echo -n "- - Rendre studio exécutable : "
                        sudo chmod +x $path_install/bin/studio
                        sudo chmod +x $path_install/bin/studio.sh; check_cmd

                        echo -n "- - Suppression du fichier original $filename : "
                        rm -f "$HOME/Tmp/$filename"; check_cmd
                        echo -n "- - Changement du propriétaire et du groupe : "
                        sudo chown -R $USER:$USER $path_install; check_cmd

                        echo "${GREEN}${BOLD}Installation terminée.${RESET}"
                        echo "Prêt pour ajouter le raccourci $path_install/bin/studio"
                        echo "Lancer Android Studio pour télécharger le SDK dans $HOME/Android/Sdk" | tee -a $HOME/Tmp/post_installation.txt
                        ask_continue
                    fi
                fi
            fi
        fi #Fin Android Studio

        #Actions manuelles
        echo
        msg_bold_yellow "*******************"
        msg_bold_yellow "Actions manuelles"
        msg_bold_yellow "*******************"
        if [[ ! -d $HOME/.local/share/plasma/look-and-feel/Colorful-Dark-Global-6/ ]]; then
            if [[ ! -d .local/share/plasma/desktoptheme/Colorful-Dark-Plasma ]]; then
                echo "➜ Installer le thème ${BOLD}Colorful-Dark-Global-6${RESET}" | tee -a $HOME/Tmp/post_installation.txt
            fi
        fi

        printf "\n- Configurer TIMESHIFT\n- Refaire la synchro Synchthing avec le téléphone et Windows\n- Webdav Dolphin Zaclys" >> $HOME/Tmp/post_installation.txt

    fi #Fin si NON VM

elif [ "$install_type" = 2 ]; then
    msg_bold_blue "➜ Paquets PACMAN supplémentaires LITE"
    while read -r line; do
        if [[ "$line" == add_lite:* ]]; then
            p=${line#add_lite:}
            if ! check_pkg "$p"; then
                echo -n "$sign_green $p : "
                add_pkg_pacman "$p"; check_pacman_status_install
            fi
        fi
        if [[ "$line" == del_lite:* ]]; then
            p=${line#del_lite:}
            if check_pkg "$p"; then
                echo -n "$sign_red $p : "
                del_pkg_pacman "$p"; check_pacman_status_uninstall
            fi
        fi
    done < "packages/pacman.list"
fi
#--------------------------------------
# [FIN] VERSION COMPLÈTE OU LITE
#--------------------------------------

if [[ -f $HOME/Tmp/post_installation.txt ]] && check_pkg neovim ; then nvim $HOME/Tmp/post_installation.txt; fi

msg_bold_green "Installation terminée."

exit 0
