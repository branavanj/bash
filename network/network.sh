#!/bin/bash

# Couleurs pour le formatage
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour obtenir les informations réseau
get_network_info() {
    echo -e "${BLUE}Interface réseau${NC}: $1"
    ip addr show $1 | awk '/inet /{print "  Adresse IP: " $2}'
    ip route | grep default | grep $1 | awk '{print "  Passerelle: " $3}'
    cat /etc/resolv.conf | grep nameserver | awk '{print "  Serveur DNS: " $2}'
}

# Fonction pour vérifier la connectivité à Internet
check_connectivity() {
    echo -e "${BLUE}Vérification de la connectivité${NC}:"
    ping -c 1 8.8.8.8 &> /dev/null
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}Connecté à Internet${NC}"
    else
        echo -e "  ${RED}Pas de connexion à Internet${NC}"
    fi
}

# Fonction principale
main() {
    interfaces=$(ip -o link show | awk -F': ' '{print $2}')
    for interface in $interfaces; do
        get_network_info $interface
        echo
    done
    check_connectivity
}

# Exécution de la fonction principale
main
