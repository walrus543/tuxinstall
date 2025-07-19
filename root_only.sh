#!/usr/bin/env bash

#################
### VARIABLES ###
#################
mkdir -p "$HOME/Tmp"
log_file="$HOME/Tmp/config-arch.log"
DE=$(echo $XDG_CURRENT_DESKTOP)
VM=$(systemd-detect-virt)
ICI=$(dirname "$0")

#Coloration du texte
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)

#################
### FONCTIONS ###
#################
check_pkg()
{
	pacman -Q "$1" > /dev/null 2>&1
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

msg_bold_blue() {
    printf "\n${BLUE}${BOLD}$1${RESET}\n"
}
msg_bold_green() {
    printf "\n${GREEN}${BOLD}$1${RESET}\n"
}
msg_bold_yellow() {
    printf "\n${YELLOW}${BOLD}$1${RESET}\n"
}
msg_bold_red() {
    printf "\n${RED}${BOLD}$1${RESET}\n"
}

#####################
### FIN FONCTIONS ###
#####################


#####################
### Contrôles de base
#####################

if [[ -z "$1" ]] # le premier argument est vide (./install.sh sans rien derrière)
    then
	echo "OK" > /dev/null
else
	echo "Usage incorrect du script"
	echo "Ne mettre aucun argument"
	exit 1;
fi

###################
#### Arch Only ####
###################
# Tester si bien une base Arch
if ! check_pkg pacman; then
	msg_bold_red "Le paquet \"pacman\" n'est pas installé donc cette distribution n'est probablement pas être basée sur Arch :-("
	exit 1;
fi

###################
# GÉNÉRALITÉS
###################
# Tester si root
if [[ $(id -u) -ne "0" ]]; then
    msg_bold_red "Lancer le script avec les droits root (sudo)"
	exit 1;
fi

###################
# EXÉCUTION
###################
msg_bold_blue "➜ Paramétrages accès root"
if [[ -f /etc/sudoers.d/00_$SUDO_USER ]] && [[ $(grep -c "passwd_timeout" /etc/sudoers.d/00_$SUDO_USER) -lt 1 ]] ; then
    echo -n "- - [Sudoers] Délai saisie mot de passe : "
    echo "Defaults passwd_timeout=0" >> /etc/sudoers.d/00_$SUDO_USER
    check_cmd
fi
    
pacman -S --needed --noconfirm meld > /dev/null 2>&1
if [[ $(grep -c "DIFFPROG=/usr/bin/meld" /etc/environment) -lt 1 ]]; then
    path_meld=$(which meld)
    echo -n "- - [Pacdiff] Meld par défaut : "
    echo "DIFFPROG=/usr/bin/meld" >> /etc/environment
    check_cmd
fi


#++++++++++++++++++++++++++++++++++++++
# [DEBUT] CHOIX COMPLÈTE OU LITE
#++++++++++++++++++++++++++++++++++++++
msg_bold_yellow "********************************\nInstallation complète ou lite ?\n********************************"

choix=""
install_type=""

while [ "$choix" != "1" ] && [ "$choix" != "2" ]; do

    echo "1) Complète"
    echo "2) Lite"
    echo
    read -p "Entrez votre choix (1 ou 2) : " choix

    if [ "$choix" = "1" ]; then
        install_type=1
    elif [ "$choix" = "2" ]; then
        install_type=2
    else
        msg_bold_red "Choix invalide."
        echo
        install_type=""
    fi
done

echo "$install_type" > "$ICI/type_install.txt"

#--------------------------------------
# [FIN] CHOIX COMPLÈTE OU LITE
#--------------------------------------

if [ "$install_type" = 1 ]; then
    msg_bold_blue "➜ Pare-Feu UFW"
    pacman -S --needed --noconfirm ufw > /dev/null 2>&1

    if check_pkg ufw && [[ $(ufw status | grep -c inactive) -eq 1 ]]; then
        echo -n " - - Paramétrage des règles : "
        echo y | ufw reset >> "$log_file" 2>&1 # y pour supprimer les règles existantes - sortie standard
        ufw default deny incoming >> "$log_file" 2>&1
        ufw default allow outgoing >> "$log_file" 2>&1
        ufw allow to 192.168.1.0/24 >> "$log_file" 2>&1
        ufw allow from 192.168.1.0/24 >> "$log_file" 2>&1
        ufw deny 22  >> "$log_file" 2>&1 # SSH - uniquement local autorisé
        ufw enable >> "$log_file" 2>&1
        systemctl enable --now ufw.service >> "$log_file" 2>&1
        check_cmd

    #    if [[ $(grep -c 'IPV6=no' /etc/default/ufw) -lt 1 ]]; then
    #        echo -n "- - Désactivation IPV6 : "
    #        sed -i sed -i 's/^IPV6=.*/IPV6=no/' /etc/default/ufw
    #        check_cmd
    #	ufw reload
    #    fi

        if [[ $(grep -c 'DEFAULT_FORWARD_POLICY=ACCEPT' /etc/default/ufw) -lt 1 ]]; then
            echo -n "- - Autoriser la police de transfert (VPN...) : "
            sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY=ACCEPT/' /etc/default/ufw
            check_cmd
        fi

        ufw reload
    fi
fi

msg_bold_green "Opérations terminées."
echo "Prêt pour lancer le fichier install.sh"

exit 0
