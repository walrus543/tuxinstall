#!/usr/bin/env bash

source "$HOME/Documents/Linux/Divers_Scripts/shared.sh"

hd_name='Seagate_DDE'

###############
# FONCTIONS
###############
check_cmd()
{
if [[ $? -eq 0 ]]
then
    echo ${GREEN}"OK"${RESET}
else
    echo ${RED}"ERREUR"${RESET}
fi
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

# Fonction pour afficher le menu
afficher_menu() {
    msg_bold_blue "--- MENU --"
    echo "1. Lister les sauvegardes"
    echo "2. Monter une sauvegarde"
    echo "3. Démonter le dossier temporaire de la sauvegarde"
	echo "q. Quitter"
    echo
    echo -n "${BOLD}➜ Entrez votre choix : ${RESET}"
}

# Fonction pour exécuter l'action choisie
executer_action() {
    case $1 in
        1)
            echo "Voici la liste des sauvegardes"
            borg list $path_borg
            return 1
            ;;
        2)
            echo -n "Nom de l'archive à monter : "
            read -r archivename

            echo "Création d'un dossier de montage temporaire"
            rm -rf /tmp/$hd_name/ #On supprime le reliquat des précédentes fois

            mkdir -p "/tmp/$hd_name"
                if [[ $? -ne 0 ]]
                then
                    msg_bold_red "Échec lors de la création du dossier temporaire"
                    exit 1;
                fi
            borg mount "$path_borg"::"$archivename" /tmp/"$hd_name"
            echo "Dossier /tmp/$hd_name prêt."
            msg_bold_yellow "Penser à le démonter une fois terminé !"
            sleep 2s
            if [[ $(pacman -Q dolphin 2>/dev/null) ]]; then
                dolphin /tmp/"$hd_name" &
            elif [[ $(pacman -Q thunar 2>/dev/null) ]]; then
                thunar /tmp/"$hd_name" &
            fi
            return 1
            ;;
        3)
            printf "\nDémontage de /tmp/$hd_name : "
            umount /tmp/$hd_name
            check_cmd
            rm -rf /tmp/"$hd_name"
            return 1
            ;;
        q)
            return 0
            ;;
        *)
            echo "Choix incorrect. Veuillez essayer à nouveau."
            echo
            return 1
            ;;
    esac
    return 0
}

#######################
# Borg installé ?
#######################
if [[ ! $(pacman -Q borg 2>/dev/null) ]]
then
    sudo pacman -S borg --needed --noconfirm
    echo
fi

#######################
# Choix du répertoire manuel
#######################
msg_bold_yellow "Utilisation de borg avec sélection manuelle du répertoire"
echo
ask_continue

while true; do
    read -p "Emplacement exact du répertoire borg (ex : /home/user/Documents/${BOLD}borg${RESET}) : " path_borg

    if [ -d "$path_borg" ]; then
        break
    else
        msg_bold_yellow "Le dossier n'existe pas. Veuillez réessayer."
    fi
done

#######################
# Exécution du menu
#######################
while true; do
    afficher_menu
    read -r choix
    echo
    executer_action "$choix"
    if [ $? -eq 0 ]; then
        break
    fi
done
