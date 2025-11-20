#!/bin/bash

set -e

ACTION=${1:-"status"}
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

case $ACTION in
    "backup")
        echo "🔄 Sauvegarde..."
        mkdir -p $BACKUP_DIR
        
        docker compose exec -T db pg_dump -U admin domotic > $BACKUP_DIR/postgres_$DATE.sql
        docker compose run --rm -v nextcloud_data:/data -v $(pwd)/$BACKUP_DIR:/backup alpine \
            tar czf /backup/nextcloud_$DATE.tar.gz /data
        
        echo "✅ Sauvegarde dans $BACKUP_DIR/"
        ;;
        
    "restore")
        BACKUP_FILE=$2
        if [ -z "$BACKUP_FILE" ]; then
            echo "❌ Usage: ./maintenance.sh restore <fichier>"
            exit 1
        fi
        
        if [[ $BACKUP_FILE == *"postgres"* ]]; then
            docker compose exec -T db psql -U admin -d domotic < $BACKUP_FILE
        elif [[ $BACKUP_FILE == *"nextcloud"* ]]; then
            docker compose down nextcloud
            docker compose run --rm -v nextcloud_data:/data -v $(pwd)/backups:/backup alpine \
                tar xzf /backup/$(basename $BACKUP_FILE) -C /
            docker compose up -d nextcloud
        fi
        
        echo "✅ Restauration terminée"
        ;;
        
    "logs")
        SERVICE=$2
        if [ -z "$SERVICE" ]; then
            docker compose logs --tail=50 -f
        else
            docker compose logs --tail=50 -f $SERVICE
        fi
        ;;
        
    "status")
        echo "📊 État des services:"
        docker compose ps
        echo ""
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
        ;;
        
    *)
        echo "Usage: $0 [backup|restore|logs|status]"
        echo ""
        echo "  backup     - Sauvegarder les données"
        echo "  restore    - Restaurer depuis sauvegarde"
        echo "  logs       - Voir les logs"
        echo "  status     - État du système"
        ;;
esac
