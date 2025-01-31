#!/usr/bin/env bash

source "$HOME/Documents/Linux/Divers_Scripts/shared.sh"

hd_name='Seagate_DDE'
hd_mounted='/run/media/arnaud/'$hd_name
hd_mounter_folder=$hd_mounted'/borg'
dev_block=$(lsblk -fi | grep Seagate_DDE | awk '{print $1}' | sed 's/.*-//')
today_date=$(date +"%Y%m%d_%H%M")


###################
# CONTRÖLES DE BASE
###################
if [[ $(grep 'This is a Borg Backup repository' $hd_mounted/**/README 2>/dev/null | wc -l ) -gt 1 ]]
then
    msg_bold_red "Il existe plusieurs dossiers racine de sauvegarde BORG"
    echo "Ce script ne fonctionne qu'avec un seul dossier racine BORG, désolé."
    exit 0
fi

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

# Fonction pour afficher le menu
afficher_menu() {
    msg_bold_blue "--- MENU --"
    echo "0. Initialiser un nouveau répertoire de sauvegarde"
    echo "1. Lancer une sauvegarde"
    echo "2. Lister les sauvegardes"
    echo "3. Rechercher un contenu spécifique dans une archive"
    echo "4. Supprimer une sauvegarde"
    echo "5. Ne conserver que les X dernières sauvegardes"
    echo "6. Compresser les sauvegardes"
    echo "7. Monter une sauvegarde"
    echo "8. Démonter le dossier temporaire de la sauvegarde"
    echo "9. Démonter le disque dur"
    echo "10. Faire un contrôle d'intégrité de toutes les sauvegardes"
	echo "11. Supprimer le cache"    
	echo "q. Quitter"
    echo
    echo -n "${BOLD}➜ Entrez votre choix : ${RESET}"
}

# Fonction pour exécuter l'action choisie
executer_action() {
    case $1 in
        0)
            msg_bold_read "Penser à revoir la variable \"hd_mounter_folder\" de ce script après avoir terminé !"
            echo -n "Nom du répertoire à créer : "
            read -r reponame

            read -p ${RED}"➜ Avec chiffrement ? (y/N) "${RESET} -n 1 -r
            if [[ $REPLY =~ ^[Yy]$ ]]
            then
                borg init -e repokey-blake2 "$hd_mounted"/"$reponame"
            else
                borg init -e none "$hd_mounted"/"$reponame"
            fi
            msg_bold_green "Initialisation terminée."
            return 1
            ;;
        1)
            if [[ $(cat /etc/mtab | grep -c "/tmp/Seagate_DDE") -eq 1 ]] #Point de montage trouvé
            then
                echo "Démontage de /tmp/$hd_name pour enlever le lock"
                umount /tmp/$hd_name
                rm -rf /tmp/$hd_name
            fi

            read -p "Nom de l'archive (laisser vide pour la date du jour) ? " answername
            if [ -n "${answername}" ] # si quelque chose a été saisi
                then
                    archivename=${answername}
                else
                    archivename=$(date +"%Y%m%d_%H%M")
            fi
            msg_bold_green "Sauvegarde lancée : $archivename."
            cp ~/.vimrc ~/.zshrc ~/Documents/Linux
			cd || exit # Impératif et le exit permet de sortir si cd ne fonctionne pas !
            if [[ $(pwd | grep -c '/home/') -eq 1 ]]
            then
                borg create --stats -C zstd,10 --progress -e 'Thèmes/*/app/build' $hd_mounter_folder::${archivename} AndroidAll Bureau Documents Images PartageVM Thèmes Vidéos
            fi
			return 1
            ;;
        2)
            echo "Voici la liste des sauvegardes"
            borg list $hd_mounter_folder
            return 1
            ;;
        3)
            echo -n "Que cherches-tu ?"
            read -r lookup
            echo -n "Dans quelle archive ?"
            read -r archivename
            borg list "$hd_mounter_folder"::"$archivename" | grep "$lookup"
            return 1
            ;;
        4)
            echo -n "Nom de la sauvegarde à supprimer : "
            read -r archivename
            borg delete "$hd_mounter_folder::$archivename"
            return 1
            ;;

        5)
            echo -n "Combien de sauvegardes à conserver : "
            read -r number_archives
            borg prune --keep-last "$number_archives" "$hd_mounter_folder"
            return 1
            ;;
        6)
            echo "Compression lancée"
            borg compact --progress "$hd_mounter_folder"
            msg_bold_green "Compression terminée"
            return 1
            ;;
        7)
            echo -n "Nom de l'archive à monter : "
            read -r archivename

            echo "Création d'un dossier de montage temporaire"
            rm -rf /tmp/$hd_name/ #On supprime le reliquat des précédentes fois

            mkdir -p "/tmp/$hd_name"
                if [[ $? -ne 0 ]]
                then
                    echo "${RED}Échec lors de la création du dossier temporaire${RESET}"
                    exit 0;
                fi
            borg mount "$hd_mounter_folder"::"$archivename" /tmp/"$hd_name"
            echo "Dossier /tmp/$hd_name prêt."
            echo "${YELLOW}Penser à le démonter une fois terminé !${RESET}"
            sleep 2s
            if [[ $(pacman -Q dolphin 2>/dev/null) ]]; then
                dolphin /tmp/"$hd_name" &
            elif [[ $(pacman -Q thunar 2>/dev/null) ]]; then
                thunar /tmp/"$hd_name" &
            fi
            return 1
            ;;
        8)
            printf "\nDémontage de /tmp/$hd_name\n"
            umount /tmp/$hd_name
            rm -rf /tmp/"$hd_name"
            return 1
            ;;
        9)
            echo -n "Démontage du disque dur : "
            # Démonter sans sudo en premier
            umount "/dev/$dev_block" > /dev/null 2>&1
            if [[ $? -ne 0 ]]; then
                sudo umount "/dev/$dev_block"
            fi
            check_cmd
            echo
            ;;
        10)
            echo "Contrôle d'intégrité lancé"
            borg check --progress "$hd_mounter_folder"
            return 1
            ;;
        11)
            echo "Suppression du cache."
            borg delete --cache-only $hd_mounter_folder
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
# Montage du disque dur
#######################
if [[ $(lsblk -f | grep -c $hd_mounted) -lt 1 ]]; then # DD pas monté
    if [[ $(lsblk -f | grep -c $hd_name) -eq 1 ]]; then # DD branché/reconnu
        while true; do
            read -p "Monter $hd_name avec sudo ? (Y/n) : " reponse
            case ${reponse:0:1} in
                [Nn]* ) echo "Script arrêté."; exit;;
                "" | [Yy]* ) return 0;;
                * ) echo "Veuillez répondre par 'Y' ou 'N'.";;
            esac
        done

        sudo mkdir -p $hd_mounted
        sudo mount "/dev/$dev_block" $hd_mounted
        echo -n "Montage de $hd_name sur $hd_mounted${RESET} : "
        check_cmd
    else
        echo "Le disque dur externe \"$hd_name\" n'est pas branché, n'est pas reconnu ou a été éjecté."
        echo "Merci de le brancher."
        exit 1;
    fi
fi

echo

#######################
# Borg installé ?
#######################
if [[ ! $(pacman -Q borg 2>/dev/null) ]]
then
    sudo pacman -S borg --needed --noconfirm
    echo
fi

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
