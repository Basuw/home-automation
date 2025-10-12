# 🛠️ Guide des Scripts d'Administration

Ce document décrit tous les scripts disponibles pour gérer votre système domotique.

## 📋 Vue d'ensemble

| Script | Objectif | Quand l'utiliser |
|--------|----------|------------------|
| `validate.sh` | Validation de configuration | Avant le premier déploiement |
| `deploy.sh` | Déploiement automatique | Premier déploiement ou redéploiement complet |
| `maintenance.sh` | Opérations courantes | Maintenance quotidienne |
| `cleanup.sh` | Nettoyage | Avant un redéploiement si problème |

---

## 🔍 validate.sh - Validation de Configuration

### Description
Vérifie que votre configuration est correcte avant le déploiement.

### Usage
```bash
./validate.sh
```

### Ce qu'il vérifie
- ✅ Présence des fichiers requis (`.env`, `docker-compose.yml`, configs Nginx)
- ✅ Toutes les variables d'environnement sont définies
- ✅ Pas de valeurs par défaut dangereuses
- ✅ Configuration Nginx adaptée à votre domaine
- ✅ Syntaxe du `docker-compose.yml`
- ✅ Résolution DNS de votre domaine
- ✅ Disponibilité des ports 80 et 443

### Exemple de sortie
```
🔍 Validation de la configuration Home Automation System

📁 Vérification des fichiers...
✅ .env
✅ docker-compose.yml
✅ nginx/nginx.conf
✅ nginx/conf.d/default.conf

🔧 Vérification des variables d'environnement...
✅ DOMAIN configuré
✅ POSTGRES_PASSWORD configuré
...

🚀 Votre configuration semble prête pour le déploiement !
```

### Quand l'utiliser
- **Obligatoire** avant le premier déploiement
- Après avoir modifié le fichier `.env`
- Pour déboguer des problèmes de configuration

---

## 🚀 deploy.sh - Déploiement Automatique

### Description
Déploie automatiquement toute la stack avec obtention des certificats SSL.

### Usage
```bash
# Production (certificats SSL réels)
./deploy.sh production

# Staging (certificats de test Let's Encrypt)
./deploy.sh staging
```

### Ce qu'il fait
1. **Préparation**
   - Crée tous les dossiers nécessaires
   - Configure les permissions
   - Adapte la configuration Nginx à votre domaine

2. **Phase 1 : Bases de données**
   - Démarre PostgreSQL
   - Démarre MySQL (Nextcloud)
   - Attend 30s pour l'initialisation

3. **Phase 2 : Services applicatifs**
   - Démarre API, Listener, Mosquitto
   - Démarre PgAdmin, Grafana, Portainer
   - Démarre Nextcloud
   - Attend 20s pour l'initialisation

4. **Phase 3 : SSL et Nginx**
   - Démarre Nginx
   - Obtient les certificats Let's Encrypt
   - Redémarre Nginx avec SSL actif
   - Teste l'accessibilité de tous les services

5. **Configuration automatique**
   - Configure le renouvellement automatique SSL (cron)

### Variables utilisées
- `DOMAIN` : Votre domaine principal
- `LETSENCRYPT_EMAIL` : Email pour les notifications Let's Encrypt

### Quand l'utiliser
- **Premier déploiement** sur un nouveau serveur
- Redéploiement complet après changement de domaine
- Réinitialisation complète du système

### Conseils
💡 **Utilisez `staging` pour tester** avant de déployer en production
- Les certificats staging ne sont pas valides mais évitent les limites de taux Let's Encrypt
- Utile pour tester la configuration sans risque

---

## 🔧 maintenance.sh - Maintenance Quotidienne

### Description
Script tout-en-un pour toutes les opérations de maintenance.

### Commandes disponibles

#### 📊 Vérifier l'état
```bash
./maintenance.sh status
```
Affiche :
- État de tous les conteneurs (running/stopped)
- Utilisation CPU et RAM de chaque service
- Espace disque des volumes Docker
- Accessibilité des services web (test HTTPS)

#### 💾 Sauvegarde
```bash
./maintenance.sh backup
```
Sauvegarde :
- Base de données PostgreSQL → `backups/postgres_YYYYMMDD_HHMMSS.sql`
- Données Nextcloud → `backups/nextcloud_YYYYMMDD_HHMMSS.tar.gz`
- Configuration Grafana → `backups/grafana_YYYYMMDD_HHMMSS.tar.gz`

**⏱️ Durée** : 2-5 minutes selon la taille des données

#### 🔄 Restauration
```bash
./maintenance.sh restore <chemin_du_backup>
```
Exemples :
```bash
./maintenance.sh restore backups/postgres_20231101_120000.sql
./maintenance.sh restore backups/nextcloud_20231101_120000.tar.gz
./maintenance.sh restore backups/grafana_20231101_120000.tar.gz
```

**⚠️ Attention** : La restauration redémarre les services concernés

#### 📦 Mise à jour
```bash
./maintenance.sh update
```
Processus :
1. Sauvegarde automatique avant mise à jour
2. Arrêt des services
3. Téléchargement des nouvelles images Docker
4. Nettoyage des anciennes images
5. Redémarrage avec les nouvelles versions

**⏱️ Durée** : 5-10 minutes selon la connexion Internet

#### 📋 Consulter les logs
```bash
# Tous les services
./maintenance.sh logs

# Service spécifique
./maintenance.sh logs nginx
./maintenance.sh logs api
./maintenance.sh logs grafana
```

**Ctrl+C** pour quitter la vue des logs

#### 🔐 Renouveler SSL
```bash
./maintenance.sh ssl-renew
```
- Renouvelle les certificats Let's Encrypt
- Redémarre Nginx
- Affiche la date d'expiration des certificats

**Note** : Le renouvellement automatique est déjà configuré (tous les jours à 3h du matin)

#### 🧹 Nettoyage
```bash
./maintenance.sh clean
```
Nettoie :
- Images Docker inutilisées
- Volumes Docker orphelins
- Cache Docker

**⚠️ Les services sont redémarrés** après le nettoyage

### Quand utiliser chaque commande

| Commande | Fréquence recommandée |
|----------|----------------------|
| `status` | Tous les jours ou quand un problème survient |
| `backup` | **Avant toute modification**, minimum 1x/semaine |
| `restore` | En cas de problème ou perte de données |
| `update` | 1x/mois ou quand une mise à jour importante sort |
| `logs` | Pour déboguer un problème |
| `ssl-renew` | Automatique, manuel seulement si problème |
| `clean` | 1x/mois pour libérer de l'espace disque |

---

## 🧹 cleanup.sh - Nettoyage Avant Redéploiement

### Description
Nettoie complètement les conteneurs existants avant un redéploiement.

### Usage
```bash
./cleanup.sh
```

### Ce qu'il fait
1. Arrête tous les conteneurs du projet
2. Supprime les conteneurs orphelins
3. Vérifie et supprime les conteneurs avec noms en conflit

### Quand l'utiliser
- **Avant un redéploiement** si des conteneurs existent déjà
- En cas de conflits de noms de conteneurs
- Si `docker compose up` échoue à cause de conteneurs existants
- Pour "repartir de zéro"

### ⚠️ Attention
- Ce script **ne supprime PAS les volumes** → vos données sont préservées
- Les conteneurs seront recréés au prochain `docker compose up`
- Utilisez `docker volume rm` manuellement si vous voulez aussi supprimer les données

---

## 🔄 Workflow Typique

### Premier déploiement
```bash
# 1. Configuration
cp .env.example .env
nano .env  # Configurez vos variables

# 2. Validation
./validate.sh

# 3. Test en staging (optionnel mais recommandé)
./deploy.sh staging
# Vérifiez que tout fonctionne, puis nettoyez :
./cleanup.sh

# 4. Déploiement production
./deploy.sh production
```

### Maintenance hebdomadaire
```bash
# Lundi : Vérifier l'état
./maintenance.sh status

# Mercredi : Sauvegarde
./maintenance.sh backup

# Consulter les logs si nécessaire
./maintenance.sh logs
```

### Mise à jour mensuelle
```bash
# 1. Vérifier l'état actuel
./maintenance.sh status

# 2. Sauvegarder (fait automatiquement par update)
# 3. Mettre à jour
./maintenance.sh update

# 4. Vérifier après mise à jour
./maintenance.sh status
```

### En cas de problème
```bash
# 1. Consulter les logs
./maintenance.sh logs <service_problematique>

# 2. Si besoin de redémarrer
docker compose restart <service>

# 3. Si besoin de redéployer
./cleanup.sh
./deploy.sh production
```

---

## 🐛 Dépannage

### Script ne s'exécute pas
```bash
# Vérifier les permissions
ls -la *.sh

# Rendre exécutable
chmod +x *.sh
```

### Erreur "docker: command not found"
```bash
# Vérifier l'installation Docker
docker --version
docker compose version

# Si absent, installer Docker : https://docs.docker.com/get-docker/
```

### Erreur "Permission denied" pendant l'exécution
```bash
# Certains scripts nécessitent sudo sur Linux
sudo ./deploy.sh production

# Ou ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER
# Puis se déconnecter/reconnecter
```

### Les certificats SSL ne s'obtiennent pas
```bash
# Vérifier que le DNS est correct
nslookup votre-domaine.fr

# Vérifier que le port 80 est accessible depuis Internet
curl http://votre-domaine.fr/.well-known/acme-challenge/

# Utiliser staging pour tester
./deploy.sh staging
```

---

## 📚 Ressources Supplémentaires

- **README principal** : Instructions complètes d'installation
- **docker compose.yml** : Configuration des services
- **.env.example** : Template des variables d'environnement
- **Logs** : `docker-compose logs -f` pour voir les logs en temps réel

## 🤝 Contribution

Si vous améliorez un script, pensez à :
1. Tester en environnement staging
2. Documenter les changements
3. Mettre à jour ce fichier SCRIPTS.md

---

**Besoin d'aide ?** Consultez les logs avec `./maintenance.sh logs` ou ouvrez une issue sur GitHub.
