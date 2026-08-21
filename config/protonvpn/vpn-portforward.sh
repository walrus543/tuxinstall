#!/usr/bin/env bash
#
# vpn-portforward.sh
# 1) Connexion à ProtonVPN (pays FR)
# 2) Boucle de port forwarding (natpmpc)
# 3) Copie du port mappé dans le presse-papier X11 (xclip)
#
# Dépendances : proton-vpn-cli (officiel, https://github.com/ProtonVPN/proton-vpn-cli),
#               natpmpc, xclip, iputils (ping), (optionnel) notify-send, xfce4-terminal
#
# Installation des dépendances si besoin :
#   sudo pacman -S xclip libnatpmp iputils
#   (xfce4-terminal et libnotify sont normalement déjà présents sous Xfce)
#
# Note : proton-vpn-cli (officiel) n'a pas de commande "status" fiable pour
# l'instant. On vérifie donc la connectivité directement via un ping sur la
# passerelle NAT-PMP plutôt que de sonder l'état du client VPN.

set -uo pipefail

# --- Configuration ---------------------------------------------------------
GATEWAY="10.2.0.1"
NATPMPC_INTERVAL=45          # secondes entre 2 renouvellements du mapping
INITIAL_WAIT=5              # pause fixe après "connect" avant de commencer à tester le tunnel
MAX_WAIT_ATTEMPTS=20         # nombre de tentatives de vérification de connectivité
WAIT_INTERVAL=3              # secondes entre 2 tentatives (soit jusqu'à 10 + 20*3 = 70s max)
LOGDIR="$HOME/.local/share/vpn-portforward"
LOGFILE="$LOGDIR/vpn-portforward.log"
mkdir -p "$LOGDIR"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $*" | tee -a "$LOGFILE"
}

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "VPN Port Forwarding" "$1" "$2"
    fi
}

# --- 0a) Vérification de l'installation de proton-vpn-cli ------------------
check_package_installed() {
    if pacman -Qq proton-vpn-cli >/dev/null 2>&1; then
        log "Paquet proton-vpn-cli déjà installé."
        return 0
    fi

    log "Le paquet proton-vpn-cli n'est pas installé."

    if [[ ! -t 0 ]]; then
        # Pas de terminal interactif (ex: lancé automatiquement au démarrage) :
        # impossible de demander confirmation, on abandonne proprement.
        log "Aucun terminal interactif disponible pour demander confirmation. Abandon."
        notify "proton-vpn-cli manquant" "Paquet non installé, script arrêté (pas de terminal interactif)."
        exit 1
    fi

    read -r -p "proton-vpn-cli n'est pas installé. L'installer maintenant avec 'paru -Syu proton-vpn-cli' ? [o/N] " reponse
    case "$reponse" in
        [oO]|[oO][uU][iI])
            log "Installation de proton-vpn-cli via paru..."
            if paru -Syu proton-vpn-cli; then
                log "proton-vpn-cli installé avec succès."
            else
                log "Échec de l'installation de proton-vpn-cli. Abandon."
                notify "Échec installation" "L'installation de proton-vpn-cli a échoué."
                exit 1
            fi
            ;;
        *)
            log "Installation refusée par l'utilisateur. Abandon."
            exit 1
            ;;
    esac
}

# --- 0b) Vérification de la connexion au compte ProtonVPN ------------------
check_account_logged_in() {
    local info
    info="$(protonvpn info 2>&1)"

    if echo "$info" | grep -q "Account: 'None'"; then
        log "Aucun compte ProtonVPN connecté (Account: 'None')."
        notify "ProtonVPN non connecté" "Veuillez vous connecter avec 'protonvpn login' avant de relancer ce script."
        exit 1
    fi

    log "Compte ProtonVPN connecté."
}

check_package_installed
check_account_logged_in

# --- 0c) Activation du port forwarding côté compte/CLI ----------------------
# Sur le CLI Linux, l'activation du port forwarding est un réglage à part,
# séparé de la connexion : sans lui, natpmpc échoue avec "the gateway does
# not support nat-pmp" (errno=111), même sur un serveur qui le supporte.
# Idempotent : sans effet si déjà activé.
log "Activation du port forwarding (protonvpn config set port-forwarding on)..."
protonvpn config set port-forwarding on 2>&1 | tee -a "$LOGFILE"

# --- 1) Connexion VPN --------------------------------------------------
# La sortie de "connect" est à la fois affichée dans le terminal et loguée,
# pour vérifier au premier coup d'œil que la connexion se passe bien.
log "=== Connexion à ProtonVPN (FR, serveur P2P) ==="
# --p2p est indispensable : le port forwarding ne fonctionne que sur les
# serveurs P2P, sinon natpmpc échoue avec "the gateway does not support
# nat-pmp" même avec le port forwarding activé côté compte.
protonvpn connect --country FR --p2p 2>&1 | tee -a "$LOGFILE"

# --- Attente active du tunnel -------------------------------------------
# proton-vpn-cli (officiel) n'expose pas de commande "status" fiable, donc on
# vérifie directement ce qui nous intéresse : la passerelle NAT-PMP doit
# répondre avant de lancer natpmpc. PC ancien -> on patiente au besoin.
log "Attente initiale de ${INITIAL_WAIT}s avant de tester le tunnel..."
sleep "$INITIAL_WAIT"

log "Vérification de la disponibilité de la passerelle NAT-PMP ($GATEWAY)..."
connected=false
for ((i = 1; i <= MAX_WAIT_ATTEMPTS; i++)); do
    if ping -c 1 -W 2 "$GATEWAY" >/dev/null 2>&1; then
        connected=true
        log "Passerelle joignable (tentative $i/$MAX_WAIT_ATTEMPTS)."
        break
    fi
    log "Tentative $i/$MAX_WAIT_ATTEMPTS : passerelle injoignable, nouvel essai dans ${WAIT_INTERVAL}s..."
    sleep "$WAIT_INTERVAL"
done

if ! $connected; then
    log "Passerelle VPN injoignable après ${INITIAL_WAIT}s + $((MAX_WAIT_ATTEMPTS * WAIT_INTERVAL))s. Abandon."
    notify "Échec VPN" "Impossible de joindre la passerelle NAT-PMP, script arrêté."
    exit 1
fi

log "=== Démarrage de la boucle de port forwarding ==="
notify "VPN connecté" "Démarrage du port forwarding..."

# --- 2) Boucle natpmpc + 3) extraction et copie du port --------------------
# On utilise stdbuf pour désactiver le buffering et traiter chaque ligne
# dès qu'elle est produite (important car natpmpc tourne dans une boucle).
{
    while true; do
        date
        natpmpc -a 1 0 udp 60 -g "$GATEWAY" && natpmpc -a 1 0 tcp 60 -g "$GATEWAY" \
            || { echo -e "ERROR with natpmpc command \a"; break; }
        sleep "$NATPMPC_INTERVAL"
    done
} | stdbuf -oL cat | {
    port_copied=false
    while IFS= read -r line; do
        echo "$line" >> "$LOGFILE"

        if [[ "$line" =~ Mapped\ public\ port\ ([0-9]+) ]]; then
            port="${BASH_REMATCH[1]}"
            if ! $port_copied; then
                printf '%s' "$port" | xclip -selection clipboard
                log "Port mappé : $port (copié dans le presse-papier)"
                notify "Port forwarding actif" "Port public : $port (copié)"
                port_copied=true
            else
                # Le port ne change pas d'un renouvellement à l'autre : on
                # se contente de logguer la confirmation, sans re-copier
                # ni renotifier à chaque itération de la boucle (45s).
                log "Port toujours mappé : $port (déjà copié, pas de nouvelle copie)"
            fi
        fi

        if [[ "$line" == *"ERROR with natpmpc command"* ]]; then
            log "Erreur natpmpc, arrêt du script."
            notify "Erreur port forwarding" "La boucle natpmpc s'est arrêtée."
        fi
    done
}