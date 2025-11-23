# Utilisation de l'image Python officielle
FROM python:3.12

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers nécessaires
COPY rgb.py requirements.txt ./

# Installer les dépendances
RUN pip install --no-cache-dir -r requirements.txt

# Exposer le port utilisé par FastAPI
EXPOSE 8000

# Lancer l'API avec Uvicorn
CMD ["uvicorn", "rgb:app", "--host", "0.0.0.0", "--port", "8000"]