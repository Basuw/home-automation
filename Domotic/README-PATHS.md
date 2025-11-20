# 🚀 Configuration avec PATHS (Sans sous-domaines)

Cette configuration utilise des **paths** au lieu de sous-domaines pour accéder aux différents services.

## 📋 URLs d'accès

Tous les services sont accessibles via le domaine principal :

| Service | URL | Description |
|---------|-----|-------------|
ù!ù^9*=9=9| 🔌 API | `https://jacquelin63.freeboxos.fr/api` | API domotique |
| 📊 Grafana | `https://jacquelin63.freeboxos.fr/grafana` | Monitoring |
| 🗄️ phpMyAdmin | `https://jacquelin63.freeboxos.fr/phpmyadmin` | Gestion MySQL |
| 🐳 Portainer | `https://jacquelin63.freeboxos.fr/portainer` | Gestion containers |
| ☁️ Nextcloud | `https://jacquelin63.freeboxos.fr/nextcloud` | Stockage cloud |

## ✅ Avantages de cette configuration

- ✅ **Un seul certificat SSL** nécessaire (pour `jacquelin63.freeboxos.fr`)
- ✅ **Pas besoin de configurer les DNS** pour les sous-domaines
- ✅ **Plus simple** à déployer et maintenir
- ✅ **Fonctionne immédiatement** avec n'importe quel domaine

## 🔧 Configuration requise dans .env

Ajoutez ces lignes dans votre fichier `.env` :

```env
# Grafana avec subpath
GF_SERVER_ROOT_URL=https://jacquelin63.freeboxos.fr/grafana
GF_SERVER_SERVE_FROM_SUB_PATH=true

# phpMyAdmin avec subpath
PMA_ABSOLUTE_URI=https://jacquelin63.freeboxos.fr/phpmyadmin/
```

## 🚀 Déploiement

```bash
cd Domotic

# 1. Valider la configuration
./validate.sh

# 2. Déployer (staging pour tester)
./deploy.sh staging

# 3. Si OK, déployer en production
./cleanup.sh
./deploy.sh production
```

## 📝 Notes importantes

### Grafana
- Accessible sur `/grafana`
- Configuré pour fonctionner avec un sub-path
- Les dashboards et plugins fonctionnent normalement

### phpMyAdmin
- Nécessite la variable `PMA_ABSOLUTE_URI`
- Se connecte automatiquement à la base MySQL de Nextcloud
- Utilisateur root avec accès complet

### Portainer
- Premier accès : création du compte admin
- Les WebSockets fonctionnent correctement

### Nextcloud
- Nécessite une configuration supplémentaire au premier démarrage
- WebDAV accessible via `/nextcloud/remote/`
- CalDAV/CardDAV via `/.well-known/`



## 🆘 Dépannage

### Service retourne 404 ou 502

```bash
# Vérifier les logs du service
docker compose logs <service>

# Redémarrer le service
docker compose restart <service>
docker compose restart nginx
```

### Grafana ne charge pas correctement
```bash
# Vérifier les variables d'environnement
docker compose exec grafana env | grep GF_SERVER

# Doivent afficher :
# GF_SERVER_ROOT_URL=https://jacquelin63.freeboxos.fr/grafana
# GF_SERVER_SERVE_FROM_SUB_PATH=true
```

### PgAdmin redirige mal
```bash
# Vérifier la variable SCRIPT_NAME
docker compose exec pgadmin env | grep SCRIPT_NAME

# Doit afficher : SCRIPT_NAME=/pgadmin
```

## 📚 Références

- [Grafana behind reverse proxy](https://grafana.com/tutorials/run-grafana-behind-a-proxy/)
- [PgAdmin container deployment](https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html)
- [Nginx reverse proxy guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
