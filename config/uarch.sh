#!/usr/bin/env bash

source "$HOME"/Documents/Linux/Divers_Scripts/shared.sh

msg_bold_blue "➜ MISE À JOUR PACMAN & AUR..."
    paru

if [ -n "$(flatpak list)" ]; then
    msg_bold_blue "➜ MISE À JOUR FLATPAK..."
    flatpak update -y
fi

msg_bold_blue "➜ NETTOYAGE DES DÉPENDANCES..."
paru -c

msg_bold_blue "➜ MISE À JOUR POWERLEVEL10K..."
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull 

if check_pkg rust; then # rust et donc cargo installé
    if [[ -n $(cargo install --list) ]]; then # des binaires sont installés
        if [[ -f "$HOME"/.cargo/bin/cargo-install-update ]]; then #Cargo installé
            if [[ $(cargo install-update -al | awk '{print $4}' | grep 'yes') -gt 0 ]]; then #MaJ disponibles
                msg_bold_blue "➜ MISE À JOUR CARGO/RUST PACKAGES..."
                cargo install-update -a
            fi
        else
            msg_bold_blue "➜ INSTALLATION DE CARGO-UPDATE"
            cargo install cargo-update
        fi
    fi
fi

msg_bold_blue "➜ MISE À JOUR rtl8821ce..."
if [[ -d ~/Tmp/rtl8821ce ]]; then
    REPO_DIR="$HOME/Tmp/rtl8821ce"
    LOG_FILE="$HOME/Tmp/rtl8821ce.txt"

    git -C "$REPO_DIR" pull > "$LOG_FILE" 2>&1

    if grep -q "Déjà à jour." "$LOG_FILE"; then
        echo "Déjà à jour."
    else
        msg_bold_yellow "[INFO] Nouveaux changements détectés, recompilation du module..."
        cd "$REPO_DIR" || { msg_bol_read "Erreur : impossible d'accéder à $REPO_DIR"; exit 1; }

        sudo ./dkms-remove.sh
        git pull
        make clean
        sudo ./dkms-install.sh
    fi
    rm -f "$LOG_FILE"
else
    msg_bold_yellow "Dossier de travail non trouvé..."
fi
