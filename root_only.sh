#!/usr/bin/env bash

###############################################################################
# root_only.sh — Paramétrages spéciaux à lancer uniquement en root            #
###############################################################################

set -euo pipefail
source variables.sh

###################
# EXÉCUTION
###################
msg_bold_blue "➜ Paramétrages accès root"
if [[ -f /etc/sudoers.d/00_$SUDO_USER ]] && [[ $(grep -c "passwd_timeout=0,pwfeedback" /etc/sudoers.d/00_$SUDO_USER) -lt 1 ]] ; then
    echo -n "- - [Sudoers] Délai de saisie et astérisques du mot de passe : "
    echo "Defaults passwd_timeout=0,pwfeedback" >> /etc/sudoers.d/00_$SUDO_USER
    check_cmd
fi
    
pacman -S --needed --noconfirm meld &> /dev/null

if [[ $(grep -c "DIFFPROG=/usr/bin/meld" /etc/environment) -lt 1 ]]; then
    path_meld=$(command -v meld)
    echo -n "- - [Pacdiff] Meld par défaut : "
    echo "DIFFPROG=\"$path_meld\"" >> /etc/environment; check_cmd
fi

if [[ $(grep -c "SYSTEMD_EDITOR" /etc/environment) -lt 1 ]]; then
    path_neovim=$(command -v meld)
    echo -n "- - [Systemd Editor] Neovim par défaut : "
    echo "SYSTEMD_EDITOR=\"$path_neovim\"" >> /etc/environment; check_cmd
fi

#++++++++++++++++++++++++++++++++++++++
# [DEBUT] CHOIX COMPLÈTE OU LITE
#++++++++++++++++++++++++++++++++++++++
# Choix installation complète ou lite
msg_bold_yellow "********************************"
msg_bold_yellow "Installation complète ou lite ?"
msg_bold_yellow "********************************"

install_type=""
while [[ "$install_type" != "1" && "$install_type" != "2" ]]; do
    echo "1) Complète"
    echo "2) Lite"
    read -rp "Entrez votre choix (1 ou 2) : " install_type
    [[ "$install_type" = "1" || "$install_type" = "2" ]] || {
        msg_bold_red "Choix invalide."
        install_type=""
    }
done
echo "$install_type" > "$ICI/type_install.txt"

if [[ "$install_type" == "1" ]]; then
    msg_bold_blue "➜ Pare-Feu UFW"
    pacman -S --needed --noconfirm ufw &> /dev/null
    if check_pkg ufw && [[ $(ufw status | grep -c inactive) -eq 1 ]]; then
        echo " - - Paramétrage des règles : "
        echo y | ufw reset >> "$log_file" 2>&1
        ufw default deny incoming >> "$log_file" 2>&1
        ufw default allow outgoing >> "$log_file" 2>&1
        ufw allow to 192.168.1.0/24 >> "$log_file" 2>&1
        ufw allow from 192.168.1.0/24 >> "$log_file" 2>&1
        ufw deny 22 >> "$log_file" 2>&1
        ufw enable >> "$log_file" 2>&1
        systemctl enable --now ufw.service >> "$log_file" 2>&1
        check_cmd

        if grep -q '^DEFAULT_FORWARD_POLICY=' /etc/default/ufw; then
            sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY=ACCEPT/' /etc/default/ufw
            check_cmd
        fi
        ufw reload
    fi
fi

msg_bold_green "Opérations terminées."
echo "Prêt pour lancer le fichier install.sh"
