# Utilisation de l'image Python officielle
FROM python:3.12

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers nécessaires
COPY sensor.py requirements.txt .env ./

# Installer les dépendances
RUN pip install --no-cache-dir -r requirements.txt

# Lancer le script de récupération des capteurs
CMD ["python", "sensor.py"]