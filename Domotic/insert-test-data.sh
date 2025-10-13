#!/bin/bash

# Script pour insérer les données de test dans PostgreSQL
# Usage: ./insert-test-data.sh [staging|production]
# Note: Les données de test sont uniquement insérées en environnement staging

set -e

ENV=${1:-"staging"}

# Vérifier l'environnement
if [ "$ENV" != "staging" ]; then
    echo "⚠️  Les données de test ne sont insérées qu'en environnement staging"
    echo "   Environnement actuel: $ENV"
    echo "   Pour insérer des données de test, lancez: ./insert-test-data.sh staging"
    exit 0
fi

echo "📊 Insertion des données de test dans PostgreSQL (environnement: staging)..."

# Vérifier que le conteneur db est démarré
if ! docker compose ps db | grep -q "Up"; then
    echo "❌ Le conteneur PostgreSQL n'est pas démarré"
    echo "   Lancez: docker compose up -d db"
    exit 1
fi

# Attendre que PostgreSQL soit prêt
echo "⏳ Attente de PostgreSQL..."
sleep 5

# Copier le fichier SQL dans le conteneur
echo "📁 Copie du script SQL..."
docker cp Data/insert_test_data.sql home-automation-db-1:/tmp/insert_test_data.sql 2>/dev/null || \
docker cp Data/insert_test_data.sql db:/tmp/insert_test_data.sql

# Exécuter le script SQL
echo "🔄 Exécution du script d'insertion..."
docker compose exec -T db psql -U admin -d domotic -f /tmp/insert_test_data.sql

echo ""
echo "✅ Données de test insérées avec succès !"
echo ""
echo "📊 Données disponibles :"
echo "   • 4 capteurs (Salon, Chambre, Cuisine, Extérieur)"
echo "   • 7 jours de données historiques"
echo "   • Mesures toutes les 15 minutes"
echo "   • ~2,688 mesures par capteur"
echo ""
echo "🔍 Vérification dans phpMyAdmin :"
echo "   https://${DOMAIN:-jacquelin63.freeboxos.fr}/phpmyadmin"
echo ""
echo "📈 Visualisation dans Grafana :"
echo "   1. Lancez: ./setup-grafana.sh"
echo "   2. Accédez à: https://${DOMAIN:-jacquelin63.freeboxos.fr}/grafana"
echo ""
