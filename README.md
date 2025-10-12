# Home Automation System with Nginx Reverse Proxy

## ## ⚡ Quick Start (TL;DR)

Pour les impatients, voici le démarrage rapide en 4 commandes :

```bash
# 1. Cloner et configurer
git clone https://github.com/Basuw/home-automation.git
cd home-automation/Domotic
cp .env.example .env
nano .env  # Configurez DOMAIN, les mots de passe, et LETSENCRYPT_EMAIL

# 2. Valider la configuration
chmod +x *.sh
./validate.sh

# 3. Déployer (tout automatique !)
./deploy.sh production

# 4. C'est prêt ! �
# Accédez à https://votre-domaine.fr
```

**⚠️ Important** : Avant de lancer ces commandes, assurez-vous que :
- Votre DNS pointe vers votre serveur
- Les ports 80 et 443 sont redirigés vers votre serveur
- Vous avez modifié le fichier `.env` avec vos vraies valeurs

## 🛠️ Scripts d'Administration

Le projet inclut 4 scripts bash pour simplifier le déploiement et la maintenance :

| Script | Description | Usage |
|--------|-------------|-------|
| `validate.sh` | Valide la configuration avant déploiement | `./validate.sh` |
| `deploy.sh` | Déploiement automatique complet avec SSL | `./deploy.sh [production\|staging]` |
| `maintenance.sh` | Toutes les opérations de maintenance | `./maintenance.sh [backup\|restore\|update\|logs\|status\|ssl-renew\|clean]` |
| `cleanup.sh` | Nettoyage des conteneurs avant redéploiement | `./cleanup.sh` |

**💡 Astuce** : Ces scripts automatisent toutes les tâches complexes. Utilisez-les pour gagner du temps !

**📚 Documentation détaillée** : Consultez [SCRIPTS.md](Domotic/SCRIPTS.md) pour le guide complet de chaque script avec exemples et workflows.Ce système domotique complet permet de :
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
jacquelin63.freeboxos.fr           → IP_DE_VOTRE_SERVEUR
api.jacquelin63.freeboxos.fr       → IP_DE_VOTRE_SERVEUR
grafana.jacquelin63.freeboxos.fr   → IP_DE_VOTRE_SERVEUR
pgadmin.jacquelin63.freeboxos.fr   → IP_DE_VOTRE_SERVEUR
portainer.jacquelin63.freeboxos.fr → IP_DE_VOTRE_SERVEUR
nextcloud.jacquelin63.freeboxos.fr → IP_DE_VOTRE_SERVEUR
```

### Configuration de votre routeur/box
**Important** : Redirigez uniquement les ports 80 et 443 vers votre serveur :
- Port 80 (HTTP) → IP_SERVEUR:80
- Port 443 (HTTPS) → IP_SERVEUR:443

Nginx se chargera de router le trafic vers les bons services.

## �️ Scripts d'Administration

Le projet inclut 4 scripts bash pour simplifier le déploiement et la maintenance :

| Script | Description | Usage |
|--------|-------------|-------|
| `validate.sh` | Valide la configuration avant déploiement | `./validate.sh` |
| `deploy.sh` | Déploiement automatique complet avec SSL | `./deploy.sh [production\|staging]` |
| `maintenance.sh` | Toutes les opérations de maintenance | `./maintenance.sh [backup\|restore\|update\|logs\|status\|ssl-renew\|clean]` |
| `cleanup.sh` | Nettoyage des conteneurs avant redéploiement | `./cleanup.sh` |

**💡 Astuce** : Ces scripts automatisent toutes les tâches complexes. Utilisez-les pour gagner du temps !

## �🚀 Installation et Configuration

### 1. Prérequis
- **Docker** et **Docker Compose** installés
- **Nom de domaine** configuré (ou sous-domaine Freebox)
- **ESP32** avec capteurs et LEDs RGB
- **Accès SSH** au serveur (pour Linux/Mac) ou **Git Bash** (pour Windows)

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
DOMAIN=jacquelin63.freeboxos.fr

# Mots de passe sécurisés
POSTGRES_PASSWORD=votre_mot_de_passe_postgres_securise
PGADMIN_DEFAULT_PASSWORD=votre_mot_de_passe_pgadmin_securise
GF_SECURITY_ADMIN_PASSWORD=votre_mot_de_passe_grafana_securise
NEXTCLOUD_ADMIN_PASSWORD=votre_mot_de_passe_nextcloud_securise
MYSQL_ROOT_PASSWORD=votre_mot_de_passe_mysql_root_securise
MYSQL_PASSWORD=votre_mot_de_passe_mysql_nextcloud_securise

# Email pour Let's Encrypt (peut être votre Gmail personnel)
LETSENCRYPT_EMAIL=votre-email@gmail.com
```

**📧 Note importante sur LETSENCRYPT_EMAIL** :
- **Pas besoin d'utiliser un email avec votre domaine** - votre Gmail personnel fonctionne parfaitement !
- Cet email sert uniquement pour les notifications Let's Encrypt :
  - Alertes si vos certificats sont sur le point d'expirer
  - Notifications de sécurité critiques
  - Récupération de compte
- **Utilisez une adresse que vous consultez régulièrement**

#### Configurer Nginx
Remplacez `jacquelin63.freeboxos.fr` par votre domaine dans :
```bash
nano nginx/conf.d/default.conf
```

### 3. Démarrage des services

Le projet inclut plusieurs scripts bash pour faciliter le déploiement et la maintenance.

#### ⚠️ PREMIER DÉMARRAGE - Méthode Recommandée (Automatisée)

**Étape 1 : Validation de la configuration**
```bash
cd Domotic

# Rendre les scripts exécutables
chmod +x *.sh

# Valider votre configuration avant le déploiement
./validate.sh
```

Le script `validate.sh` vérifie :
- ✅ Présence de tous les fichiers requis
- ✅ Configuration des variables d'environnement
- ✅ Syntaxe du `docker compose.yml`
- ✅ Résolution DNS de votre domaine
- ✅ Disponibilité des ports 80 et 443

**Étape 2 : Déploiement automatique**
```bash
# Déploiement en production (certificats SSL réels)
./deploy.sh production

# OU Déploiement en staging (certificats de test - recommandé pour les tests)
./deploy.sh staging
```

Le script `deploy.sh` s'occupe automatiquement de :
- 📁 Création des dossiers nécessaires
- 🔒 Configuration des permissions
- 🔧 Adaptation de la configuration Nginx à votre domaine
- 🗄️ Démarrage progressif des bases de données
- 🚀 Démarrage de tous les services
- 🔐 Obtention des certificats SSL Let's Encrypt
- ✅ Vérification de l'accessibilité de tous les services
- ⏰ Configuration du renouvellement automatique SSL

**Le déploiement se fait en 3 phases :**
1. **Phase 1** : Démarrage des bases de données (PostgreSQL, MySQL)
2. **Phase 2** : Démarrage des services applicatifs (API, Grafana, etc.)
3. **Phase 3** : Configuration SSL et démarrage de Nginx

#### 🔄 PREMIER DÉMARRAGE - Méthode Manuelle (si besoin)

Si vous préférez contrôler chaque étape :

**Étape 1 : Nettoyage (si redéploiement)**
```bash
cd Domotic
./cleanup.sh
```

**Étape 2 : Préparation**
```bash
# Créer les dossiers nécessaires
mkdir -p certbot/conf certbot/www nginx/ssl mosquitto/data mosquitto/log

# Configurer les permissions
chmod -R 755 nginx/ certbot/
chmod -R 777 mosquitto/data mosquitto/log
```

**Étape 3 : Démarrer les services de base**
```bash
# Démarrer les bases de données
docker compose up -d db nextcloud-db

# Attendre 30 secondes que les BD soient prêtes
sleep 30

# Démarrer les services applicatifs
docker compose up -d api listener mosquitto pgadmin grafana portainer nextcloud

# Attendre 20 secondes
sleep 20
```

**Étape 4 : Configuration SSL**
```bash
# Démarrer Nginx
docker compose up -d nginx

# Attendre 10 secondes
sleep 10

# Obtenir les certificats (remplacez par vos valeurs)
docker compose run --rm certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email votre-email@gmail.com \
  --agree-tos \
  --no-eff-email \
  -d votre-domaine.fr \
  -d api.votre-domaine.fr \
  -d grafana.votre-domaine.fr \
  -d pgadmin.votre-domaine.fr \
  -d portainer.votre-domaine.fr \
  -d nextcloud.votre-domaine.fr

# Redémarrer Nginx avec SSL
docker compose restart nginx
```

#### 🔄 Démarrage normal (après configuration initiale)
Une fois les certificats obtenus et la configuration complète :
```bash
cd Domotic
docker compose up -d
```

#### 🆘 Dépannage du premier démarrage

**Problème : Certbot échoue avec "Connection refused" ou "404"**
- Vérifiez que Nginx est bien démarré : `docker compose ps nginx`
- Vérifiez que le port 80 est accessible depuis Internet
- Testez l'accès au dossier ACME : `curl http://votre-domaine.fr/.well-known/acme-challenge/`

**Problème : "too many certificates already issued"**
- Let's Encrypt a des limites de taux (rate limits)
- Attendez une semaine ou utilisez un autre (sous-)domaine
- En développement, utilisez l'option `--staging` pour tester

**Problème : Nginx ne démarre pas après ajout du SSL**
```bash
# Vérifier la configuration Nginx
docker compose exec nginx nginx -t

# Vérifier que les certificats existent
docker compose exec nginx ls -la /etc/letsencrypt/live/votre-domaine/

# Voir les logs détaillés
docker compose logs nginx
```

**Problème : Les certificats existent mais sont invalides**
```bash
# Forcer le renouvellement
docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --force-renewal \
  --email votre-email@domain.com \
  --agree-tos \
  -d votre-domaine.fr
```

## 🔗 Accès aux Services

Une fois tous les services démarrés, accédez via HTTPS :

### 🏠 Dashboard Principal
- **URL** : https://jacquelin63.freeboxos.fr
- **Service** : Grafana (tableau de bord principal)
- **Login** : admin / [GF_SECURITY_ADMIN_PASSWORD]

### 🔌 API Domotique
- **URL** : https://api.jacquelin63.freeboxos.fr
- **Documentation** : https://api.jacquelin63.freeboxos.fr/docs
- **Exemple** : `curl "https://api.jacquelin63.freeboxos.fr/setColor?r=255&g=100&b=50&brightness=80"`

### 📊 Grafana (Monitoring)
- **URL** : https://grafana.jacquelin63.freeboxos.fr
- **Login** : admin / [GF_SECURITY_ADMIN_PASSWORD]
- **Usage** : Tableaux de bord, alertes, monitoring

### 🗄️ PgAdmin (Base de données)
- **URL** : https://pgadmin.jacquelin63.freeboxos.fr
- **Login** : [PGADMIN_DEFAULT_EMAIL] / [PGADMIN_DEFAULT_PASSWORD]
- **Usage** : Administration PostgreSQL

### 🐳 Portainer (Conteneurs)
- **URL** : https://portainer.jacquelin63.freeboxos.fr
- **Premier accès** : Créer compte admin
- **Usage** : Gestion des conteneurs Docker

### ☁️ Nextcloud (Stockage Cloud)
- **URL** : https://nextcloud.jacquelin63.freeboxos.fr
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
│   ├── api/                    # API FastAPI pour contrôle RGB
│   ├── services/               # Service listener MQTT
│   ├── Data/                   # Scripts SQL d'initialisation
│   ├── mosquitto/              # Configuration MQTT Broker
│   ├── nginx/                  # Configuration Nginx
│   │   ├── conf.d/            # Virtual hosts (sous-domaines)
│   │   ├── ssl/               # Certificats SSL Let's Encrypt
│   │   └── nginx.conf         # Configuration principale
│   ├── certbot/               # Let's Encrypt
│   │   ├── conf/              # Certificats et clés
│   │   └── www/               # Challenge ACME HTTP-01
│   ├── docker-compose.yml     # Configuration des services
│   ├── .env                   # Variables d'environnement (à créer)
│   │
│   ├── 🛠️ Scripts d'administration
│   ├── validate.sh            # Validation de configuration
│   ├── deploy.sh              # Déploiement automatique
│   ├── maintenance.sh         # Maintenance (backup, update, logs...)
│   ├── cleanup.sh             # Nettoyage avant redéploiement
│   └── SCRIPTS.md             # Documentation détaillée des scripts
│
└── README.md                   # Ce fichier
```

## 🔄 Maintenance

Le script `maintenance.sh` automatise toutes les tâches courantes de maintenance.

### Vérifier l'état du système
```bash
cd Domotic
./maintenance.sh status
```

Affiche :
- 📊 État de tous les conteneurs
- 💾 Utilisation CPU/RAM de chaque service
- 💿 Espace disque des volumes Docker
- 🌐 Accessibilité des services web

### Sauvegarde
```bash
# Sauvegarde complète (PostgreSQL, Nextcloud, Grafana)
./maintenance.sh backup

# Les sauvegardes sont stockées dans ./backups/
# Format: postgres_YYYYMMDD_HHMMSS.sql
#         nextcloud_YYYYMMDD_HHMMSS.tar.gz
#         grafana_YYYYMMDD_HHMMSS.tar.gz
```

### Restauration
```bash
# Restaurer depuis une sauvegarde
./maintenance.sh restore backups/postgres_20231101_120000.sql
./maintenance.sh restore backups/nextcloud_20231101_120000.tar.gz
./maintenance.sh restore backups/grafana_20231101_120000.tar.gz
```

### Mise à jour des services
```bash
# Mise à jour automatique avec sauvegarde préalable
./maintenance.sh update
```

Le script effectue automatiquement :
1. 💾 Sauvegarde avant mise à jour
2. 🛑 Arrêt des services
3. 📦 Téléchargement des nouvelles images
4. 🧹 Nettoyage des anciennes images
5. 🚀 Redémarrage des services

### Renouvellement SSL
```bash
# Renouveler les certificats SSL manuellement
./maintenance.sh ssl-renew
```

**Note** : Le renouvellement automatique est déjà configuré par le script `deploy.sh` (crontab à 3h du matin).

### Consulter les logs
```bash
# Logs de tous les services
./maintenance.sh logs

# Logs d'un service spécifique
./maintenance.sh logs nginx
./maintenance.sh logs api
./maintenance.sh logs grafana
```

### Nettoyage du système
```bash
# Nettoyer les images et volumes inutilisés
./maintenance.sh clean
```

### Méthode manuelle (si nécessaire)
```bash
# Sauvegarde manuelle PostgreSQL
docker compose exec db pg_dump -U admin domotic > backup_$(date +%Y%m%d_%H%M%S).sql

# Sauvegarde manuelle Nextcloud
docker compose run --rm -v nextcloud_data:/data alpine tar czf /backup/nextcloud_$(date +%Y%m%d_%H%M%S).tar.gz /data

# Mise à jour manuelle
docker compose pull
docker compose up -d

# Logs manuels
docker compose logs -f nginx
docker compose logs -f
```

## 🐛 Dépannage

**📖 Guide complet** : Consultez [TROUBLESHOOTING.md](Domotic/TROUBLESHOOTING.md) pour des solutions détaillées à tous les problèmes courants.

### Problèmes Fréquents - Solutions Rapides

#### 🔐 Certificats SSL ne s'obtiennent pas
```bash
# 1. Vérifier DNS
nslookup votre-domaine.fr

# 2. Tester en staging
./cleanup.sh
./deploy.sh staging

# 3. Si OK, déployer en production
./cleanup.sh
./deploy.sh production
```

#### 🔴 Un service ne démarre pas
```bash
# Voir les logs du service problématique
docker compose logs <service>

# Exemples
docker compose logs api
docker compose logs db
docker compose logs mosquitto
```

#### 🌐 Service web inaccessible (404/502)
```bash
# Vérifier que le service est démarré
docker compose ps

# Redémarrer le service et Nginx
docker compose restart <service>
docker compose restart nginx
```

#### 💾 Espace disque plein
```bash
# Nettoyer Docker
./maintenance.sh clean
```

#### 🔑 Mot de passe oublié
```bash
# Grafana
docker compose exec grafana grafana-cli admin reset-admin-password nouveaumotdepasse

# Autres services : modifier .env et recréer le conteneur
nano .env
docker compose up -d --force-recreate <service>
```

### Commandes de Diagnostic

```bash
# État complet du système
./maintenance.sh status

# Logs en temps réel
docker compose logs -f

# Logs d'un service spécifique
docker compose logs -f <service>

# Redémarrer tout
docker compose restart

# Redéploiement complet
./cleanup.sh
./deploy.sh production
```

### En Cas d'Urgence

```bash
# Sauvegarder d'abord !
./maintenance.sh backup

# Puis redéployer
./cleanup.sh
./deploy.sh production
```

**💡 Pour plus de détails** : Voir [TROUBLESHOOTING.md](Domotic/TROUBLESHOOTING.md)

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

## � Résumé des Commandes Essentielles

### Premier Déploiement
```bash
./validate.sh              # 1️⃣ Valider la config
./deploy.sh production     # 2️⃣ Déployer tout
```

### Maintenance Courante
```bash
./maintenance.sh status    # Vérifier l'état
./maintenance.sh backup    # Sauvegarder
./maintenance.sh logs      # Consulter les logs
./maintenance.sh update    # Mettre à jour
```

### En Cas de Problème
```bash
./maintenance.sh logs <service>  # Déboguer
./cleanup.sh                     # Nettoyer
./deploy.sh production           # Redéployer
```

### Commandes Docker Utiles
```bash
docker compose ps              # Voir les conteneurs
docker compose restart <srv>   # Redémarrer un service
docker compose logs -f <srv>   # Logs d'un service
docker compose down            # Arrêter tout
docker compose up -d           # Démarrer tout
```

## 🎯 Checklist de Déploiement

- [ ] DNS configuré et vérifié
- [ ] Ports 80 et 443 redirigés vers le serveur
- [ ] Docker et Docker Compose installés
- [ ] Fichier `.env` créé et configuré
- [ ] `LETSENCRYPT_EMAIL` défini (Gmail accepté !)
- [ ] Domaine remplacé dans `nginx/conf.d/default.conf`
- [ ] `./validate.sh` exécuté avec succès
- [ ] `./deploy.sh production` exécuté
- [ ] Tous les services accessibles en HTTPS
- [ ] Sauvegarde programmée (`./maintenance.sh backup`)

## �👨‍💻 Auteur
Bastien Jacquelin

## 🔗 Liens Utiles
- [📚 Documentation des scripts](Domotic/SCRIPTS.md) - Guide complet de tous les scripts
- [🆘 Guide de dépannage](Domotic/TROUBLESHOOTING.md) - Solutions aux problèmes courants
- [🔧 Projet Arduino ESP32](https://github.com/Basuw/Moisture_termic_sensor-Arduino) - Code pour les capteurs
- [🐳 Docker Documentation](https://docs.docker.com/)
- [🔒 Let's Encrypt Documentation](https://letsencrypt.org/docs/)

---

**Note importante** : Remplacez `jacquelin63.freeboxos.fr` par votre vrai domaine dans tous les fichiers de configuration avant le déploiement.
