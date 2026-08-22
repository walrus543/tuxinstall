#!/usr/bin/env bash
#
# Fournit :
#   - proton_drive_is_authenticated : teste la session actuelle
#   - proton_drive_ensure_auth      : vérifie, et lance "auth login" si besoin
#
# Le proton-drive CLI ne propose pas de commande "whoami" ou "status" dédiée :
# on détecte l'absence d'authentification via le message qu'il renvoie
# ("You need to login first") lorsqu'on tente une action nécessitant une
# session, ici un listage léger de la racine.

PROTON_DRIVE_BIN="${PROTON_DRIVE_BIN:-proton-drive}"

proton_drive_is_authenticated() {
    local output
    output="$("$PROTON_DRIVE_BIN" filesystem list /my-files 2>&1)"

    if echo "$output" | grep -qi "You need to login first"; then
        return 1
    fi
    return 0
}

proton_drive_ensure_auth() {
    if proton_drive_is_authenticated; then
        return 0
    fi

    echo "Authentification Proton Drive requise, ouverture du navigateur..." >&2
    "$PROTON_DRIVE_BIN" auth login >&2

    if ! proton_drive_is_authenticated; then
        echo "Échec de l'authentification Proton Drive." >&2
        return 1
    fi
}

# Si le fichier est exécuté directement (./pdrive_auth.sh), on lance
# la vérification/authentification tout de suite — pratique pour tester.
# S'il est sourcé (source pdrive_auth.sh), on se contente de définir
# les fonctions ci-dessus, sans rien exécuter.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    proton_drive_ensure_auth
fi
