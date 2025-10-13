#!/bin/bash

# Script pour nettoyer les conteneurs existants et redémarrer proprement
# Usage: ./cleanup.sh

echo "🧹 Nettoyage des conteneurs existants..."

# Arrêter tous les conteneurs du projet
echo "🛑 Arrêt des conteneurs..."
docker compose down --remove-orphans

# Nettoyer les fichiers de configuration temporaires Nginx
echo "🧹 Nettoyage des fichiers de configuration temporaires..."
rm -f nginx/conf.d/default-paths-temp.conf nginx/conf.d/default-paths-temp.conf.bak

# Supprimer les conteneurs avec les mêmes noms si ils existent encore
echo "🗑️ Suppression des conteneurs orphelins..."
containers=("mosquitto" "api" "listenner" "db" "pgadmin" "grafana" "portainer" "nextcloud" "nextcloud-db" "nginx" "certbot")

for container in "${containers[@]}"; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        echo "🗑️ Suppression du conteneur: $container"
        docker rm -f $container
    fi
done

echo "✅ Nettoyage terminé. Vous pouvez maintenant lancer:"
echo "   docker compose up -d nginx certbot"