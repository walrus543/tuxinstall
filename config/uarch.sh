#!/usr/bin/env bash

source "$HOME"/Documents/Linux/Divers_Scripts/shared.sh

msg_bold_blue "MISE À JOUR PACMAN & AUR... !"
    paru

if [ -n "$(flatpak list)" ]; then
    msg_bold_blue "MISE À JOUR FLATPAK..."
    flatpak update -y
fi

msg_bold_blue "NETTOYAGE DES DÉPENDANCES..."
paru -c

msg_bold_blue "MISE À JOUR POWERLEVEL10K..."
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull 

if check_pkg rust; then # rust et donc cargo installé
    if [[ -n $(cargo install --list) ]]; then # des binaires sont installés
        if [[ -f "$HOME"/.cargo/bin/cargo-install-update ]]; then #Cargo installé
            if [[ $(cargo install-update -a | awk '{print $4}' | grep 'yes') -gt 0 ]]; then #MaJ disponibles
                msg_bold_blue "MISE À JOUR CARGO/RUST PACKAGES..."
                cargo install-update -a
            fi
        else
            msg_bold_blue "INSTALLATION DE CARGO-UPDATE"
            cargo install cargo-update
        fi
    fi
fi
