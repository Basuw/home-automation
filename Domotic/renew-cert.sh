#!/bin/bash

set -e

cd "$(dirname "$0")"

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

DOMAIN=${DOMAIN:-"bastien-jacquelin.fr"}
EMAIL=${LETSENCRYPT_EMAIL:-"bastien.jacquelin@gmail.com"}

SUBDOMAIN_API=${SUBDOMAIN_API:-"api"}
SUBDOMAIN_GRAFANA=${SUBDOMAIN_GRAFANA:-"grafana"}
SUBDOMAIN_DB=${SUBDOMAIN_DB:-"db"}
SUBDOMAIN_PORTAINER=${SUBDOMAIN_PORTAINER:-"portainer"}
SUBDOMAIN_NEXTCLOUD=${SUBDOMAIN_NEXTCLOUD:-"cloud"}
SUBDOMAIN_LA4LDESDOMES=${SUBDOMAIN_LA4LDESDOMES:-"la4ldesdomes"}
SUBDOMAIN_CAPITALOT=${SUBDOMAIN_CAPITALOT:-"capitalot"}
SUBDOMAIN_DAE_OPTIMIZZER=${SUBDOMAIN_DAE_OPTIMIZZER:-"dae-optimizzer"}

echo "🔐 Renouvellement du certificat SSL pour $DOMAIN"
echo "📧 Email: $EMAIL"
echo ""
echo "📡 Sous-domaines inclus:"
echo "   - ${SUBDOMAIN_API}.${DOMAIN}"
echo "   - ${SUBDOMAIN_GRAFANA}.${DOMAIN}"
echo "   - ${SUBDOMAIN_DB}.${DOMAIN}"
echo "   - ${SUBDOMAIN_PORTAINER}.${DOMAIN}"
echo "   - ${SUBDOMAIN_NEXTCLOUD}.${DOMAIN}"
echo "   - ${SUBDOMAIN_LA4LDESDOMES}.${DOMAIN}"
echo "   - ${SUBDOMAIN_CAPITALOT}.${DOMAIN}"
echo "   - ${SUBDOMAIN_DAE_OPTIMIZZER}.${DOMAIN}"
echo ""

# Vérification que nginx est en cours d'exécution
if ! docker compose ps nginx-proxy | grep -q "Up"; then
    echo "❌ Nginx n'est pas en cours d'exécution"
    exit 1
fi

# Création du dossier acme-challenge
mkdir -p certbot/www/.well-known/acme-challenge

# Liste tous les domaines
ALL_DOMAINS="-d $DOMAIN"
ALL_DOMAINS="$ALL_DOMAINS -d ${SUBDOMAIN_API}.${DOMAIN}"
ALL_DOMAINS="$ALL_DOMAINS -d ${SUBDOMAIN_GRAFANA}.${DOMAIN}"
ALL_DOMAINS="$ALL_DOMAINS -d ${SUBDOMAIN_DB}.${DOMAIN}"
ALL_DOMAINS="$ALL_DOMAINS -d ${SUBDOMAIN_PORTAINER}.${DOMAIN}"
ALL_DOMAINS="$ALL_DOMAINS -d ${SUBDOMAIN_NEXTCLOUD}.${DOMAIN}"
ALL_DOMAINS="$ALL_DOMAINS -d ${SUBDOMAIN_LA4LDESDOMES}.${DOMAIN}"
ALL_DOMAINS="$ALL_DOMAINS -d ${SUBDOMAIN_CAPITALOT}.${DOMAIN}"
ALL_DOMAINS="$ALL_DOMAINS -d ${SUBDOMAIN_DAE_OPTIMIZZER}.${DOMAIN}"

echo "🚀 Lancement de certbot..."
docker exec certbot certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    --expand \
    $ALL_DOMAINS

if [ -f "certbot/conf/live/$DOMAIN/fullchain.pem" ]; then
    echo ""
    echo "✅ Certificat renouvelé avec succès !"
    echo ""
    echo "🔄 Rechargement de Nginx..."
    docker exec nginx-proxy nginx -t && docker exec nginx-proxy nginx -s reload
    echo "✅ Nginx rechargé"
    echo ""
    echo "📋 Domaines couverts par le certificat :"
    openssl x509 -in certbot/conf/live/$DOMAIN/cert.pem -text -noout | grep -A 1 "Subject Alternative Name"
else
    echo ""
    echo "❌ Échec du renouvellement du certificat"
    exit 1
fi
