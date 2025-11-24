#!/bin/bash

# Charger les variables d'environnement depuis .env
if [ -f .env ]; then
    while IFS='=' read -r key value; do
        # Ignorer les commentaires et lignes vides
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        # Supprimer les espaces autour de la clé
        key=$(echo "$key" | xargs)
        # Exporter la variable
        export "$key=$value"
    done < .env
fi

# Charger les variables d'environnement depuis subdomains.env
if [ -f subdomains.env ]; then
    while IFS='=' read -r key value; do
        # Ignorer les commentaires et lignes vides
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        # Supprimer les espaces autour de la clé
        key=$(echo "$key" | xargs)
        # Exporter la variable
        export "$key=$value"
    done < subdomains.env
fi

MODE=${1:-"production"}

DOMAIN=${DOMAIN:-"yourdomain.com"}
SUBDOMAIN_API=${SUBDOMAIN_API:-"api"}
SUBDOMAIN_GRAFANA=${SUBDOMAIN_GRAFANA:-"grafana"}
SUBDOMAIN_PHPMYADMIN=${SUBDOMAIN_PHPMYADMIN:-"phpmyadmin"}
SUBDOMAIN_PORTAINER=${SUBDOMAIN_PORTAINER:-"portainer"}
SUBDOMAIN_NEXTCLOUD=${SUBDOMAIN_NEXTCLOUD:-"cloud"}
SUBDOMAIN_LA4LDESDOMES=${SUBDOMAIN_LA4LDESDOMES:-"la4ldesdomes"}
SUBDOMAIN_CAPITALOT=${SUBDOMAIN_CAPITALOT:-"capitalot"}

if [ "$MODE" = "dev" ]; then
    OUTPUT_FILE="nginx/conf.d/default.conf"
    DOMAIN_BASE="$DOMAIN"
    SSL_CERT="/etc/nginx/ssl/selfsigned.crt"
    SSL_KEY="/etc/nginx/ssl/selfsigned.key"
else
    OUTPUT_FILE="nginx/conf.d/default.conf"
    DOMAIN_BASE="$DOMAIN"
    SSL_CERT="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
    SSL_KEY="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
fi

echo "🔧 Génération de la configuration Nginx..."
echo "📝 Fichier de sortie: $OUTPUT_FILE"

cat > "$OUTPUT_FILE" << EOF
# Résolveur DNS pour la résolution dynamique des backends
resolver 127.0.0.11 valid=10s;
resolver_timeout 5s;

map \$http_upgrade \$connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 80;
    server_name _;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://\$host\$request_uri;
    }
}

EOF

declare -A SERVICES=(
    ["$SUBDOMAIN_API"]="domotic-api:8000|api|20|20||true"
    ["$SUBDOMAIN_GRAFANA"]="grafana:3000|general|50|10|websocket|true"
    ["$SUBDOMAIN_PHPMYADMIN"]="phpmyadmin:80|login|5|5|csp|true"
    ["$SUBDOMAIN_PORTAINER"]="portainer:9000|general|50|10|websocket|true"
    ["$SUBDOMAIN_NEXTCLOUD"]="nextcloud:80|general|100|20|nextcloud|true"
    ["$SUBDOMAIN_LA4LDESDOMES"]="fourltrophy-frontend:80|general|50|10|websocket|true"
    ["$SUBDOMAIN_CAPITALOT"]="capitalot-frontend:3001|general|50|10|websocket|true"
)

for subdomain in "${!SERVICES[@]}"; do
    IFS='|' read -r proxy_pass rate_zone burst conn_limit features optional <<< "${SERVICES[$subdomain]}"
    
    # Extraire le host et le port du proxy_pass
    backend_host="${proxy_pass%%:*}"
    backend_port="${proxy_pass##*:}"
    
    cat >> "$OUTPUT_FILE" << EOF
server {
    listen 443 ssl;
    http2 on;
    server_name ${subdomain}.${DOMAIN_BASE};

    ssl_certificate ${SSL_CERT};
    ssl_certificate_key ${SSL_KEY};

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
EOF

    if [ "$features" = "csp" ]; then
        cat >> "$OUTPUT_FILE" << EOF
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';" always;
EOF
    fi

    cat >> "$OUTPUT_FILE" << EOF

    limit_req zone=${rate_zone} burst=${burst} nodelay;
    limit_conn conn_limit_per_ip ${conn_limit};
EOF

    if [ "$features" = "nextcloud" ]; then
        cat >> "$OUTPUT_FILE" << EOF

    client_max_body_size 10G;
    client_body_timeout 300s;
EOF
    fi

    # Pour les services optionnels, utiliser une variable pour permettre la résolution DNS dynamique
    if [ "$optional" = "true" ]; then
        # Ajouter la route API pour la4ldesdomes
        if [ "$subdomain" = "$SUBDOMAIN_LA4LDESDOMES" ]; then
            cat >> "$OUTPUT_FILE" << EOF

    # Route pour l'API backend
    location /4ldesdomes-api/ {
        rewrite ^/4ldesdomes-api/(.*)\$ /\$1 break;
        set \$backend_server fourltrophy-backend;
        proxy_pass http://\$backend_server:8001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Headers CORS
        add_header 'Access-Control-Allow-Origin' 'https://la4ldesdomes.bastien-jacquelin.fr' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' '*' always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        
        # Gérer les requêtes OPTIONS (preflight CORS)
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' 'https://la4ldesdomes.bastien-jacquelin.fr' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' '*' always;
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
        
        # Gestion d'erreur gracieuse si le service est down
        proxy_intercept_errors on;
        error_page 502 503 504 = @api_unavailable;
    }

EOF
        fi
        
        cat >> "$OUTPUT_FILE" << EOF

    location / {
        # Résolution DNS dynamique pour services optionnels
        set \$backend_server ${backend_host};
        proxy_pass http://\$backend_server:${backend_port};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Gestion d'erreur gracieuse si le service est down
        proxy_intercept_errors on;
        error_page 502 503 504 = @service_unavailable;
EOF
    else
        cat >> "$OUTPUT_FILE" << EOF

    location / {
        proxy_pass http://${proxy_pass};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
EOF
    fi

    if [ "$features" = "nextcloud" ]; then
        cat >> "$OUTPUT_FILE" << EOF
        proxy_set_header X-Forwarded-Ssl on;
        
        proxy_read_timeout 3600;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        
        proxy_buffering off;
        proxy_request_buffering off;
EOF
    elif [ "$features" = "websocket" ]; then
        cat >> "$OUTPUT_FILE" << EOF
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
EOF
    elif [ "$subdomain" = "$SUBDOMAIN_PHPMYADMIN" ]; then
        cat >> "$OUTPUT_FILE" << EOF
        proxy_redirect off;
        
        proxy_read_timeout 90;
        proxy_connect_timeout 90;
EOF
    fi

    cat >> "$OUTPUT_FILE" << EOF
    }
EOF

    # Ajouter la page d'erreur pour les services optionnels
    if [ "$optional" = "true" ]; then
        # Ajouter la page d'erreur pour l'API la4ldesdomes
        if [ "$subdomain" = "$SUBDOMAIN_LA4LDESDOMES" ]; then
            cat >> "$OUTPUT_FILE" << 'EOF'

    location @api_unavailable {
        return 503 '{"status":"unavailable","message":"Service temporairement indisponible. Le service API la4ldesdomes est actuellement hors ligne ou en maintenance.","service":"la4ldesdomes-api"}';
        add_header Content-Type application/json;
    }
EOF
        fi
        
        cat >> "$OUTPUT_FILE" << EOF

    location @service_unavailable {
        return 503 '{"status":"unavailable","message":"Service temporairement indisponible. Le service ${subdomain} est actuellement hors ligne ou en maintenance.","service":"${subdomain}"}';
        add_header Content-Type application/json;
    }
EOF
    fi

    cat >> "$OUTPUT_FILE" << EOF
}

EOF
done

cat >> "$OUTPUT_FILE" << EOF
server {
    listen 443 ssl default_server;
    http2 on;
    server_name ${DOMAIN_BASE};

    ssl_certificate ${SSL_CERT};
    ssl_certificate_key ${SSL_KEY};

    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    location / {
        return 200 "Home Automation Services:\\n\\n- https://${SUBDOMAIN_API}.${DOMAIN_BASE}\\n- https://${SUBDOMAIN_GRAFANA}.${DOMAIN_BASE}\\n- https://${SUBDOMAIN_PHPMYADMIN}.${DOMAIN_BASE}\\n- https://${SUBDOMAIN_PORTAINER}.${DOMAIN_BASE}\\n- https://${SUBDOMAIN_NEXTCLOUD}.${DOMAIN_BASE}\\n\\nApplications externes:\\n- https://${SUBDOMAIN_LA4LDESDOMES}.${DOMAIN_BASE}\\n- https://${SUBDOMAIN_CAPITALOT}.${DOMAIN_BASE}\\n";
        add_header Content-Type text/plain;
    }
}
EOF

echo "✅ Configuration Nginx générée: $OUTPUT_FILE"
