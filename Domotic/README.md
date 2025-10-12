# Système Domotique - Home Automation

Système complet de domotique avec surveillance, gestion de données et interface web sécurisée.

## 🏗️ Architecture

- **API FastAPI** : API REST pour le contrôle domotique
- **Listener Service** : Écoute et traitement des données capteurs MQTT
- **Base de données PostgreSQL** : Stockage des données
- **MQTT Mosquitto** : Messagerie IoT
- **Grafana** : Visualisation et monitoring
- **PgAdmin** : Gestion base de données
- **Portainer** : Gestion conteneurs Docker
- **Nextcloud** : Stockage et partage de fichiers
- **Nginx** : Reverse proxy avec SSL Let's Encrypt

## 🌐 URLs des services

- **Principal (Grafana)** : https://jacquelin63.freeboxos.fr
- **API** : https://api.jacquelin63.freeboxos.fr
- **Grafana** : https://grafana.jacquelin63.freeboxos.fr
- **PgAdmin** : https://pgadmin.jacquelin63.freeboxos.fr
- **Portainer** : https://portainer.jacquelin63.freeboxos.fr
- **Nextcloud** : https://nextcloud.jacquelin63.freeboxos.fr

## 📋 Prérequis

- Docker et Docker Compose installés
- Nom de domaine configuré (DNS pointant vers votre serveur)
- Ports ouverts : 80, 443, 1883, 9001

## 🚀 Installation et démarrage

### 1. Configuration initiale

```bash
# Cloner le projet (si nécessaire)
git clone <votre-repo>
cd Domotic

# Copier et modifier la configuration
cp .env.example .env
# Éditer .env avec vos valeurs (domaine, mots de passe, email)

# Créer les répertoires nécessaires
mkdir -p nginx/ssl
mkdir -p certbot/conf
mkdir -p certbot/www
```

### 2. Configuration du fichier .env

Modifiez `.env` avec vos vraies valeurs :
- Remplacez `yourdomain.com` par votre domaine
- Changez TOUS les mots de passe par des valeurs sécurisées
- Configurez votre email pour Let's Encrypt

### 3. Première génération des certificats SSL

```bash
# Démarrer certbot pour obtenir les certificats
docker compose up -d certbot

# Obtenir les certificats SSL
docker compose exec certbot certbot certonly \
  --webroot \
  --webroot-path /var/www/certbot \
  --email votre-email@example.com \
  --agree-tos \
  --no-eff-email \
  -d jacquelin63.freeboxos.fr \
  -d api.jacquelin63.freeboxos.fr \
  -d grafana.jacquelin63.freeboxos.fr \
  -d pgladmin.jacquelin63.freeboxos.fr \
  -d portainer.jacquelin63.freeboxos.fr \
  -d nextcloud.jacquelin63.freeboxos.fr
```

### 4. Démarrage des services (ordre recommandé)

```bash
# 1. Services de base (bases de données)
docker compose up -d db mosquitto

# 2. Attendre que les DB soient prêtes
sleep 30

# 3. Services métier
docker compose up -d api listener

# 4. Services web
docker compose up -d grafana pgadmin portainer nextcloud-db
sleep 30
docker compose up -d nextcloud

# 5. Nginx avec SSL
docker compose up -d nginx
```

### 5. Démarrage complet (si certificats déjà présents)

```bash
# Si tout est déjà configuré
docker compose up -d
```

## 🔄 Gestion des certificats SSL

### Renouvellement automatique

Créer un script `renew_ssl.sh` :
```bash
#!/bin/bash
docker compose exec certbot certbot renew --quiet
docker compose restart nginx
```

### Configuration cron (Linux/Mac)
```bash
# Ajouter à crontab pour renouvellement automatique
0 2 * * 1 /chemin/vers/renew_ssl.sh
```

## 🔍 Vérification et maintenance

### Vérifier l'état des services
```bash
# Status des conteneurs
docker compose ps

# Logs des services
docker compose logs nginx
docker compose logs certbot
docker compose logs api
docker compose logs listener
```

### Tester les certificats
```bash
# Lister les certificats
docker compose exec certbot certbot certificates

# Vérifier l'expiration
openssl x509 -in nginx/ssl/live/jacquelin63.freeboxos.fr/cert.pem -text -noout | grep "Not After"
```

## 🛠️ Scripts utiles

### Maintenance générale
```bash
# Utiliser le script de maintenance
./maintenance.sh
```

### Nettoyage complet
```bash
# Arrêter tous les services
docker compose down -v

# Nettoyer les volumes (ATTENTION : supprime toutes les données)
docker volume prune

# Nettoyer les certificats
rm -rf certbot/conf/*
rm -rf nginx/ssl/*
```

### Validation de la configuration
```bash
# Valider la configuration
./validate.sh
```

## ⚠️ Problèmes courants

### Les certificats ne se génèrent pas
```bash
# Vérifier les logs certbot
docker compose logs certbot

# Vérifier la configuration DNS
nslookup jacquelin63.freeboxos.fr

# Test manuel du challenge ACME
curl http://jacquelin63.freeboxos.fr/.well-known/acme-challenge/test
```

### Nginx ne démarre pas
```bash
# Vérifier la configuration nginx
docker compose exec nginx nginx -t

# Utiliser une config temporaire sans SSL
mv nginx/conf.d/default.conf nginx/conf.d/default.conf.bak
# Créer une config HTTP simple puis redémarrer
```

### Services inaccessibles
```bash
# Vérifier les ports ouverts
netstat -tlnp | grep -E ':(80|443|1883|9001)'

# Vérifier les logs du reverse proxy
docker compose logs nginx | tail -50
```

## 📁 Structure du projet

```
Domotic/
├── .env                    # Configuration principale
├── .env.example           # Template de configuration
├── docker compose.yml     # Orchestration des services
├── docker compose.override.yml # Surcharges locales
├── README.md              # Documentation
├── api/                   # API FastAPI
├── services/              # Service listener MQTT
├── Data/                  # Scripts SQL d'initialisation
├── nginx/                 # Configuration reverse proxy
│   ├── conf.d/           # Configuration sites
│   ├── nginx.conf        # Configuration principale
│   └── ssl/              # Certificats SSL (généré)
├── certbot/              # Let's Encrypt
│   ├── conf/            # Configuration certbot
│   └── www/             # Challenge ACME
├── mosquitto/           # Configuration MQTT
│   ├── config/         # Fichiers de config
│   └── data/           # Données persistantes
├── cleanup.sh          # Script de nettoyage
├── deploy.sh           # Script de déploiement
├── maintenance.sh      # Script de maintenance
└── validate.sh         # Script de validation
```

## 🔒 Sécurité

- Tous les services utilisent HTTPS avec certificats Let's Encrypt
- Rate limiting configuré sur nginx
- Mots de passe sécurisés requis pour tous les services
- Réseau Docker isolé pour les communications internes
- Volumes persistants pour les données critiques

## 📞 Support

- Vérifiez les logs avec `docker compose logs <service>`
- Consultez la documentation des services individuels
- Utilisez les scripts de maintenance fournis

## 🔄 Mises à jour

```bash
# Mettre à jour les images Docker
docker compose pull

# Redémarrer avec les nouvelles images
docker compose up -d
```