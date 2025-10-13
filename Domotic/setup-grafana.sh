#!/bin/bash

# Script pour configurer Grafana avec la datasource PostgreSQL et le dashboard
# Usage: ./setup-grafana.sh

set -e

echo "🔧 Configuration de Grafana avec PostgreSQL"

# Charger les variables d'environnement
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Attendre que Grafana soit prêt
echo "⏳ Attente de Grafana..."
sleep 10

# URL de Grafana
GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="${GF_SECURITY_ADMIN_USER:-admin}"
GRAFANA_PASSWORD="${GF_SECURITY_ADMIN_PASSWORD}"

echo "📊 Configuration de la datasource PostgreSQL..."

# Créer la datasource PostgreSQL
curl -X POST \
  -H "Content-Type: application/json" \
  -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
  "$GRAFANA_URL/api/datasources" \
  -d '{
    "name": "PostgreSQL",
    "type": "postgres",
    "uid": "postgres-datasource",
    "access": "proxy",
    "url": "db:5432",
    "database": "'"$POSTGRES_DB"'",
    "user": "'"$POSTGRES_USER"'",
    "secureJsonData": {
      "password": "'"$POSTGRES_PASSWORD"'"
    },
    "jsonData": {
      "sslmode": "disable",
      "postgresVersion": 1300,
      "timescaledb": false
    },
    "isDefault": true
  }' 2>/dev/null || echo "⚠️  Datasource existe déjà"

echo "✅ Datasource PostgreSQL configurée"

echo "📈 Import du dashboard..."

# Importer le dashboard
if [ -f "grafana/dashboards/home-automation-dashboard.json" ]; then
    DASHBOARD_JSON=$(cat grafana/dashboards/home-automation-dashboard.json)
    
    curl -X POST \
      -H "Content-Type: application/json" \
      -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
      "$GRAFANA_URL/api/dashboards/db" \
      -d '{
        "dashboard": '"$DASHBOARD_JSON"',
        "overwrite": true,
        "message": "Dashboard importé via script"
      }' 2>/dev/null
    
    echo "✅ Dashboard importé avec succès"
else
    echo "❌ Fichier dashboard non trouvé"
    exit 1
fi

echo ""
echo "🎉 Configuration Grafana terminée !"
echo ""
echo "📋 Accès :"
echo "   URL: https://${DOMAIN}/grafana"
echo "   User: $GRAFANA_USER"
echo "   Password: (voir .env)"
echo ""
echo "📈 Dashboard : 🏠 Domotique - Dashboard Principal"
echo ""
