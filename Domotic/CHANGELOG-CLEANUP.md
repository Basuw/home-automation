# 🧹 Nettoyage de la configuration - Octobre 2025

## Fichiers supprimés

Les fichiers suivants ont été supprimés car ils ne sont plus nécessaires avec la configuration path-based :

### Scripts
- ❌ `add-subdomains-ssl.sh` - Script pour ajouter des certificats de sous-domaines (non nécessaire avec path-based routing)

### Configurations Nginx
- ❌ `nginx/conf.d/default.conf` - Configuration avec sous-domaines (remplacée par default-paths.conf)
- ❌ `nginx/conf.d/default-http-only.conf` - Configuration temporaire HTTP (générée dynamiquement dans deploy.sh)

## Configuration actuelle

### Fichier unique de configuration Nginx
- ✅ `nginx/conf.d/default-paths.conf` - Configuration path-based pour tous les services

### Services accessibles via paths
- `https://votre-domaine.com/` - Dashboard principal (Grafana)
- `https://votre-domaine.com/api` - API domotique
- `https://votre-domaine.com/grafana` - Grafana
- `https://votre-domaine.com/pgadmin` - PgAdmin
- `https://votre-domaine.com/portainer` - Portainer
- `https://votre-domaine.com/nextcloud` - Nextcloud

## Modifications des scripts

### deploy.sh
- Génère maintenant la configuration HTTP temporaire inline (pas besoin de fichier séparé)
- Utilise uniquement `default-paths.conf` pour la configuration SSL finale
- Ne gère plus les liens symboliques nginx/ssl (inutiles)
- Tests des services adaptés aux paths au lieu des sous-domaines

### validate.sh
- Vérifie maintenant `default-paths.conf` au lieu de `default.conf`
- Références mises à jour

## Modifications de la documentation

### README-PATHS.md
- Section "Passer aux sous-domaines" supprimée (simplification)

### SCRIPTS.md
- Références à `default.conf` remplacées par `default-paths.conf`

### TROUBLESHOOTING.md
- Commandes mises à jour pour utiliser `default-paths.conf`

### README.md
- Instructions simplifiées pour le troubleshooting nginx

## Avantages de cette simplification

✅ **Moins de fichiers** : Configuration plus simple à maintenir
✅ **Pas de DNS complexe** : Un seul certificat SSL pour le domaine principal
✅ **Deploy plus rapide** : Moins d'étapes, moins de risques d'erreur
✅ **Plus clair** : Une seule façon de faire les choses

## Migration

Si vous aviez déjà déployé avec l'ancienne configuration :

```bash
# Nettoyer et redéployer
./cleanup.sh
./deploy.sh staging
```

Aucune autre action n'est nécessaire !
