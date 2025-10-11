# Home Automation System with Nginx Reverse Proxy

## 🏠 Overview
Ce système domotique complet permet de :
- **Contrôler des LEDs RGB** à distance via une API
- **Collecter et stocker des données de capteurs** depuis un ESP32 via MQTT
- **Visualiser les données** dans des tableaux de bord Grafana
- **Gérer des fichiers cloud** avec Nextcloud
- **Administrer le système** via Portainer et PgAdmin
- **Sécuriser tous les services** derrière un reverse proxy Nginx avec SSL

Projet lié au [projet Arduino](https://github.com/Basuw/Moisture_termic_sensor-Arduino).

## 🏗️ Architecture
Le système comprend les composants suivants :

### Services de base
- **ESP32** : Capteurs et LEDs, communication MQTT
- **API FastAPI** : Contrôle des LEDs via MQTT
- **MQTT Broker (Mosquitto)** : Communication entre ESP32 et services backend
- **Service Listener** : Écoute les données capteurs et les stocke en base
- **PostgreSQL** : Base de données principale
- **Grafana** : Tableaux de bord et monitoring

### Services cloud et administration
- **Nextcloud** : Stockage cloud personnel et synchronisation de fichiers
- **Portainer** : Interface web pour gérer les conteneurs Docker
- **PgAdmin** : Interface d'administration PostgreSQL

### Infrastructure réseau
- **Nginx** : Reverse proxy avec SSL/TLS automatique
- **Certbot** : Gestion automatique des certificats Let's Encrypt

## 🌐 Configuration DNS et Domaine

### Prérequis DNS
Avant de démarrer, configurez votre DNS pour pointer vers votre serveur :

```
yourdomain.com           → IP_DE_VOTRE_SERVEUR
api.yourdomain.com       → IP_DE_VOTRE_SERVEUR
grafana.yourdomain.com   → IP_DE_VOTRE_SERVEUR
pgadmin.yourdomain.com   → IP_DE_VOTRE_SERVEUR
portainer.yourdomain.com → IP_DE_VOTRE_SERVEUR
nextcloud.yourdomain.com → IP_DE_VOTRE_SERVEUR
```

### Configuration de votre routeur/box
**Important** : Redirigez uniquement les ports 80 et 443 vers votre serveur :
- Port 80 (HTTP) → IP_SERVEUR:80
- Port 443 (HTTPS) → IP_SERVEUR:443

Nginx se chargera de router le trafic vers les bons services.

## 🚀 Installation et Configuration

### 1. Prérequis
- **Docker** et **Docker Compose** installés
- **Nom de domaine** configuré
- **ESP32** avec capteurs et LEDs RGB

### 2. Configuration initiale

#### Cloner le projet
```bash
git clone https://github.com/your-repo/home-automation.git
cd home-automation/Domotic
```

#### Configurer les variables d'environnement
Éditez le fichier `.env` :
```bash
cp .env.example .env
nano .env
```

**Variables importantes à modifier :**
```env
# Votre domaine
DOMAIN=yourdomain.com

# Mots de passe sécurisés
POSTGRES_PASSWORD=votre_mot_de_passe_postgres_securise
PGADMIN_DEFAULT_PASSWORD=votre_mot_de_passe_pgadmin_securise
GF_SECURITY_ADMIN_PASSWORD=votre_mot_de_passe_grafana_securise
NEXTCLOUD_ADMIN_PASSWORD=votre_mot_de_passe_nextcloud_securise
MYSQL_ROOT_PASSWORD=votre_mot_de_passe_mysql_root_securise
MYSQL_PASSWORD=votre_mot_de_passe_mysql_nextcloud_securise

# Email pour Let's Encrypt
LETSENCRYPT_EMAIL=admin@yourdomain.com
```

#### Configurer Nginx
Remplacez `yourdomain.com` par votre domaine dans :
```bash
nano nginx/conf.d/default.conf
```

### 3. Démarrage des services

#### Premier démarrage (certificats SSL)
```bash
# Démarrer sans SSL pour obtenir les certificats
docker-compose up -d nginx certbot

# Obtenir les certificats Let's Encrypt
docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot --email your-email@domain.com --agree-tos --no-eff-email -d yourdomain.com -d api.yourdomain.com -d grafana.yourdomain.com -d pgadmin.yourdomain.com -d portainer.yourdomain.com -d nextcloud.yourdomain.com

# Redémarrer avec la configuration SSL complète
docker-compose down
docker-compose up -d
```

#### Démarrage normal
```bash
docker-compose up -d
```

## 🔗 Accès aux Services

Une fois tous les services démarrés, accédez via HTTPS :

### 🏠 Dashboard Principal
- **URL** : https://yourdomain.com
- **Service** : Grafana (tableau de bord principal)
- **Login** : admin / [GF_SECURITY_ADMIN_PASSWORD]

### 🔌 API Domotique
- **URL** : https://api.yourdomain.com
- **Documentation** : https://api.yourdomain.com/docs
- **Exemple** : `curl "https://api.yourdomain.com/setColor?r=255&g=100&b=50&brightness=80"`

### 📊 Grafana (Monitoring)
- **URL** : https://grafana.yourdomain.com
- **Login** : admin / [GF_SECURITY_ADMIN_PASSWORD]
- **Usage** : Tableaux de bord, alertes, monitoring

### 🗄️ PgAdmin (Base de données)
- **URL** : https://pgadmin.yourdomain.com
- **Login** : [PGADMIN_DEFAULT_EMAIL] / [PGADMIN_DEFAULT_PASSWORD]
- **Usage** : Administration PostgreSQL

### 🐳 Portainer (Conteneurs)
- **URL** : https://portainer.yourdomain.com
- **Premier accès** : Créer compte admin
- **Usage** : Gestion des conteneurs Docker

### ☁️ Nextcloud (Stockage Cloud)
- **URL** : https://nextcloud.yourdomain.com
- **Login** : admin / [NEXTCLOUD_ADMIN_PASSWORD]
- **Usage** : Stockage fichiers, synchronisation, calendrier, contacts

## 🔧 Configuration des Services

### Grafana
1. **Connexion à PostgreSQL** :
   - Host : `db:5432`
   - Database : `domotic`
   - User : `admin`
   - Password : [POSTGRES_PASSWORD]

2. **Import de dashboards** :
   - Créer des dashboards pour vos données de capteurs
   - Configurer des alertes

### Nextcloud
1. **Premier accès** : Assistant de configuration automatique
2. **Recommandations** :
   - Configurer la sauvegarde
   - Installer des applications (Calendar, Contacts, Notes)
   - Configurer la synchronisation mobile

### PgAdmin
1. **Ajouter le serveur PostgreSQL** :
   - Name : `Domotic DB`
   - Host : `db`
   - Port : `5432`
   - Username : `admin`
   - Password : [POSTGRES_PASSWORD]

### Portainer
1. **Configuration initiale** : Compte admin au premier accès
2. **Connexion Docker** : Automatique via socket

## 🔒 Sécurité

### Certificats SSL
- **Renouvellement automatique** : Configuré via cron
- **Grade SSL** : A+ (test sur SSL Labs)
- **Protocoles** : TLS 1.2 et 1.3 uniquement

### Pare-feu recommandé
```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP (redirection)
sudo ufw allow 443   # HTTPS
sudo ufw enable
```

### Bonnes pratiques
- Changez tous les mots de passe par défaut
- Activez 2FA sur Nextcloud
- Surveillez les logs Nginx
- Sauvegardez régulièrement les données

## 📁 Structure du Projet
```
home-automation/
├── Domotic/
│   ├── api/                    # API FastAPI
│   ├── services/               # Service listener MQTT
│   ├── Data/                   # Scripts SQL
│   ├── mosquitto/              # Configuration MQTT
│   ├── nginx/                  # Configuration Nginx
│   │   ├── conf.d/            # Virtual hosts
│   │   ├── ssl/               # Certificats SSL
│   │   └── nginx.conf         # Configuration principale
│   ├── certbot/               # Let's Encrypt
│   │   ├── conf/              # Certificats
│   │   └── www/               # Challenge ACME
│   ├── docker-compose.yml     # Configuration des services
│   └── .env                   # Variables d'environnement
└── README.md
```

## 🔄 Maintenance

### Renouvellement SSL automatique
Ajoutez au crontab :
```bash
0 3 * * * docker-compose -f /path/to/docker-compose.yml run --rm certbot renew && docker-compose -f /path/to/docker-compose.yml restart nginx
```

### Sauvegarde
```bash
# Script de sauvegarde
docker-compose exec db pg_dump -U admin domotic > backup_$(date +%Y%m%d_%H%M%S).sql
docker-compose run --rm -v nextcloud_data:/data alpine tar czf /backup/nextcloud_$(date +%Y%m%d_%H%M%S).tar.gz /data
```

### Mise à jour
```bash
# Mettre à jour les images
docker-compose pull
docker-compose up -d
```

### Monitoring des logs
```bash
# Logs nginx
docker-compose logs -f nginx

# Logs Nextcloud
docker-compose logs -f nextcloud

# Logs de tous les services
docker-compose logs -f
```

## 🐛 Dépannage

### Services non accessibles
1. Vérifiez DNS : `nslookup api.yourdomain.com`
2. Vérifiez certificats SSL : `docker-compose logs certbot`
3. Vérifiez configuration Nginx : `docker-compose exec nginx nginx -t`

### Problèmes SSL
```bash
# Regénérer les certificats
docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot --force-renewal -d yourdomain.com
```

### Base de données
```bash
# Accès direct PostgreSQL
docker-compose exec db psql -U admin -d domotic
```

## 📈 Performances et Optimisation

### Monitoring des ressources
- Utilisez Portainer pour surveiller l'utilisation CPU/RAM
- Grafana peut monitorer les métriques système
- Vérifiez les logs Nginx pour les performances

### Optimisations Nextcloud
- Configurez le cache Redis si nécessaire
- Optimisez PHP-FPM selon vos besoins
- Configurez la compression

## 🤝 Contribution
Les contributions sont les bienvenues ! Merci de :
1. Fork le projet
2. Créer une branche feature
3. Commiter vos changements
4. Pousser vers la branche
5. Ouvrir une Pull Request

## 📄 License
Ce projet est sous licence MIT.

## 👨‍💻 Auteur
Bastien Jacquelin

---

**Note importante** : Remplacez `yourdomain.com` par votre vrai domaine dans tous les fichiers de configuration avant le déploiement.
