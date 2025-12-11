#!/bin/bash

# Script de nettoyage des conteneurs certbot orphelins
# À exécuter si des conteneurs certbot s'accumulent

echo "🧹 Nettoyage des conteneurs certbot orphelins..."

# Compte le nombre de conteneurs certbot-run
COUNT=$(docker ps -a --filter "name=certbot-run" --format "{{.Names}}" | wc -l)

if [ "$COUNT" -eq 0 ]; then
    echo "✅ Aucun conteneur certbot orphelin trouvé"
    exit 0
fi

echo "⚠️  Trouvé $COUNT conteneurs certbot orphelins"

# Arrêt et suppression
echo "🛑 Arrêt des conteneurs..."
docker ps -a --filter "name=certbot-run" -q | xargs -r docker stop

echo "🗑️  Suppression des conteneurs..."
docker ps -a --filter "name=certbot-run" -q | xargs -r docker rm

echo "✅ Nettoyage terminé !"

# Vérification finale
REMAINING=$(docker ps -a --filter "name=certbot-run" --format "{{.Names}}" | wc -l)
if [ "$REMAINING" -eq 0 ]; then
    echo "✅ Tous les conteneurs orphelins ont été supprimés"
else
    echo "⚠️  Il reste encore $REMAINING conteneurs"
fi
