#!/bin/bash

set -e

if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

DOMAIN=${DOMAIN:-"yourdomain.com"}
EMAIL=${LETSENCRYPT_EMAIL:-"admin@yourdomain.com"}
ENV=${1:-"production"}

echo "🚀 Déploiement Home Automation"
echo "🏷️  Environnement: $ENV"

if ! command -v docker &> /dev/null; then
    echo "❌ Docker non installé"
    exit 1
fi

if [ ! -f .env ]; then
    echo "❌ Fichier .env manquant"
    exit 1
fi

echo "📁 Création des dossiers..."
mkdir -p nginx/conf.d nginx/ssl certbot/conf certbot/www mosquitto/data mosquitto/log

echo "🔒 Configuration des permissions..."
chmod -R 755 nginx/ certbot/
chmod -R 777 mosquitto/data mosquitto/log

if [ "$ENV" = "dev" ]; then
    echo "🔧 Mode DEV: Sans SSL"
    
    echo "🔄 Phase 1: Bases de données..."
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d db nextcloud-db
    sleep 30
    
    echo "🔄 Phase 2: Services..."
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d api listener mosquitto phpmyadmin grafana portainer nextcloud
    sleep 20
    
    echo "🔄 Phase 3: Nginx..."
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d nginx
    sleep 5
    
    if ! docker compose ps nginx | grep -q "Up"; then
        echo "❌ Nginx n'a pas démarré"
        docker compose logs nginx
        exit 1
    fi
    
    echo ""
    echo "🎉 Déploiement DEV terminé !"
    echo ""
    echo "📋 Services disponibles sur http://localhost :"
    echo "   http://localhost/api"
    echo "   http://localhost/grafana"
    echo "   http://localhost/phpmyadmin"
    echo "   http://localhost/portainer"
    echo "   http://localhost/nextcloud"
    
else
    echo "📍 Domaine: $DOMAIN"
    
    echo "🔧 Configuration Nginx..."
    envsubst '${DOMAIN}' < nginx/conf.d/default.conf > nginx/conf.d/default-tmp.conf
    mv nginx/conf.d/default-tmp.conf nginx/conf.d/default.conf
    
    echo "🔄 Phase 1: Bases de données..."
    docker compose up -d db nextcloud-db
    sleep 30
    
    echo "🔄 Phase 2: Services..."
    docker compose up -d api listener mosquitto phpmyadmin grafana portainer nextcloud
    sleep 20
    
    echo "🔄 Phase 3: SSL..."
    cat > nginx/conf.d/default-http.conf << 'EOF'
server {
    listen 80;
    server_name _;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
EOF
    
    mv nginx/conf.d/default.conf nginx/conf.d/default.conf.bak
    docker compose up -d nginx
    sleep 10
    
    if ! docker compose ps nginx | grep -q "Up"; then
        echo "❌ Nginx n'a pas démarré"
        docker compose logs nginx
        exit 1
    fi
    
    echo "🔐 Obtention certificat SSL..."
    mkdir -p certbot/www/.well-known/acme-challenge
    
    if [ "$ENV" = "production" ]; then
        docker compose run --rm --entrypoint certbot certbot certonly --webroot \
            --webroot-path=/var/www/certbot \
            --email $EMAIL \
            --agree-tos \
            --no-eff-email \
            --non-interactive \
            -d $DOMAIN
    else
        docker compose run --rm --entrypoint certbot certbot certonly --webroot \
            --webroot-path=/var/www/certbot \
            --email $EMAIL \
            --agree-tos \
            --no-eff-email \
            --staging \
            --non-interactive \
            -d $DOMAIN
    fi
    
    if [ -f "certbot/conf/live/$DOMAIN/fullchain.pem" ]; then
        echo "✅ Certificat obtenu"
        
        rm -f nginx/conf.d/default-http.conf
        mv nginx/conf.d/default.conf.bak nginx/conf.d/default.conf
        
        docker compose restart nginx
        sleep 5
        
        if ! docker compose ps nginx | grep -q "Up"; then
            echo "❌ Nginx n'a pas redémarré avec SSL"
            docker compose logs nginx
            exit 1
        fi
        echo "✅ Nginx avec SSL activé"
    else
        echo "❌ Certificats non créés"
    fi
    
    echo "🔄 Renouvellement automatique SSL..."
    (crontab -l 2>/dev/null; echo "0 3 * * * cd $(pwd) && docker compose run --rm certbot renew && docker compose restart nginx") | crontab -
    
    echo ""
    echo "🎉 Déploiement terminé !"
    echo ""
    echo "📋 Services :"
    echo "   https://$DOMAIN/api"
    echo "   https://$DOMAIN/grafana"
    echo "   https://$DOMAIN/phpmyadmin"
    echo "   https://$DOMAIN/portainer"
    echo "   https://$DOMAIN/nextcloud"
fi
