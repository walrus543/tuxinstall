#!/usr/bin/env bash

source /home/arnaud/Documents/Linux/Divers_Scripts/shared.sh

msg_bold_blue "MISE À JOUR PACMAN & AUR..."
    paru

if [ -n "$(flatpak list)" ]; then
    msg_bold_blue "MISE À JOUR FLATPAK..."
    flatpak update -y
fi

if [[ "$(paru -c | grep -c 'rien à faire')" -lt 1 ]]; then
    msg_bold_red "NETTOYAGE DES DÉPENDANCES..."
    paru -c
fi

if [[ "$(git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull | grep -c 'à jour')" -lt 1 ]]; then
    msg_bold_blue "MISE À JOUR POWERLEVEL10K..."
fi

