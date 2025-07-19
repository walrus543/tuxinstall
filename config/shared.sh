#!/usr/bin/env bash

#Coloration du texte
RESET=$(tput sgr0)
RESET_ALT="\x1b[0m"
RED=$(tput setaf 1)
RED_ALT="\x1b[38;2;255;18;18m"
GREEN=$(tput setaf 2)
GREEN_ALT="\x1b[38;2;32;226;1m" #RGB : 32, 226, 1
YELLOW=$(tput setaf 3)
YELLOW_ALT="\x1b[38;2;255;212;18m"
BLUE=$(tput setaf 4)
BLUE_ALT="\x1b[38;2;64;129;249m"
BOLD=$(tput bold)
BOLD_ALT="\x1b[1m"
sign_green="${GREEN}${BOLD}[+]${RESET}"
sign_red="${RED}${BOLD}[-]${RESET}"

#Pauses
sleepquick=2
sleepmid=4
sleeplong=6

# Fonctions
msg_bold_yellow() {
    printf "\n${YELLOW_ALT}${BOLD_ALT}$1${RESET_ALT}\n"
}
msg_bold_blue() {
    printf "\n${BLUE_ALT}${BOLD_ALT}$1${RESET_ALT}\n"
}
msg_bold_green() {
    printf "\n${GREEN_ALT}${BOLD_ALT}$1${RESET_ALT}\n"
}
msg_bold_red() {
    printf "\n${RED_ALT}${BOLD_ALT}$1${RESET_ALT}\n"
}
msg_ok_green() {
    printf "${GREEN_ALT}${BOLD_ALT}$1${RESET_ALT}\n"
}
msg_ok_red() {
    printf "${RED_ALT}${BOLD_ALT}$1${RESET_ALT}\n"
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
check_cmd()
{
if [[ $? -eq 0 ]]; then
    msg_ok_green "OK"
else
    msg_ok_red "ERREUR"
fi
}

check_cmd_secure()
{
if [[ $? -eq 0 ]]; then
    msg_ok_green "OK"
else
    msg_ok_red "ERREUR"
    exit 1
fi
}

check_pkg()
{
	pacman -Q "$1" > /dev/null 2>&1
}
