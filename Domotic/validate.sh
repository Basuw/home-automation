#!/bin/bash

# Script de validation de la configuration
# Usage: ./validate.sh

echo "🔍 Validation de la configuration Home Automation System"
echo ""

# Vérification des fichiers requis
echo "📁 Vérification des fichiers..."

required_files=(
    ".env"
    "docker compose.yml" 
    "nginx/nginx.conf"
    "nginx/conf.d/default.conf"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file - MANQUANT"
        exit 1
    fi
done

# Vérification des variables d'environnement
echo ""
echo "🔧 Vérification des variables d'environnement..."

required_vars=(
    "DOMAIN"
    "POSTGRES_PASSWORD"
    "PGADMIN_DEFAULT_PASSWORD"
    "GF_SECURITY_ADMIN_PASSWORD"
    "NEXTCLOUD_ADMIN_PASSWORD"
    "MYSQL_ROOT_PASSWORD"
    "LETSENCRYPT_EMAIL"
)

source .env 2>/dev/null || { echo "❌ Impossible de charger .env"; exit 1; }

for var in "${required_vars[@]}"; do
    if [ -n "${!var}" ] && [ "${!var}" != "yourdomain.com" ] && [[ "${!var}" != *"changez_ce_mot_de_passe"* ]]; then
        echo "✅ $var configuré"
    else
        echo "❌ $var - NON CONFIGURÉ OU VALEUR PAR DÉFAUT"
        exit 1
    fi
done

# Vérification de la configuration Nginx
echo ""
echo "🌐 Vérification de la configuration Nginx..."

if grep -q "yourdomain.com" nginx/conf.d/default.conf; then
    echo "❌ nginx/conf.d/default.conf contient encore 'yourdomain.com'"
    echo "   Remplacez par votre vrai domaine"
    exit 1
else
    echo "✅ Configuration Nginx mise à jour avec votre domaine"
fi

# Test de syntaxe docker compose
echo ""
echo "🐳 Validation docker compose..."

if docker compose config > /dev/null 2>&1; then
    echo "✅ docker compose.yml valide"
else
    echo "❌ docker compose.yml invalide"
    docker compose config
    exit 1
fi

# Vérification DNS (optionnel)
echo ""
echo "🌍 Test de résolution DNS..."

if command -v nslookup > /dev/null; then
    if nslookup $DOMAIN > /dev/null 2>&1; then
        echo "✅ $DOMAIN résolu correctement"
    else
        echo "⚠️  $DOMAIN ne résout pas - Vérifiez votre configuration DNS"
    fi
else
    echo "⚠️  nslookup non disponible - Impossible de tester DNS"
fi

# Vérification des ports
echo ""
echo "🔌 Vérification des ports..."

if command -v ss > /dev/null || command -v netstat > /dev/null; then
    ports=(80 443)
    for port in "${ports[@]}"; do
        if ss -tln 2>/dev/null | grep -q ":$port " || netstat -tln 2>/dev/null | grep -q ":$port "; then
            echo "⚠️  Port $port déjà utilisé"
        else
            echo "✅ Port $port libre"
        fi
    done
else
    echo "⚠️  Impossible de vérifier les ports (ss/netstat non disponibles)"
fi

echo ""
echo "📋 Résumé de la validation:"
echo ""
echo "✅ Configuration de base validée"
echo "✅ Variables d'environnement configurées"
echo "✅ Configuration Nginx adaptée"
echo "✅ docker compose.yml valide"
echo ""
echo "🚀 Votre configuration semble prête pour le déploiement !"
echo ""
echo "Prochaines étapes:"
echo "1. Assurez-vous que votre DNS pointe vers ce serveur"
echo "2. Ouvrez les ports 80 et 443 sur votre routeur/firewall"
echo "3. Lancez le déploiement avec: ./deploy.sh"
echo ""