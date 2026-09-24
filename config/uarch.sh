#!/usr/bin/env bash

set -uo pipefail

source "$HOME/Documents/Linux/Divers_Scripts/shared.sh"
source "$HOME/Documents/Linux/Divers_Scripts/pdrive_auth.sh"

msg_bold_blue "➜ MISE À JOUR PACMAN & AUR..."
    paru

if [ -n "$(flatpak list)" ]; then
    msg_bold_blue "➜ MISE À JOUR FLATPAK..."
    flatpak update -y
fi

msg_bold_blue "➜ NETTOYAGE DES DÉPENDANCES ET DU CACHE..."
paru -c
#paru -Sc # faire -Scc pour ajouter le cache des paquets installés

msg_bold_blue "➜ NETTOYAGE DU CACHES DES ANCIENS PAQUETS..."
paccache -rk2

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

# >>>>>>>>>
# DOCKER
# >>>>>>>>>
if [[ $(grep -c 'ideapad 320' /sys/devices/virtual/dmi/id/product_version) -eq 1 ]]; then
    msg_bold_blue "➜ DOCKER"
    msg_bold "Sauvegarde des services Docker et qBittorrent..."

    BACKUP_DIR="$HOME/docker/backups/"
    SOURCE_DIRS=(
        "$HOME/docker/freshrss"
        "$HOME/.cross-seed"
        "$HOME/.prowlarr"
        "$HOME/.apprise"
        "$HOME/.diun"
        "$HOME/.ntfy"
        "$HOME/.radarr"
        "$HOME/.scripts"
        "$HOME/.config/qBittorrent"
    )
    COMPOSE_FILES=(
    "$HOME/docker/docker-compose.yml"
    "$HOME/docker/cross_seed/docker-compose.yml"
    "$HOME/docker/prowlarr/docker-compose.yml"
    "$HOME/docker/apprise/docker-compose.yml"
    "$HOME/docker/radarr/docker-compose.yml"
    "$HOME/docker/diun/docker-compose.yml"
    "$HOME/docker/ntfy/docker-compose.yml"
    )
    CONTAINERS_TO_STOP=(freshrss cross-seed diun ntfy radarr)

    mkdir -p "$BACKUP_DIR"
    rm -rf "$BACKUP_DIR"/*

    for c in "${CONTAINERS_TO_STOP[@]}"; do
        docker stop "$c" &> /dev/null
    done

    STAGING="$(mktemp -d)"
    mkdir -p "$STAGING/compose"
    for f in "${COMPOSE_FILES[@]}"; do
        [[ -f "$f" ]] && cp --parents "$f" "$STAGING/compose/" 2>/dev/null
    done

    sudo tar -czf "$BACKUP_DIR/docker-backup.tar.gz" \
        -C "$STAGING" compose \
        "${SOURCE_DIRS[@]}"

    rm -rf "$STAGING"

    for c in "${CONTAINERS_TO_STOP[@]}"; do
        docker start "$c" &> /dev/null
    done

    echo "Sauvegarde terminée, envoi vers Proton Drive..."

    PROTON_DRIVE_BIN="${PROTON_DRIVE_BIN:-proton-drive}"
    REMOTE_DIR="/my-files/Backup/docker"

    FILES=(
        "$BACKUP_DIR/docker-backup.tar.gz"
    )

    upload_overwrite() {
        local local_file="$1"
        local remote_dir="$2"
        local filename remote_path

        filename="$(basename "$local_file")"
        remote_path="${remote_dir%/}/$filename"

        "$PROTON_DRIVE_BIN" filesystem trash "$remote_path" >/dev/null 2>&1

        if "$PROTON_DRIVE_BIN" filesystem upload "$local_file" "$remote_dir" >/dev/null 2>&1; then
            echo "OK      : $filename"
        else
            msg_bold_red "ERREUR  : échec de l'upload de $filename"
        fi
    }

    proton_drive_ensure_auth || exit 1

    for f in "${FILES[@]}"; do
        if [[ -f "$f" ]]; then
            upload_overwrite "$f" "$REMOTE_DIR"
        else
            msg_bold_yellow "ABSENT  : $f"
        fi
    done
fi
# <<<<<<<<<
# DOCKER
# <<<<<<<<<
