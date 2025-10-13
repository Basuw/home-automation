#!/bin/bash

# Script de maintenance pour Home Automation System
# Usage: ./maintenance.sh [backup|restore|update|logs|status|ssl-renew]

set -e

ACTION=${1:-"status"}
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

case $ACTION in
    "backup")
        echo "🔄 Sauvegarde en cours..."
        mkdir -p $BACKUP_DIR
        
        # Sauvegarde PostgreSQL
        echo "📊 Sauvegarde base de données PostgreSQL..."
        docker compose exec -T db pg_dump -U admin domotic > $BACKUP_DIR/postgres_$DATE.sql
        
        # Sauvegarde Nextcloud
        echo "☁️ Sauvegarde données Nextcloud..."
        docker compose run --rm -v nextcloud_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine \
            tar czf /backup/nextcloud_$DATE.tar.gz /data
        
        # Sauvegarde Grafana
        echo "📈 Sauvegarde configuration Grafana..."
        docker compose run --rm -v grafana_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine \
            tar czf /backup/grafana_$DATE.tar.gz /data
        
        echo "✅ Sauvegarde terminée dans $BACKUP_DIR/"
        ;;
        
    "restore")
        BACKUP_FILE=$2
        if [ -z "$BACKUP_FILE" ]; then
            echo "❌ Usage: ./maintenance.sh restore <backup_file>"
            exit 1
        fi
        
        echo "🔄 Restauration depuis $BACKUP_FILE..."
        
        if [[ $BACKUP_FILE == *"postgres"* ]]; then
            echo "📊 Restauration PostgreSQL..."
            docker compose exec -T db psql -U admin -d domotic < $BACKUP_FILE
        elif [[ $BACKUP_FILE == *"nextcloud"* ]]; then
            echo "☁️ Restauration Nextcloud..."
            docker compose down nextcloud
            docker volume rm $(docker compose config --services | grep nextcloud)_nextcloud_data || true
            docker compose run --rm -v nextcloud_data:/data -v $(pwd)/backups:/backup alpine \
                tar xzf /backup/$(basename $BACKUP_FILE) -C /
            docker compose up -d nextcloud
        elif [[ $BACKUP_FILE == *"grafana"* ]]; then
            echo "📈 Restauration Grafana..."
            docker compose down grafana
            docker volume rm $(docker compose config --services | grep grafana)_grafana_data || true
            docker compose run --rm -v grafana_data:/data -v $(pwd)/backups:/backup alpine \
                tar xzf /backup/$(basename $BACKUP_FILE) -C /
            docker compose up -d grafana
        fi
        
        echo "✅ Restauration terminée"
        ;;
        
    "update")
        echo "🔄 Mise à jour des services..."
        
        # Sauvegarde avant mise à jour
        echo "💾 Sauvegarde automatique avant mise à jour..."
        $0 backup
        
        # Arrêt des services
        echo "🛑 Arrêt des services..."
        docker compose down
        
        # Mise à jour des images
        echo "📦 Téléchargement des nouvelles images..."
        docker compose pull
        
        # Nettoyage
        echo "🧹 Nettoyage des anciennes images..."
        docker image prune -f
        
        # Redémarrage
        echo "🚀 Redémarrage des services..."
        docker compose up -d
        
        echo "✅ Mise à jour terminée"
        ;;
        
    "logs")
        SERVICE=$2
        if [ -z "$SERVICE" ]; then
            echo "📋 Logs de tous les services:"
            docker compose logs --tail=50 -f
        else
            echo "📋 Logs du service $SERVICE:"
            docker compose logs --tail=50 -f $SERVICE
        fi
        ;;
        
    "status")
        echo "📊 État des services Home Automation:"
        echo ""
        
        # Statut des conteneurs
        docker compose ps
        echo ""
        
        # Utilisation des ressources
        echo "💾 Utilisation des ressources:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
        echo ""
        
        # Espace disque des volumes
        echo "💿 Espace disque des volumes:"
        docker system df -v | grep -A 20 "Local Volumes:"
        echo ""
        
        # Test des services web
        echo "🌐 Test des services web:"
        DOMAIN=$(grep DOMAIN .env | cut -d'=' -f2)
        services=("api" "grafana" "phpmyadmin" "portainer" "nextcloud")
        
        for service in "${services[@]}"; do
            if curl -sf "https://$service.$DOMAIN" > /dev/null 2>&1; then
                echo "✅ $service.$DOMAIN - Accessible"
            else
                echo "❌ $service.$DOMAIN - Inaccessible"
            fi
        done
        ;;
        
    "ssl-renew")
        echo "🔐 Renouvellement des certificats SSL..."
        
        # Renouvellement
        docker compose run --rm certbot renew
        
        # Redémarrage Nginx
        docker compose restart nginx
        
        # Vérification
        DOMAIN=$(grep DOMAIN .env | cut -d'=' -f2)
        echo "🔍 Vérification du certificat pour $DOMAIN..."
        echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | \
            openssl x509 -noout -dates
        
        echo "✅ Renouvellement SSL terminé"
        ;;
        
    "clean")
        echo "🧹 Nettoyage du système..."
        
        # Arrêt de tous les services
        echo "🛑 Arrêt des services..."
        docker compose down
        
        # Nettoyage Docker
        echo "🗑️ Nettoyage des images inutilisées..."
        docker image prune -a -f
        
        echo "🗑️ Nettoyage des volumes inutilisés..."
        docker volume prune -f
        
        echo "🗑️ Nettoyage du cache Docker..."
        docker system prune -f
        
        # Redémarrage
        echo "🚀 Redémarrage des services..."
        docker compose up -d
        
        echo "✅ Nettoyage terminé"
        ;;
        
    *)
        echo "Usage: $0 [backup|restore|update|logs|status|ssl-renew|clean]"
        echo ""
        echo "Commandes disponibles:"
        echo "  backup     - Sauvegarde tous les services"
        echo "  restore    - Restaure depuis une sauvegarde"
        echo "  update     - Met à jour tous les services"
        echo "  logs       - Affiche les logs (optionnel: nom du service)"
        echo "  status     - Affiche l'état du système"
        echo "  ssl-renew  - Renouvelle les certificats SSL"
        echo "  clean      - Nettoie le système Docker"
        echo ""
        echo "Exemples:"
        echo "  $0 status"
        echo "  $0 logs nginx"
        echo "  $0 backup"
        echo "  $0 restore backups/postgres_20231101_120000.sql"
        ;;
esac