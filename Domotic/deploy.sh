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
SUBDOMAIN_LA4LDESDOMES=${SUBDOMAIN_LA4LDESDOMES:-"la4ldesdomes"}
SUBDOMAIN_CAPITALOT=${SUBDOMAIN_CAPITALOT:-"capitalot"}
SUBDOMAIN_DAE_OPTIMIZZER=${SUBDOMAIN_DAE_OPTIMIZZER:-"dae-optimizzer"}

echo "🚀 Déploiement Home Automation"
echo "🏷️  Environnement: $ENV"
echo "🌐 Domaine principal: $DOMAIN"
echo "📡 Sous-domaines:"
echo "   - API:        ${SUBDOMAIN_API}.${DOMAIN}"
echo "   - Grafana:    ${SUBDOMAIN_GRAFANA}.${DOMAIN}"
echo "   - phpMyAdmin: ${SUBDOMAIN_PHPMYADMIN}.${DOMAIN}"
echo "   - Portainer:  ${SUBDOMAIN_PORTAINER}.${DOMAIN}"
echo "   - Cloud:      ${SUBDOMAIN_NEXTCLOUD}.${DOMAIN}"
echo "   - La4ldesdomes: ${SUBDOMAIN_LA4LDESDOMES}.${DOMAIN}"
echo "   - Capitalot:  ${SUBDOMAIN_CAPITALOT}.${DOMAIN}"
echo "   - DAE Optimizzer: ${SUBDOMAIN_DAE_OPTIMIZZER}.${DOMAIN}"

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
chmod -R 755 nginx/ certbot/ 2>/dev/null || true
chmod -R 777 mosquitto/data mosquitto/log 2>/dev/null || true

echo "🌐 Création du réseau Docker partagé..."
# Création du réseau partagé unique pour tous les services
docker network inspect shared-network >/dev/null 2>&1 || docker network create shared-network
echo "✅ Réseau Docker partagé créé ou déjà existant"

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
    rm -f nginx/conf.d/default.conf nginx/conf.d/default.conf.bak nginx/conf.d/default-dev.conf
    bash ./generate-nginx-config.sh dev
    # Le script génère default-dev.conf, on le copie vers default.conf
    if [ -f nginx/conf.d/default-dev.conf ]; then
        mv nginx/conf.d/default-dev.conf nginx/conf.d/default.conf
    fi
    
    echo "🔄 Phase 1: Bases de données..."
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d db nextcloud-db
    sleep 30
    
    echo "🔄 Phase 2: Services..."
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d domotic-api listener mosquitto phpmyadmin grafana portainer nextcloud
    sleep 20
    
    echo "🔄 Phase 3: Nginx..."
    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d nginx-proxy
    sleep 5
    
    if ! docker compose ps nginx-proxy | grep -q "Up"; then
        echo "❌ Nginx n'a pas démarré"
        docker compose logs nginx-proxy
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
    echo "   https://${SUBDOMAIN_LA4LDESDOMES}.${DOMAIN}"
    echo "   https://${SUBDOMAIN_CAPITALOT}.${DOMAIN}"
    echo "   https://${SUBDOMAIN_DAE_OPTIMIZZER}.${DOMAIN}"
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
    docker compose up -d domotic-api listener mosquitto phpmyadmin grafana portainer nextcloud
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
    docker compose up -d nginx-proxy
    sleep 10
    
    if ! docker compose ps nginx-proxy | grep -q "Up"; then
        echo "❌ Nginx n'a pas démarré"
        docker compose logs nginx-proxy
        exit 1
    fi
    
    echo "🔐 Obtention certificats SSL pour tous les sous-domaines..."
    mkdir -p certbot/www/.well-known/acme-challenge
    
    # Certificats uniquement pour grafana, portainer, nextcloud, la4ldesdomes, capitalot et dae-optimizzer
    # Pas de certificats pour api et phpmyadmin
    SUBDOMAINS="${SUBDOMAIN_GRAFANA}.${DOMAIN},${SUBDOMAIN_PORTAINER}.${DOMAIN},${SUBDOMAIN_NEXTCLOUD}.${DOMAIN},${SUBDOMAIN_LA4LDESDOMES}.${DOMAIN},${SUBDOMAIN_CAPITALOT}.${DOMAIN},${SUBDOMAIN_DAE_OPTIMIZZER}.${DOMAIN}"
    
    if [ "$ENV" = "production" ]; then
        docker compose run --rm --entrypoint certbot certbot certonly --webroot \
            --webroot-path=/var/www/certbot \
            --email $EMAIL \
            --agree-tos \
            --no-eff-email \
            --non-interactive \
            --expand \
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
            --expand \
            -d $DOMAIN \
            -d $SUBDOMAINS
    fi
    
    if [ -f "certbot/conf/live/$DOMAIN/fullchain.pem" ]; then
        echo "✅ Certificats obtenus pour $DOMAIN et tous les sous-domaines"
        
        rm -f nginx/conf.d/default-http.conf
        mv nginx/conf.d/default.conf.bak nginx/conf.d/default.conf
        
        # Test et reload nginx sans redémarrer le container
        echo "🔧 Rechargement de la configuration Nginx..."
        docker exec nginx-proxy nginx -t
        if [ $? -eq 0 ]; then
            docker exec nginx-proxy nginx -s reload
            sleep 2
        else
            echo "❌ Erreur dans la configuration Nginx"
            docker compose logs nginx-proxy
            exit 1
        fi
        
        if ! docker compose ps nginx-proxy | grep -q "Up"; then
            echo "❌ Nginx n'a pas redémarré avec SSL"
            docker compose logs nginx-proxy
            exit 1
        fi
        echo "✅ Nginx avec SSL activé"
    else
        echo "❌ Certificats non créés"
        echo "Vérifiez que les DNS pointent vers ce serveur :"
        echo "  - $DOMAIN"
        echo "  - ${SUBDOMAIN_GRAFANA}.$DOMAIN"
        echo "  - ${SUBDOMAIN_PORTAINER}.$DOMAIN"
        echo "  - ${SUBDOMAIN_NEXTCLOUD}.$DOMAIN"
        echo "  - ${SUBDOMAIN_LA4LDESDOMES}.$DOMAIN"
        echo "  - ${SUBDOMAIN_CAPITALOT}.$DOMAIN"
        echo "  - ${SUBDOMAIN_DAE_OPTIMIZZER}.$DOMAIN"
        echo ""
        echo "Note: api et phpmyadmin n'utilisent pas de certificats SSL"
        exit 1
    fi
    
    echo "🔄 Renouvellement automatique SSL..."
    (crontab -l 2>/dev/null; echo "0 3 * * * cd $(pwd) && docker compose run --rm certbot renew && docker compose restart nginx-proxy") | crontab -
    
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
    echo "   🚗 La4ldesdomes:  https://${SUBDOMAIN_LA4LDESDOMES}.$DOMAIN"
    echo "   💰 Capitalot:     https://${SUBDOMAIN_CAPITALOT}.$DOMAIN"
    echo "   🚑 DAE Optimizzer: https://${SUBDOMAIN_DAE_OPTIMIZZER}.$DOMAIN"
    echo ""
    echo "✅ SSL Let's Encrypt configuré pour tous les domaines"
fi
