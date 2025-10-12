# 🆘 Guide de Dépannage Rapide

Ce guide vous aide à résoudre les problèmes courants rapidement.

## 🚨 Problèmes Courants

### 1. Les certificats SSL ne s'obtiennent pas

**Symptômes** : Erreur "Failed to obtain certificate" ou "Connection refused"

**Causes possibles et solutions** :

#### ❌ DNS non configuré ou incorrect
```bash
# Vérifier la résolution DNS
nslookup votre-domaine.fr
nslookup api.votre-domaine.fr

# Si ça ne résout pas, attendez que le DNS se propage (24-48h)
# Ou vérifiez votre configuration DNS chez votre hébergeur
```

#### ❌ Port 80 non accessible depuis Internet
```bash
# Tester depuis un autre réseau (4G par exemple)
curl http://votre-domaine.fr/.well-known/acme-challenge/test

# Si erreur : vérifiez la redirection de port sur votre routeur
# Port 80 externe → Port 80 de votre serveur
```

#### ❌ Nginx ne répond pas
```bash
# Vérifier que Nginx est démarré
docker compose ps nginx

# Vérifier les logs
docker compose logs nginx

# Redémarrer si nécessaire
docker compose restart nginx
```

#### ❌ Limite de taux Let's Encrypt atteinte
```bash
# Utiliser staging pour tester
./cleanup.sh
./deploy.sh staging

# Une fois que ça fonctionne, redéployer en production
./cleanup.sh
./deploy.sh production
```

**✅ Solution générale** :
```bash
# 1. Nettoyer
./cleanup.sh

# 2. Vérifier le fichier .env
cat .env | grep DOMAIN
cat .env | grep LETSENCRYPT_EMAIL

# 3. Tester en staging d'abord
./deploy.sh staging
```

---

### 2. Un service ne démarre pas

**Symptômes** : Un conteneur est en état "Restarting" ou "Exited"

**Diagnostic** :
```bash
# Voir l'état de tous les services
docker compose ps

# Voir les logs du service problématique
docker compose logs <nom_du_service>

# Exemples
docker compose logs api
docker compose logs db
docker compose logs nginx
```

**Solutions courantes** :

#### Pour la base de données (PostgreSQL)
```bash
# Vérifier les logs
docker compose logs db

# Si problème de permissions
docker compose down
sudo chown -R 999:999 ./postgres_data
docker compose up -d db
```

#### Pour l'API ou le Listener
```bash
# Vérifier que la base de données est prête
docker compose logs db | grep "ready to accept connections"

# Vérifier les variables d'environnement
docker compose exec api env | grep DB_

# Redémarrer après la base de données
docker compose restart api listener
```

#### Pour Mosquitto (MQTT)
```bash
# Vérifier les permissions des dossiers
ls -la mosquitto/data mosquitto/log

# Corriger si nécessaire
chmod -R 777 mosquitto/data mosquitto/log
docker compose restart mosquitto
```

---

### 3. "Container name already in use"

**Symptômes** : Erreur lors du `docker compose up`

**Solution** :
```bash
# Utiliser le script de nettoyage
./cleanup.sh

# Ou manuellement
docker compose down --remove-orphans
docker rm -f $(docker ps -aq)

# Puis redémarrer
docker compose up -d
```

---

### 4. Un service web n'est pas accessible (404 ou 502)

**Symptômes** : Erreur 404, 502, ou "Service Unavailable"

**Diagnostic** :
```bash
# Vérifier que le service backend est démarré
docker compose ps

# Vérifier les logs Nginx
docker compose logs nginx | grep error

# Vérifier les logs du service concerné
docker compose logs grafana  # ou api, pgadmin, etc.
```

**Solutions** :

#### Erreur 502 Bad Gateway
```bash
# Le service backend n'est pas prêt
# Attendre qu'il démarre complètement
docker compose logs -f <service>

# Ou redémarrer le service
docker compose restart <service>
docker compose restart nginx
```

#### Erreur 404 Not Found
```bash
# Vérifier la configuration Nginx
docker compose exec nginx cat /etc/nginx/conf.d/default-paths.conf

# Vérifier que le domaine est correct
grep "server_name" nginx/conf.d/default-paths.conf

# Recharger Nginx
docker compose restart nginx
```

---

### 5. Nextcloud : "Access through untrusted domain"

**Symptômes** : Message d'erreur lors de l'accès à Nextcloud

**Solution** :
```bash
# Ajouter le domaine aux domaines de confiance
docker compose exec -u www-data nextcloud php occ config:system:set trusted_domains 2 --value=nextcloud.votre-domaine.fr

# Ou éditer directement le fichier .env et redémarrer
nano .env
# Ajouter votre domaine à NEXTCLOUD_TRUSTED_DOMAINS
docker compose restart nextcloud
```

---

### 6. Grafana : Connection à PostgreSQL échoue

**Symptômes** : "Connection refused" lors de l'ajout de la source de données

**Solution** :
```bash
# Vérifier que PostgreSQL est accessible
docker compose exec grafana ping -c 3 db

# Paramètres corrects dans Grafana :
# Host: db:5432
# Database: domotic
# User: admin
# Password: (celui dans .env POSTGRES_PASSWORD)
# SSL Mode: disable

# Vérifier les credentials
docker compose exec db psql -U admin -d domotic -c "SELECT 1"
```

---

### 7. MQTT : L'ESP32 ne se connecte pas

**Symptômes** : ESP32 ne peut pas publier/recevoir de messages

**Diagnostic** :
```bash
# Vérifier que Mosquitto est démarré
docker compose ps mosquitto

# Vérifier les logs
docker compose logs mosquitto

# Tester la connexion MQTT (nécessite mosquitto-clients)
docker compose exec mosquitto mosquitto_sub -h localhost -t "test/topic" -u admin -P <mot_de_passe>
```

**Solution** :
```bash
# Vérifier les credentials MQTT dans .env
cat .env | grep MQTT

# Redémarrer Mosquitto
docker compose restart mosquitto

# Dans votre code ESP32, utiliser :
# Host: votre-ip-serveur
# Port: 1883
# User: valeur de MQTT_USER
# Password: valeur de MQTT_PASSWORD
```

---

### 8. Espace disque plein

**Symptômes** : Services qui crashent, erreurs "No space left on device"

**Diagnostic** :
```bash
# Vérifier l'espace disque
df -h

# Vérifier l'espace utilisé par Docker
docker system df
```

**Solution** :
```bash
# Nettoyer avec le script
./maintenance.sh clean

# Ou nettoyer manuellement
docker system prune -a --volumes -f

# Supprimer les anciens logs
docker compose down
sudo rm -rf nginx_logs/*
docker compose up -d
```

---

### 9. Mot de passe oublié

#### PgAdmin
```bash
# Modifier le mot de passe dans .env
nano .env
# Changer PGADMIN_DEFAULT_PASSWORD

# Recréer le conteneur
docker compose up -d --force-recreate pgadmin
```

#### Grafana
```bash
# Réinitialiser le mot de passe admin
docker compose exec grafana grafana-cli admin reset-admin-password nouveaumotdepasse
```

#### PostgreSQL
```bash
# Se connecter en tant que postgres
docker compose exec db psql -U admin -d domotic

# Changer le mot de passe
ALTER USER admin WITH PASSWORD 'nouveau_mot_de_passe';
\q

# Mettre à jour .env
nano .env
# Changer POSTGRES_PASSWORD et DB_PASSWORD
```

---

### 10. Le script de déploiement échoue

**Symptômes** : `./deploy.sh` s'arrête avec une erreur

**Diagnostic** :
```bash
# Vérifier les logs complets
./deploy.sh production 2>&1 | tee deploy.log
cat deploy.log

# Vérifier la validation
./validate.sh
```

**Solutions courantes** :

#### Fichier .env manquant ou invalide
```bash
# Copier depuis l'exemple
cp .env.example .env
nano .env
# Configurer toutes les variables

# Revalider
./validate.sh
```

#### Docker non disponible
```bash
# Vérifier Docker
docker --version
docker compose version

# Redémarrer le service Docker (Linux)
sudo systemctl restart docker
```

#### Permissions insuffisantes
```bash
# Rendre les scripts exécutables
chmod +x *.sh

# Ou utiliser avec sudo (Linux)
sudo ./deploy.sh production
```

---

## 🔧 Commandes de Diagnostic Utiles

### Voir l'état complet du système
```bash
./maintenance.sh status
```

### Voir tous les logs en temps réel
```bash
docker compose logs -f
```

### Voir les logs d'un service spécifique
```bash
docker compose logs -f <service>
```

### Redémarrer un service
```bash
docker compose restart <service>
```

### Redémarrer tout
```bash
docker compose restart
```

### Arrêter et redémarrer complètement
```bash
docker compose down
docker compose up -d
```

### Vérifier les réseaux Docker
```bash
docker network ls
docker network inspect domotic-net
```

### Vérifier les volumes Docker
```bash
docker volume ls
docker volume inspect <volume_name>
```

### Accéder au shell d'un conteneur
```bash
docker compose exec <service> sh
# ou
docker compose exec <service> bash
```

---

## 📞 Obtenir de l'Aide

Si le problème persiste :

1. **Consulter les logs détaillés** :
   ```bash
   ./maintenance.sh logs > full_logs.txt
   ```

2. **Vérifier la configuration** :
   ```bash
   ./validate.sh
   ```

3. **Redéploiement complet** :
   ```bash
   ./cleanup.sh
   ./deploy.sh staging  # Tester d'abord
   ./deploy.sh production  # Si OK
   ```

4. **Ouvrir une issue GitHub** avec :
   - Description du problème
   - Messages d'erreur exacts
   - Logs pertinents (sans mots de passe !)
   - Résultat de `./validate.sh`

---

## 🆘 Scénarios d'Urgence

### Tout est cassé, je veux recommencer à zéro
```bash
# ⚠️ ATTENTION : Ceci supprime TOUTES les données
docker compose down -v  # -v supprime aussi les volumes
./cleanup.sh
rm -rf nginx/ssl/* certbot/conf/*
./deploy.sh production
```

### Sauvegarder avant de faire des tests
```bash
./maintenance.sh backup
# Vos données sont dans ./backups/
```

### Restaurer après un test raté
```bash
./maintenance.sh restore backups/<fichier_sauvegarde>
```

---

**💡 Conseil** : Gardez toujours une sauvegarde récente avec `./maintenance.sh backup` !
