#!/bin/bash

# Script de déploiement automatique pour Home Automation System
# Usage: ./deploy.sh [production|staging]

set -e

# Charger les variables d'environnement depuis .env
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Configuration
DOMAIN=${DOMAIN:-"yourdomain.com"}
EMAIL=${LETSENCRYPT_EMAIL:-"admin@yourdomain.com"}
ENV=${1:-"production"}

echo "🚀 Démarrage du déploiement Home Automation System"
echo "📍 Domaine: $DOMAIN"
echo "📧 Email: $EMAIL"
echo "🏷️  Environnement: $ENV"

# Vérification des prérequis
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé"
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé"
    exit 1
fi

# Vérification du fichier .env
if [ ! -f .env ]; then
    echo "❌ Fichier .env manquant"
    echo "📝 Copiez .env.example vers .env et configurez vos variables"
    exit 1
fi

# Création des dossiers nécessaires
echo "📁 Création des dossiers..."
mkdir -p nginx/conf.d nginx/ssl certbot/conf certbot/www
mkdir -p mosquitto/data mosquitto/log

# Configuration des permissions
echo "🔒 Configuration des permissions..."
chmod -R 755 nginx/ certbot/
chmod -R 777 mosquitto/data mosquitto/log

# Remplacement du domaine dans la config Nginx
echo "🔧 Configuration Nginx pour le domaine $DOMAIN..."
sed -i "s/jacquelin63.freeboxos.fr/$DOMAIN/g" nginx/conf.d/default.conf

# Première phase : démarrage sans SSL
echo "🔄 Phase 1: Démarrage des services de base..."
docker compose up -d db nextcloud-db

# Attendre que les bases de données soient prêtes
echo "⏳ Attente des bases de données..."
sleep 30

# Démarrage des autres services
echo "🔄 Phase 2: Démarrage des services applicatifs..."
docker compose up -d api listener mosquitto pgadmin grafana portainer nextcloud

# Attendre que les services soient prêts
echo "⏳ Attente des services..."
sleep 20

# Phase SSL
echo "🔄 Phase 3: Configuration SSL..."

# Démarrer Nginx pour la validation Let's Encrypt
docker compose up -d nginx

# Attendre que Nginx soit prêt
echo "⏳ Attente de Nginx..."
sleep 10

# Obtenir les certificats SSL
echo "🔐 Obtention des certificats SSL..."
if [ "$ENV" = "production" ]; then
    # Production - certificats réels
    docker compose run --rm --entrypoint certbot certbot certonly --webroot \
        --webroot-path=/var/www/certbot \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --non-interactive \
        -d $DOMAIN \
        -d api.$DOMAIN \
        -d grafana.$DOMAIN \
        -d pgadmin.$DOMAIN \
        -d portainer.$DOMAIN \
        -d nextcloud.$DOMAIN
else
    # Staging - certificats de test
    docker compose run --rm --entrypoint certbot certbot certonly --webroot \
        --webroot-path=/var/www/certbot \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --staging \
        --non-interactive \
        -d $DOMAIN \
        -d api.$DOMAIN \
        -d grafana.$DOMAIN \
        -d pgadmin.$DOMAIN \
        -d portainer.$DOMAIN \
        -d nextcloud.$DOMAIN
fi

# Redémarrer Nginx avec SSL
echo "🔄 Redémarrage avec SSL..."
docker compose restart nginx

# Vérification finale
echo "🔍 Vérification des services..."
sleep 10

# Test des services
services=("api" "grafana" "pgadmin" "portainer" "nextcloud")
for service in "${services[@]}"; do
    if curl -sf "https://$service.$DOMAIN" > /dev/null; then
        echo "✅ $service.$DOMAIN - OK"
    else
        echo "⚠️  $service.$DOMAIN - Problème détecté"
    fi
done

# Configuration du renouvellement automatique
echo "🔄 Configuration du renouvellement automatique SSL..."
(crontab -l 2>/dev/null; echo "0 3 * * * cd $(pwd) && docker compose run --rm certbot renew && docker compose restart nginx") | crontab -

echo ""
echo "🎉 Déploiement terminé !"
echo ""
echo "📋 Accès aux services :"
echo "   🏠 Dashboard principal: https://$DOMAIN"
echo "   🔌 API Domotique: https://api.$DOMAIN"
echo "   📊 Grafana: https://grafana.$DOMAIN"
echo "   🗄️  PgAdmin: https://pgadmin.$DOMAIN"
echo "   🐳 Portainer: https://portainer.$DOMAIN"
echo "   ☁️  Nextcloud: https://nextcloud.$DOMAIN"
echo ""
echo "🔧 Prochaines étapes :"
echo "   1. Configurez vos dashboards Grafana"
echo "   2. Ajoutez votre serveur PostgreSQL dans PgAdmin"
echo "   3. Configurez Nextcloud selon vos besoins"
echo "   4. Testez votre API domotique"
echo ""
echo "📖 Consultez le README.md pour plus de détails"