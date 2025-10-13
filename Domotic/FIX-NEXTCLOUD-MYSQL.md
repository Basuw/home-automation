# 🔧 Fix Nextcloud MySQL Connection

## Problème
Erreur: `Host '172.19.0.4' is not allowed to connect to this MySQL server`

## Solution appliquée

Modifications dans `docker-compose.yml` :

1. Ajout de `--bind-address=0.0.0.0` dans la commande MySQL
2. Ajout de `MYSQL_ROOT_HOST: '%'` pour autoriser les connexions réseau

## 🚀 Pour appliquer le fix

**Sur votre serveur Linux (via SSH)**, exécutez :

```bash
cd /path/to/home-automation/Domotic

# 1. Arrêter Nextcloud et sa base de données
docker compose stop nextcloud nextcloud-db

# 2. Supprimer les conteneurs
docker compose rm -f nextcloud nextcloud-db

# 3. IMPORTANT: Supprimer le volume de la base MySQL pour repartir à zéro
docker volume rm home-automation_nextcloud_db

# 4. Redémarrer les services
docker compose up -d nextcloud-db
sleep 10  # Attendre que MySQL soit prêt
docker compose up -d nextcloud

# 5. Vérifier les logs
docker compose logs -f nextcloud
```

## 📝 Alternative : Fix sans supprimer le volume

Si vous voulez garder les données existantes (pas recommandé pour un premier setup) :

```bash
cd /path/to/home-automation/Domotic

# 1. Accéder au conteneur MySQL
docker compose exec nextcloud-db mysql -u root -p${MYSQL_ROOT_PASSWORD}

# 2. Dans MySQL, exécuter :
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'%' IDENTIFIED BY 'votre_mot_de_passe';
FLUSH PRIVILEGES;
EXIT;

# 3. Redémarrer Nextcloud
docker compose restart nextcloud
```

## ✅ Vérification

Une fois redémarré, accédez à :
```
https://jacquelin63.freeboxos.fr/nextcloud
```

L'installation devrait se faire sans erreur de connexion MySQL.

## 🔒 Sécurité

Cette configuration autorise les connexions MySQL depuis n'importe quelle IP du réseau Docker interne (`domotic-net`), ce qui est sécurisé car :
- Le réseau est isolé (pas accessible depuis l'extérieur)
- Seuls les conteneurs du même projet peuvent communiquer
- L'authentification par mot de passe est toujours requise
