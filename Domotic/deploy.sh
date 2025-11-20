#!/bin/bash

set -e

if [ -f .env ]; then
    set -a
    source <(grep -v '^#' .env | grep -v '^\s*$' | sed 's/^\([^=]*\)=\(.*\)$/\1="\2"/')
    set +a
fi

if [ -f subdomains.env ]; then
    set -a
    source <(grep -v '^#' subdomains.env | grep -v '^\s*$' | sed 's/^\([^=]*\)=\(.*\)$/\1="\2"/')
    set +a
fi

DOMAIN=${DOMAIN:-"yourdomain.com"}
EMAIL=${LETSENCRYPT_EMAIL:-"admin@yourdomain.com"}
ENV=${1:-"production"}

SUBDOMAIN_API=${SUBDOMAIN_API:-"api"}
SUBDOMAIN_GRAFANA=${SUBDOMAIN_GRAFANA:-"grafana"}
SUBDOMAIN_PHPMYADMIN=${SUBDOMAIN_PHPMYADMIN:-"phpmyadmin"}
SUBDOMAIN_PORTAINER=${SUBDOMAIN_PORTAINER:-"portainer"}
SUBDOMAIN_NEXTCLOUD=${SUBDOMAIN_NEXTCLOUD:-"cloud"}

echo "🚀 Déploiement Home Automation"
echo "🏷️  Environnement: $ENV"
echo "🌐 Domaine principal: $DOMAIN"
echo "📡 Sous-domaines:"
echo "   - API:        ${SUBDOMAIN_API}.${DOMAIN}"
echo "   - Grafana:    ${SUBDOMAIN_GRAFANA}.${DOMAIN}"
echo "   - phpMyAdmin: ${SUBDOMAIN_PHPMYADMIN}.${DOMAIN}"
echo "   - Portainer:  ${SUBDOMAIN_PORTAINER}.${DOMAIN}"
echo "   - Cloud:      ${SUBDOMAIN_NEXTCLOUD}.${DOMAIN}"

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
    echo "🔧 Mode DEV: Certificat auto-signé"
    
    echo "🔐 Génération certificat auto-signé..."
    if [ ! -f "nginx/ssl/selfsigned.crt" ]; then
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/selfsigned.key \
            -out nginx/ssl/selfsigned.crt \
            -subj "/C=FR/ST=France/L=Paris/O=Dev/CN=localhost"
        echo "✅ Certificat auto-signé créé"
    else
        echo "✅ Certificat auto-signé déjà présent"
    fi
    
    echo "🔧 Génération configuration Nginx pour DEV..."
    bash ./generate-nginx-config.sh dev
    
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
    echo "📋 Services disponibles (certificat auto-signé) :"
    echo "   https://${SUBDOMAIN_API}.${DOMAIN}"
    echo "   https://${SUBDOMAIN_GRAFANA}.${DOMAIN}"
    echo "   https://${SUBDOMAIN_PHPMYADMIN}.${DOMAIN}"
    echo "   https://${SUBDOMAIN_PORTAINER}.${DOMAIN}"
    echo "   https://${SUBDOMAIN_NEXTCLOUD}.${DOMAIN}"
    echo ""
    echo "⚠️  Certificat auto-signé : ignorez l'avertissement de sécurité du navigateur"
    
else
    echo "📍 Domaine: $DOMAIN"
    
    echo "🔧 Génération configuration Nginx..."
    bash ./generate-nginx-config.sh production
    
    echo "🔄 Phase 1: Bases de données..."
    docker compose up -d db nextcloud-db
    sleep 30
    
    echo "🔄 Phase 2: Services..."
    docker compose up -d api listener mosquitto phpmyadmin grafana portainer nextcloud
    sleep 20
    
    echo "🔄 Phase 3: SSL Setup - Nginx HTTP temporaire..."
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
    
    echo "🔐 Obtention certificats SSL pour tous les sous-domaines..."
    mkdir -p certbot/www/.well-known/acme-challenge
    
    SUBDOMAINS="${SUBDOMAIN_API}.${DOMAIN},${SUBDOMAIN_GRAFANA}.${DOMAIN},${SUBDOMAIN_PHPMYADMIN}.${DOMAIN},${SUBDOMAIN_PORTAINER}.${DOMAIN},${SUBDOMAIN_NEXTCLOUD}.${DOMAIN}"
    
    if [ "$ENV" = "production" ]; then
        docker compose run --rm --entrypoint certbot certbot certonly --webroot \
            --webroot-path=/var/www/certbot \
            --email $EMAIL \
            --agree-tos \
            --no-eff-email \
            --non-interactive \
            -d $DOMAIN \
            -d $SUBDOMAINS
    else
        docker compose run --rm --entrypoint certbot certbot certonly --webroot \
            --webroot-path=/var/www/certbot \
            --email $EMAIL \
            --agree-tos \
            --no-eff-email \
            --staging \
            --non-interactive \
            -d $DOMAIN \
            -d $SUBDOMAINS
    fi
    
    if [ -f "certbot/conf/live/$DOMAIN/fullchain.pem" ]; then
        echo "✅ Certificats obtenus pour $DOMAIN et tous les sous-domaines"
        
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
        echo "Vérifiez que les DNS pointent vers ce serveur :"
        echo "  - $DOMAIN"
        echo "  - ${SUBDOMAIN_API}.$DOMAIN"
        echo "  - ${SUBDOMAIN_GRAFANA}.$DOMAIN"
        echo "  - ${SUBDOMAIN_PHPMYADMIN}.$DOMAIN"
        echo "  - ${SUBDOMAIN_PORTAINER}.$DOMAIN"
        echo "  - ${SUBDOMAIN_NEXTCLOUD}.$DOMAIN"
        exit 1
    fi
    
    echo "🔄 Renouvellement automatique SSL..."
    (crontab -l 2>/dev/null; echo "0 3 * * * cd $(pwd) && docker compose run --rm certbot renew && docker compose restart nginx") | crontab -
    
    echo ""
    echo "🎉 Déploiement terminé !"
    echo ""
    echo "📋 Services disponibles :"
    echo "   🌐 Page principale: https://$DOMAIN"
    echo "   🔌 API:            https://${SUBDOMAIN_API}.$DOMAIN"
    echo "   📊 Grafana:        https://${SUBDOMAIN_GRAFANA}.$DOMAIN"
    echo "   🗄️  phpMyAdmin:    https://${SUBDOMAIN_PHPMYADMIN}.$DOMAIN"
    echo "   🐳 Portainer:      https://${SUBDOMAIN_PORTAINER}.$DOMAIN"
    echo "   ☁️  Cloud:          https://${SUBDOMAIN_NEXTCLOUD}.$DOMAIN"
    echo ""
    echo "✅ SSL Let's Encrypt configuré pour tous les domaines"
fi
