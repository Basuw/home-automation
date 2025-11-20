#!/bin/bash

set -e

if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

if [ -f subdomains.env ]; then
    export $(cat subdomains.env | grep -v '^#' | xargs)
fi

MODE=${1:-"production"}

DOMAIN=${DOMAIN:-"yourdomain.com"}
SUBDOMAIN_API=${SUBDOMAIN_API:-"api"}
SUBDOMAIN_GRAFANA=${SUBDOMAIN_GRAFANA:-"grafana"}
SUBDOMAIN_PHPMYADMIN=${SUBDOMAIN_PHPMYADMIN:-"phpmyadmin"}
SUBDOMAIN_PORTAINER=${SUBDOMAIN_PORTAINER:-"portainer"}
SUBDOMAIN_NEXTCLOUD=${SUBDOMAIN_NEXTCLOUD:-"cloud"}

OUTPUT_FILE="nginx/conf.d/default.conf"

echo "🔧 Génération de la configuration Nginx..."

if [ "$MODE" = "dev" ]; then
    DOMAIN_BASE="localhost"
    SSL_CERT="/etc/nginx/ssl/selfsigned.crt"
    SSL_KEY="/etc/nginx/ssl/selfsigned.key"
else
    DOMAIN_BASE="$DOMAIN"
    SSL_CERT="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
    SSL_KEY="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
fi

cat > "$OUTPUT_FILE" << EOF
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
    ["$SUBDOMAIN_API"]="api:8000|api|20|20"
    ["$SUBDOMAIN_GRAFANA"]="grafana:3000|general|50|10|websocket"
    ["$SUBDOMAIN_PHPMYADMIN"]="phpmyadmin:80|login|5|5|csp"
    ["$SUBDOMAIN_PORTAINER"]="portainer:9000|general|50|10|websocket"
    ["$SUBDOMAIN_NEXTCLOUD"]="nextcloud:80|general|100|20|nextcloud"
)

for subdomain in "${!SERVICES[@]}"; do
    IFS='|' read -r proxy_pass rate_zone burst conn_limit features <<< "${SERVICES[$subdomain]}"
    
    cat >> "$OUTPUT_FILE" << EOF
server {
    listen 443 ssl http2;
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

    cat >> "$OUTPUT_FILE" << EOF

    location / {
        proxy_pass http://${proxy_pass};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
EOF

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
}

EOF
done

cat >> "$OUTPUT_FILE" << EOF
server {
    listen 443 ssl http2 default_server;
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
        return 200 "Home Automation Services:\\n\\n- https://${SUBDOMAIN_API}.${DOMAIN_BASE}\\n- https://${SUBDOMAIN_GRAFANA}.${DOMAIN_BASE}\\n- https://${SUBDOMAIN_PHPMYADMIN}.${DOMAIN_BASE}\\n- https://${SUBDOMAIN_PORTAINER}.${DOMAIN_BASE}\\n- https://${SUBDOMAIN_NEXTCLOUD}.${DOMAIN_BASE}\\n";
        add_header Content-Type text/plain;
    }
}
EOF

echo "✅ Configuration Nginx générée: $OUTPUT_FILE"
