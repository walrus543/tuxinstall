#!/usr/bin/env bash

source "$HOME/Documents/Linux/Divers_Scripts/shared.sh"

model='Seagate'
hd_name='Seagate_DDE'
hd_mounted='/run/media/arnaud/'$hd_name
hd_mounter_folder=$hd_mounted'/borg'
dev_block="/dev/$(lsblk -fi | grep "$model" | awk '{print $1}' | sed 's/.*-//')"
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
            msg_bold_red "Penser à revoir la variable \"hd_mounter_folder\" de ce script après avoir terminé !"
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
            # Synchronisation des données
            printf "\n➜ Synchronisation des données...\n"
            sync

            # Vérification si le périphérique est monté et démontage
            if [[ $(mount | grep -c "$dev_block") -eq 1 ]]; then
                echo "➜ Démontage des partitions..."
                udisksctl unmount -b "$dev_block" > /dev/null || { msg_bold_red "Erreur lors du démontage"; exit 1; }
            else
                echo "Le périphérique n'est pas monté."
            fi

            # Demander confirmation pour l'éjection
            echo
            read -p "Éjecter $dev_block ? (Y/n) " response
            if [[ "$response" =~ ^[nN]$ ]]; then
                echo "Le disque n'a pas été éjecté."
            else
                echo "➜ Éjection du disque..."
                udisksctl power-off -b "$dev_block" && msg_bold_green "Disque éjecté avec succès." || msg_bold_red "Erreur lors de l'éjection."
            fi

            echo
            return 0
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
# Contrôle du disque dur
#######################
if [[ $(udisksctl status | grep -c "$model") -lt 1 ]]; then
    msg_bold_red "Disque $model non branché"
    exit 1
elif [[ $(lsblk -f | grep Seagate | grep -c "/run/media") -lt 1 ]]; then
    msg_bold_red "Disque $model non monté"
    echo "Pour rappel, KDE Plasma permet de le faire automatiquement"
    echo "Rechercher \"Montage automatique\" dans les paramètres"
    exit 1
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
