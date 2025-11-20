# Système Domotique - Home Automation

Système complet de domotique avec surveillance, gestion de données et interface web sécurisée.

## 🏗️ Architecture

- **API FastAPI** : API REST pour le contrôle domotique
- **Listener Service** : Écoute et traitement des données capteurs MQTT
- **Base de données PostgreSQL** : Stockage des données
- **MQTT Mosquitto** : Messagerie IoT
- **Grafana** : Visualisation et monitoring
- **phpMyAdmin** : Gestion base de données MySQL
- **Portainer** : Gestion conteneurs Docker
- **Nextcloud** : Stockage et partage de fichiers
- **Nginx** : Reverse proxy avec SSL Let's Encrypt

## 🌐 URLs des services

Tous les services sont accessibles via votre domaine (configuré dans `.env`) :

- **Principal** : https://your-domain.com
- **API** : https://your-domain.com/api
- **Grafana** : https://your-domain.com/grafana
- **phpMyAdmin** : https://your-domain.com/phpmyadmin
- **Portainer** : https://your-domain.com/portainer
- **Nextcloud** : https://your-domain.com/nextcloud

## 📋 Prérequis

- Docker et Docker Compose installés
- Nom de domaine configuré (DNS pointant vers votre serveur)
- Ports ouverts : 80, 443, 1883, 9001

## 🚀 Démarrage rapide

### 1. Configuration

```bash
# Copier et modifier la configuration
cp .env.example .env
# Éditer .env avec vos valeurs (domaine, mots de passe, email)
```

### 2. Déploiement automatique

```bash
# Lancer le script de déploiement
./deploy.sh
```

Le script `deploy.sh` :
- Configure automatiquement nginx avec votre domaine
- Démarre les services dans le bon ordre
- Obtient les certificats SSL Let's Encrypt
- Configure le renouvellement automatique SSL

### 3. Démarrage manuel (optionnel)

Si vous préférez contrôler chaque étape :

```bash
# 1. Services de base (bases de données)
docker compose up -d db mosquitto

# 2. Services métier
docker compose up -d api listener

# 3. Services web
docker compose up -d grafana phpmyadmin portainer nextcloud-db nextcloud

# 4. Nginx
docker compose up -d nginx
```

## 🔧 Maintenance

Utilisez le script `maintenance.sh` pour les opérations courantes :

```bash
./maintenance.sh backup   # Sauvegarde les bases de données
./maintenance.sh restore  # Restaure depuis une sauvegarde
./maintenance.sh logs     # Affiche les logs de tous les services
./maintenance.sh status   # État de tous les conteneurs
```

## 📁 Structure du projet

```
Domotic/
├── .env                    # Configuration principale
├── .env.example           # Template de configuration
├── docker-compose.yml     # Orchestration des services
├── docker-compose.override.yml # Surcharges locales
├── README.md              # Documentation
├── deploy.sh              # Script de déploiement
├── maintenance.sh         # Script de maintenance
├── api/                   # API FastAPI
├── services/              # Service listener MQTT
├── Data/                  # Scripts SQL d'initialisation
├── nginx/                 # Configuration reverse proxy
│   ├── conf.d/default.conf  # Configuration des routes
│   └── nginx.conf         # Configuration principale
├── certbot/               # Let's Encrypt
│   └── www/               # Challenge ACME
├── mosquitto/             # Configuration MQTT
└── grafana/               # Dashboards Grafana
```

## 🔍 Commandes utiles

```bash
# Status des conteneurs
docker compose ps

# Logs d'un service
docker compose logs <service>
docker compose logs -f nginx  # Suivre les logs en temps réel

# Redémarrer un service
docker compose restart <service>

# Arrêter tous les services
docker compose down

# Démarrer tous les services
docker compose up -d
```

## ⚠️ Problèmes courants

### Nginx ne démarre pas
```bash
# Vérifier la configuration nginx
docker compose exec nginx nginx -t

# Redémarrer nginx
docker compose restart nginx
```

### Services inaccessibles
```bash
# Vérifier les logs du reverse proxy
docker compose logs nginx

# Vérifier que les certificats SSL existent
ls -la certbot/conf/live/
```

### Certificats SSL expirés
Les certificats sont renouvelés automatiquement via cron.
Pour forcer un renouvellement manuel :
```bash
docker compose exec certbot certbot renew
docker compose restart nginx
```

## 🔒 Sécurité

- Tous les services utilisent HTTPS avec certificats Let's Encrypt
- Mots de passe sécurisés requis pour tous les services
- Réseau Docker isolé pour les communications internes
- Volumes persistants pour les données critiques

## 📞 Support

- Vérifiez les logs avec `docker compose logs <service>`
- Utilisez `./maintenance.sh status` pour voir l'état des services
- Consultez `.env.example` pour les variables de configuration

## 🔄 Mises à jour

```bash
# Mettre à jour les images Docker
docker compose pull

# Redémarrer avec les nouvelles images
docker compose up -d
```
