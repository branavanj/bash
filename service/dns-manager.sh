#!/bin/bash

# Fonction pour installer BIND
installer_bind() {
    echo "Installation de BIND..."
    sudo dnf install -y bind bind-utils
    echo "BIND installé avec succès."
}

# Fonction pour configurer BIND
configurer_bind() {
    echo "Configuration de BIND..."
    sudo cp /etc/named.conf /etc/named.conf.bak
    sudo bash -c 'cat << EOF > /etc/named.conf
options {
    directory "/var/named";
    dump-file "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    secroots-file "/var/named/data/named.secroots";
    recursing-file "/var/named/data/named.recursing";
    allow-query { any; };
    recursion yes;
};

zone "." IN {
    type hint;
    file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF'
    sudo systemctl enable named
    sudo systemctl start named
    echo "BIND configuré et démarré."
}

# Fonction pour ajouter un domaine
ajouter_domaine() {
    echo -n "Entrez le nom de domaine: "
    read domaine
    echo -n "Entrez l'adresse IP: "
    read ip

    sudo bash -c 'cat << EOF > /var/named/'"$domaine"'.zone
\$TTL 86400
@   IN  SOA ns1.'"$domaine"'. admin.'"$domaine"'. (
        2023062401  ; Serial
        3600        ; Refresh
        1800        ; Retry
        604800      ; Expire
        86400       ; Minimum TTL
)
@   IN  NS  ns1.'"$domaine"'.
ns1 IN  A   '"$ip"'
@   IN  A   '"$ip"'
EOF'

    sudo bash -c 'cat << EOF >> /etc/named.rfc1912.zones
zone "'"$domaine"'" IN {
    type master;
    file "'"$domaine"'.zone";
    allow-update { none; };
};
EOF'

    sudo systemctl restart named
    echo "Domaine $domaine ajouté et BIND redémarré."
}

# Fonction pour ajouter un nom d'hôte à un domaine
ajouter_hostname() {
    echo "Liste des domaines disponibles:"
    grep 'zone "' /etc/named.rfc1912.zones | awk '{print $2}' | tr -d '"' | tr -d ';'
    echo -n "Entrez le nom de domaine où vous voulez ajouter un hostname: "
    read domaine

    if [ ! -f /var/named/"$domaine".zone ]; then
        echo "Le domaine n'existe pas."
        return
    fi

    echo -n "Entrez le hostname: "
    read hostname
    echo -n "Entrez l'adresse IP: "
    read ip

    sudo bash -c 'cat << EOF >> /var/named/'"$domaine"'.zone
'"$hostname"' IN A '"$ip"'
EOF'

    sudo systemctl restart named
    echo "Hostname $hostname avec IP $ip ajouté au domaine $domaine et BIND redémarré."
}

# Fonction pour lister les hostnames avec leurs IPs et les pinger
lister_hostnames() {
    echo "Liste des domaines disponibles:"
    grep 'zone "' /etc/named.rfc1912.zones | awk '{print $2}' | tr -d '"' | tr -d ';'
    echo -n "Entrez le nom de domaine pour lister les hostnames: "
    read domaine

    if [ ! -f /var/named/"$domaine".zone ]; then
        echo "Le domaine n'existe pas."
        return
    fi

    echo -e "\nListe des hostnames pour le domaine $domaine:"
    echo -e "Hostname\tIP\t\tPing"
    echo -e "--------\t--\t\t----"

    while read -r line; do
        if [[ $line == *"IN A"* ]]; then
            hostname=$(echo $line | awk '{print $1}')
            ip=$(echo $line | awk '{print $4}')
            if ping -c 1 $hostname &> /dev/null; then
                result="\e[32mRéussi\e[0m"
            else
                result="\e[31mÉchoué\e[0m"
            fi
            echo -e "$hostname\t$ip\t$result"
        fi
    done < /var/named/"$domaine".zone
}

# Fonction pour supprimer un domaine
supprimer_domaine() {
    echo "Liste des domaines disponibles:"
    grep 'zone "' /etc/named.rfc1912.zones | awk '{print $2}' | tr -d '"' | tr -d ';'
    echo -n "Entrez le nom de domaine à supprimer: "
    read domaine

    if [ ! -f /var/named/"$domaine".zone ]; then
        echo "Le domaine n'existe pas."
        return
    fi

    sudo rm /var/named/"$domaine".zone
    sudo sed -i "/zone \"$domaine\"/,+4d" /etc/named.rfc1912.zones
    sudo systemctl restart named
    echo "Domaine $domaine supprimé et BIND redémarré."
}

# Fonction pour supprimer un nom d'hôte d'un domaine
supprimer_hostname() {
    echo "Liste des domaines disponibles:"
    grep 'zone "' /etc/named.rfc1912.zones | awk '{print $2}' | tr -d '"' | tr -d ';'
    echo -n "Entrez le nom de domaine: "
    read domaine

    if [ ! -f /var/named/"$domaine".zone ]; then
        echo "Le domaine n'existe pas."
        return
    fi

    echo -n "Entrez le hostname à supprimer: "
    read hostname

    sudo sed -i "/^$hostname IN A/d" /var/named/"$domaine".zone
    sudo systemctl restart named
    echo "Hostname $hostname supprimé du domaine $domaine et BIND redémarré."
}

# Menu interactif
while true; do
    clear
    echo -e "Menu de gestion de BIND"
    echo -e "1. Installer BIND"
    echo -e "2. Configurer BIND"
    echo -e "3. Ajouter un domaine"
    echo -e "4. Ajouter un hostname à un domaine"
    echo -e "5. Lister les hostnames d'un domaine"
    echo -e "6. Supprimer un domaine"
    echo -e "7. Supprimer un hostname d'un domaine"
    echo -e "8. Quitter"
    echo -n "Choisissez une option: "
    read option

    case $option in
        1)
            installer_bind
            ;;
        2)
            configurer_bind
            ;;
        3)
            ajouter_domaine
            ;;
        4)
            ajouter_hostname
            ;;
        5)
            lister_hostnames
            ;;
        6)
            supprimer_domaine
            ;;
        7)
            supprimer_hostname
            ;;
        8)
            echo "Au revoir!"
            exit 0
            ;;
        *)
            echo "Option invalide!"
            ;;
    esac

    echo -n "Appuyez sur une touche pour continuer..."
    read pause
done

