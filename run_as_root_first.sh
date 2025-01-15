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

if [[ $(grep -c "DIFFPROG=/usr/bin/meld" /etc/environment) -lt 1 ]]; then
    path_meld=$(which meld)
    echo -n "- - [Pacdiff] Meld par défaut : "
    echo "DIFFPROG=/usr/bin/meld" >> /etc/environment
    check_cmd
fi

msg_bold_green "Opérations terminées."
echo "Prêt pour lancer le fichier install.sh"
touch $ICI/.root_finished

exit 0
