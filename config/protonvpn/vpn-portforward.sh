#!/usr/bin/env bash
#
# vpn-portforward.sh
# 1) Connexion à ProtonVPN (pays FR)
# 2) Boucle de port forwarding (natpmpc)
# 3) Copie du port mappé dans le presse-papier X11 (xclip)
# 4) Démarre les conteneurs Docker dépendants du VPN, les arrête à la sortie
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
DOCKER_STACKS=(prowlarr radarr cross_seed)
mkdir -p "$LOGDIR"
rm -f "$LOGFILE"   # pas d'historique conservé : on repart d'un log vide à chaque lancement

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $*" | tee -a "$LOGFILE"
}

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "VPN Port Forwarding" "$1" "$2"
    fi
}

start_docker_stacks() {
    log "Démarrage des conteneurs dépendants du VPN (${DOCKER_STACKS[*]})..."
    for stack in "${DOCKER_STACKS[@]}"; do
        (cd ~/docker/"$stack" && docker compose up -d) 2>&1 | tee -a "$LOGFILE"
    done
}

stop_docker_stacks() {
    log "Arrêt des conteneurs dépendants du VPN (${DOCKER_STACKS[*]})..."
    for stack in "${DOCKER_STACKS[@]}"; do
        (cd ~/docker/"$stack" && docker compose stop) 2>&1 | tee -a "$LOGFILE"
    done
}

# Hook de déconnexion : s'exécute que le script se termine proprement
# (Ctrl+C, kill, fermeture du terminal) ou après une erreur natpmpc.
cleanup() {
    log "=== Arrêt du script : nettoyage ==="
    stop_docker_stacks
    notify "VPN déconnecté" "Conteneurs arrêtés."
}
trap cleanup EXIT INT TERM

# --- 0a) Vérification de l'installation de proton-vpn-cli ------------------
check_package_installed() {
    if pacman -Qq proton-vpn-cli >/dev/null 2>&1; then
        log "Paquet proton-vpn-cli déjà installé."
        return 0
    fi

    log "Le paquet proton-vpn-cli n'est pas installé."

    if [[ ! -t 0 ]]; then
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
        notify "ProtonVPN non connecté" "Veuillez vous connecter avec 'protonvpn signin' avant de relancer ce script."
        exit 1
    fi

    log "Compte ProtonVPN connecté."
}

check_package_installed
check_account_logged_in

# --- 0c) Activation du port forwarding côté compte/CLI ----------------------
log "Activation du port forwarding (protonvpn config set port-forwarding on)..."
protonvpn config set port-forwarding on 2>&1 | tee -a "$LOGFILE"

# --- 1) Connexion VPN --------------------------------------------------
log "=== Connexion à ProtonVPN (FR, serveur P2P) ==="
protonvpn connect --country FR --p2p 2>&1 | tee -a "$LOGFILE"

# --- Attente active du tunnel -------------------------------------------
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

log "=== Tunnel VPN confirmé ==="
notify "VPN connecté" "Démarrage des conteneurs et du port forwarding..."

# Le tunnel est confirmé actif : on démarre les conteneurs AVANT d'entrer
# dans la boucle infinie de renouvellement du port (sinon ce code ne
# s'exécuterait jamais).
start_docker_stacks

log "=== Démarrage de la boucle de port forwarding ==="

# --- 2) Boucle natpmpc + 3) extraction et copie du port --------------------
last_port=""
while true; do
    out_udp="$(natpmpc -a 1 0 udp 60 -g "$GATEWAY" 2>&1)"
    rc_udp=$?
    echo "$out_udp" >> "$LOGFILE"

    out_tcp=""
    rc_tcp=1
    if [[ $rc_udp -eq 0 ]]; then
        out_tcp="$(natpmpc -a 1 0 tcp 60 -g "$GATEWAY" 2>&1)"
        rc_tcp=$?
        echo "$out_tcp" >> "$LOGFILE"
    fi

    if [[ $rc_udp -ne 0 || $rc_tcp -ne 0 ]]; then
        log "Erreur natpmpc, arrêt du script."
        notify "Erreur port forwarding" "La boucle natpmpc s'est arrêtée."
        break
    fi

    port="$(grep -oE 'Mapped public port [0-9]+' <<< "$out_udp" | head -1 | grep -oE '[0-9]+')"

    if [[ -n "$port" ]]; then
        if [[ "$port" != "$last_port" ]]; then
            printf '%s' "$port" | xclip -selection clipboard
            log "Port mappé : $port (copié dans le presse-papier)"
            notify "Port forwarding actif" "Port public : $port (copié)"
            last_port="$port"
        fi
    else
        log "Aucun port détecté dans la sortie natpmpc, à surveiller."
    fi

    sleep "$NATPMPC_INTERVAL"
done

# Le trap EXIT (cleanup) se charge d'arrêter les conteneurs ici.
