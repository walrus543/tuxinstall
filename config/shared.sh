#!/usr/bin/env bash

#Coloration du texte
RESET=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
BOLD=$(tput bold)
sign_green="${GREEN}${BOLD}[+]${RESET}"
sign_red="${RED}${BOLD}[-]${RESET}"

#Pauses
sleepquick=2
sleepmid=4
sleeplong=6

# Fonctions
msg_bold_blue() {
    printf "\n${BLUE}${BOLD}$1${RESET}\n"
}
msg_bold_green() {
    printf "\n${GREEN}${BOLD}$1${RESET}\n"
}
msg_bold_red() {
    printf "\n${RED}${BOLD}$1${RESET}\n"
}

ask_continue() {
    while true; do
        read -p "On continue ? (Y/n) : " reponse
        case ${reponse:0:1} in
            [Nn]* ) echo "Script arrêté."; exit;;
            "" | [Yy]* ) return 0;;
            * ) echo "Veuillez répondre par 'Y' ou 'N'.";;
        esac
    done
}
