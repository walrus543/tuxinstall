#!/usr/bin/env bash

source "$HOME/Documents/Linux/Divers_Scripts/shared.sh"

msg_bold_blue "MISE À JOUR PACMAN & AUR..."
    paru

if [ -n "$(flatpak list)" ]; then
    msg_bold_blue "MISE À JOUR FLATPAK..."
    flatpak update -y
fi

msg_bold_blue "NETTOYAGE DES DÉPENDANCES..."
paru -c

msg_bold_blue "MISE À JOUR POWERLEVEL10K..."
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull 

