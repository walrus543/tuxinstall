#!/usr/bin/env bash

###############################################################################
# variables.sh — Variables globales et fonctions utilitaires pour post-install #
###############################################################################

# Variables
log_file="$HOME/Tmp/config-arch.log"
DE="${XDG_CURRENT_DESKTOP:-}" # Possible de mettre une valeur par défaut après :- si la variable est vide (expansion paramétrique Bash)
VM="$(systemd-detect-virt)"
ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Coloration du texte
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
sign_green="${GREEN}${BOLD}[+]${RESET}"
sign_red="${RED}${BOLD}[-]${RESET}"

# Pauses
sleepquick=2
sleepmid=4
sleeplong=6

# Fonctions
check_pkg() { pacman -Q "$1" &>/dev/null; }

check_pacman_status_install() { if check_pkg "$p"; then echo "${BOLD}${GREEN}OK${RESET}"; else echo "${BOLD}${RED}KO${RESET}"; fi; }
check_pacman_status_uninstall() { if ! check_pkg "$p"; then echo "${BOLD}${GREEN}OK${RESET}"; else echo "${BOLD}${RED}KO${RESET}"; fi; }
add_pkg_pacman() { if pacman -Si "$1" &>/dev/null; then sudo pacman -S --needed --noconfirm "$1" >> "$log_file" 2>&1; else echo "${RED}*** Inexistant ***${RESET}"; pacman_status='false'; fi; }
del_pkg_pacman() { sudo pacman -Rs --noconfirm "$1" >> "$log_file" 2>&1; }

add_pkg_paru() { paru -S --needed --noconfirm "$1" >> "$log_file" 2>&1; }
del_pkg_paru() { paru -Rs --noconfirm "$1" >> "$log_file" 2>&1; }

check_flatpak() { flatpak info "$1" &>/dev/null; }
add_flatpak() { flatpak install flathub --noninteractive -y "$1" >> "$log_file" 2>&1; }
del_flatpak() { flatpak uninstall --noninteractive -y "$1" >> "$log_file" 2>&1 && flatpak uninstall --unused --noninteractive -y >> "$log_file" 2>&1; }
check_flatpak_status_install() { if flatpak info "$p" &>/dev/null; then echo "${BOLD}${GREEN}OK${RESET}"; else echo "${BOLD}${RED}KO${RESET}"; fi; }
check_flatpak_status_uninstall() { if flatpak info "$p" &>/dev/null; then echo "${BOLD}${RED}KO${RESET}"; else echo "${BOLD}${GREEN}OK${RESET}"; fi; }

check_cmd() {
    if [[ "${pacman_status:-true}" != 'false' ]]; then
        if [[ $? -eq 0 ]]; then echo "${GREEN}OK${RESET}"; else echo "${RED}ERREUR${RESET}"; fi
    fi
    pacman_status=''
}

check_systemd() { systemctl is-enabled "$1"; }
check_systemd_user() { systemctl --user is-enabled "$1"; }

# Affichage
msg_bold_blue() { printf "\n${BLUE}${BOLD}%s${RESET}\n" "$1"; }
msg_bold_green() { printf "\n${GREEN}${BOLD}%s${RESET}\n" "$1"; }
msg_bold_yellow() { printf "\n${YELLOW}${BOLD}%s${RESET}\n" "$1"; }
msg_bold_red() { printf "\n${RED}${BOLD}%s${RESET}\n" "$1"; }

# Attente utilisateur
ask_continue() {
    while true; do
        read -p "On continue ? (Y/n) : " rep
        case ${rep:0:1} in
            [Nn]*) echo "Script arrêté."; exit 1;;
            ""|[Yy]*) return 0;;
            *) echo "Veuillez répondre par 'Y' ou 'N'.";;
        esac
    done
}
