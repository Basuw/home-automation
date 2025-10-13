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

# Remplacement du domaine dans la config Nginx paths
echo "🔧 Configuration Nginx pour le domaine $DOMAIN..."
# Copier le template et le modifier sans toucher à l'original
cp nginx/conf.d/default-paths.conf nginx/conf.d/default-paths-temp.conf
sed -i "s/jacquelin63.freeboxos.fr/$DOMAIN/g" nginx/conf.d/default-paths-temp.conf

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

# Renommer temporairement la config SSL pour éviter qu'elle soit chargée
echo "📝 Préparation de la configuration Nginx..."
if [ -f nginx/conf.d/default-paths-temp.conf ]; then
    mv nginx/conf.d/default-paths-temp.conf nginx/conf.d/default-paths-temp.conf.bak
fi

# Créer la configuration HTTP temporaire pour Let's Encrypt
echo "📝 Configuration Nginx en mode HTTP pour validation Let's Encrypt..."
cat > nginx/conf.d/default.conf << 'EOF'
server {
    listen 80;
    server_name _;

    # ACME challenge pour Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Répondre 200 OK pour les autres requêtes pendant la validation
    location / {
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Démarrer Nginx pour la validation Let's Encrypt
docker compose up -d nginx

# Attendre que Nginx soit prêt
echo "⏳ Attente de Nginx..."
sleep 10

# Vérifier que Nginx fonctionne
if ! docker compose ps nginx | grep -q "Up"; then
    echo "❌ Nginx n'a pas démarré correctement"
    docker compose logs nginx
    exit 1
fi

# Vérifier la configuration Nginx
echo "🔍 Vérification de la configuration Nginx..."
docker compose exec nginx nginx -t

# Recharger Nginx pour être sûr que la config est prise en compte
echo "🔄 Rechargement de la configuration Nginx..."
docker compose exec nginx nginx -s reload

echo "✅ Nginx démarré en mode HTTP"

# Obtenir les certificats SSL
echo "🔐 Obtention des certificats SSL..."

# Test de connectivité du challenge ACME
echo "🧪 Test du dossier ACME challenge..."
mkdir -p certbot/www/.well-known/acme-challenge
echo "test" > certbot/www/.well-known/acme-challenge/test.txt
sleep 2

# Tester depuis le conteneur
docker compose exec nginx cat /var/www/certbot/.well-known/acme-challenge/test.txt || echo "⚠️ Problème d'accès au dossier ACME"

if [ "$ENV" = "production" ]; then
    # Production - certificat réel pour le domaine principal uniquement
    echo "🔐 Obtention du certificat SSL pour $DOMAIN (configuration path-based)"
    docker compose run --rm --entrypoint certbot certbot certonly --webroot \
        --webroot-path=/var/www/certbot \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --non-interactive \
        -d $DOMAIN
else
    # Staging - certificat de test pour le domaine principal uniquement
    echo "🔐 Obtention du certificat SSL de test pour $DOMAIN (configuration path-based)"
    docker compose run --rm --entrypoint certbot certbot certonly --webroot \
        --webroot-path=/var/www/certbot \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --staging \
        --non-interactive \
        -d $DOMAIN
fi

# Vérifier que les certificats ont été créés
if [ -f "certbot/conf/live/$DOMAIN/fullchain.pem" ]; then
    echo "✅ Certificat SSL obtenu avec succès pour $DOMAIN"
    echo "   Tous les services seront accessibles via HTTPS avec paths"
    echo "   Exemple: https://$DOMAIN/grafana, https://$DOMAIN/api, etc."
    
    # Restaurer et activer la configuration path-based avec SSL
    echo "📝 Activation de la configuration path-based avec SSL..."
    if [ -f nginx/conf.d/default-paths-temp.conf.bak ]; then
        mv nginx/conf.d/default-paths-temp.conf.bak nginx/conf.d/default-paths-temp.conf
    fi
    cp nginx/conf.d/default-paths-temp.conf nginx/conf.d/default.conf
    
    # Redémarrer Nginx avec SSL
    echo "🔄 Redémarrage de Nginx avec SSL..."
    docker compose restart nginx
    
    # Vérifier que Nginx a bien redémarré
    sleep 5
    if ! docker compose ps nginx | grep -q "Up"; then
        echo "❌ Nginx n'a pas redémarré correctement avec SSL"
        docker compose logs nginx
        exit 1
    fi
    echo "✅ Nginx redémarré avec SSL activé (path-based routing)"
else
    echo "❌ Les certificats n'ont pas été créés"
    echo "⚠️  Le système continue à fonctionner en HTTP seulement"
fi

# Vérification finale
echo "🔍 Vérification des services..."
sleep 10

# Test des services (via paths)
services=("api" "grafana" "pgadmin" "portainer" "nextcloud")
for service in "${services[@]}"; do
    if curl -sf "https://$DOMAIN/$service" > /dev/null; then
        echo "✅ https://$DOMAIN/$service - OK"
    else
        echo "⚠️  https://$DOMAIN/$service - Problème détecté"
    fi
done

# Configuration du renouvellement automatique
echo "🔄 Configuration du renouvellement automatique SSL..."
(crontab -l 2>/dev/null; echo "0 3 * * * cd $(pwd) && docker compose run --rm certbot renew && docker compose restart nginx") | crontab -

echo ""
echo "🎉 Déploiement terminé !"
echo ""
echo "� Configuration SSL : Certificat unique pour $DOMAIN"
echo "🛣️  Routing : Path-based (pas de sous-domaines)"
echo ""
echo "�📋 Accès aux services :"
echo "   🏠 Dashboard principal: https://$DOMAIN/"
echo "   🔌 API Domotique:       https://$DOMAIN/api"
echo "   📊 Grafana:             https://$DOMAIN/grafana"
echo "   🗄️  PgAdmin:            https://$DOMAIN/pgadmin"
echo "   🐳 Portainer:           https://$DOMAIN/portainer"
echo "   ☁️  Nextcloud:          https://$DOMAIN/nextcloud"
echo ""
echo "💡 Avantages de cette configuration :"
echo "   • Un seul certificat SSL à gérer"
echo "   • Pas de configuration DNS pour sous-domaines"
echo "   • Renouvellement automatique simplifié"
echo "   • Tous les services sous le même domaine"
echo ""
# Configuration automatique selon l'environnement
if [ "$ENV" = "staging" ]; then
    echo ""
    echo "🧪 Configuration automatique de l'environnement STAGING..."
    echo ""
    
    # Insertion des données de test
    echo "📊 Insertion des données de test..."
    if [ -f insert-test-data.sh ]; then
        chmod +x insert-test-data.sh
        ./insert-test-data.sh staging
    else
        echo "⚠️  Script insert-test-data.sh non trouvé"
    fi
    
    echo ""
    
    # Configuration de Grafana
    echo "📈 Configuration de Grafana..."
    if [ -f setup-grafana.sh ]; then
        chmod +x setup-grafana.sh
        ./setup-grafana.sh
    else
        echo "⚠️  Script setup-grafana.sh non trouvé"
    fi
    
    echo ""
    echo "✅ Configuration STAGING terminée !"
fi

echo ""
echo "🔧 Prochaines étapes :"
if [ "$ENV" = "staging" ]; then
    echo "   1. ✅ Données de test insérées"
    echo "   2. ✅ Grafana configuré"
    echo "   3. Testez votre API domotique"
    echo "   4. Vérifiez tous les services"
else
    echo "   1. Configurez vos dashboards Grafana"
    echo "   2. Ajoutez votre serveur PostgreSQL dans PgAdmin"
    echo "   3. Configurez Nextcloud selon vos besoins"
    echo "   4. Testez votre API domotique"
fi
echo ""
echo "📖 Consultez le README-PATHS.md pour plus de détails"