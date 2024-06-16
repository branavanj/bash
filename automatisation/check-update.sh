#!/bin/bash

# Fonction pour détecter l'OS
detect_os() {
    if [ -f /etc/os-release ]; then
        # LSB distribution information
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        OS=$(cat /etc/redhat-release | awk '{print tolower($1)}')
        VERSION=$(cat /etc/redhat-release | awk '{print $3}')
    else
        echo "Système d'exploitation non supporté."
        exit 1
    fi
}

# Fonction pour mettre à jour le système
update_system() {
    echo "[$(date)] Mise à jour du système pour $OS $VERSION..."

    case "$OS" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get upgrade -y
            sudo apt-get dist-upgrade -y
            sudo apt-get autoremove -y
            sudo apt-get clean
            ;;
        fedora)
            sudo dnf update -y
            sudo dnf upgrade -y
            sudo dnf autoremove -y
            sudo dnf clean all
            ;;
        centos|rhel)
            sudo yum update -y
            sudo yum upgrade -y
            sudo yum autoremove -y
            sudo yum clean all
            ;;
        *)
            echo "Système d'exploitation non supporté pour la mise à jour automatique."
            exit 1
            ;;
    esac

    echo "[$(date)] Mise à jour du système terminée."
}

# Fonction pour vérifier les versions des services
check_service_versions() {
    echo "[$(date)] Vérification des versions des services..."

    # Liste des services à vérifier
    services=("nginx" "apache2" "mysql" "postgresql" "docker")

    for service in "${services[@]}"; do
        if command -v $service &> /dev/null; then
            version=$($service --version 2>&1 | head -n 1)
            echo "[$(date)] $service version: $version"
        else
            echo "[$(date)] $service n'est pas installé."
        fi
    done

    echo "[$(date)] Vérification des versions des services terminée."
}

# Exécution des fonctions
detect_os
update_system
check_service_versions
