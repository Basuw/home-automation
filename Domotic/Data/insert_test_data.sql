-- Script pour insérer des données de test dans la base de données
-- Usage: docker compose exec db psql -U admin -d domotic -f /docker-entrypoint-initdb.d/insert_test_data.sql

-- Nettoyer les données existantes
TRUNCATE TABLE measurements CASCADE;
TRUNCATE TABLE sensors RESTART IDENTITY CASCADE;

-- Insérer des capteurs de test
INSERT INTO sensors (name, location) VALUES 
    ('Capteur Salon', 'Salon'),
    ('Capteur Chambre', 'Chambre'),
    ('Capteur Cuisine', 'Cuisine'),
    ('Capteur Extérieur', 'Jardin');

-- Générer des données de test sur les 7 derniers jours avec generate_series
-- Capteur 1: Salon
INSERT INTO measurements (timestamp, temperature, humidity, light, idSensor)
SELECT 
    ts,
    21.0 + (SIN(EXTRACT(EPOCH FROM ts) / 86400.0 * 2 * PI()) * 2.0) + (RANDOM() * 1.0 - 0.5),
    45.0 + (COS(EXTRACT(EPOCH FROM ts) / 86400.0 * 2 * PI()) * 5.0) + (RANDOM() * 5.0 - 2.5),
    CASE 
        WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 300.0 + (RANDOM() * 200.0)
        ELSE 300.0 * 0.05 + (RANDOM() * 10.0)
    END,
    (SELECT id FROM sensors WHERE name = 'Capteur Salon')
FROM generate_series(
    NOW() - INTERVAL '7 days',
    NOW(),
    INTERVAL '15 minutes'
) AS ts;

-- Capteur 2: Chambre
INSERT INTO measurements (timestamp, temperature, humidity, light, idSensor)
SELECT 
    ts,
    19.0 + (SIN(EXTRACT(EPOCH FROM ts) / 86400.0 * 2 * PI()) * 2.0) + (RANDOM() * 1.0 - 0.5),
    50.0 + (COS(EXTRACT(EPOCH FROM ts) / 86400.0 * 2 * PI()) * 5.0) + (RANDOM() * 5.0 - 2.5),
    CASE 
        WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 100.0 + (RANDOM() * 200.0)
        ELSE 100.0 * 0.05 + (RANDOM() * 10.0)
    END,
    (SELECT id FROM sensors WHERE name = 'Capteur Chambre')
FROM generate_series(
    NOW() - INTERVAL '7 days',
    NOW(),
    INTERVAL '15 minutes'
) AS ts;

-- Capteur 3: Cuisine
INSERT INTO measurements (timestamp, temperature, humidity, light, idSensor)
SELECT 
    ts,
    22.0 + (SIN(EXTRACT(EPOCH FROM ts) / 86400.0 * 2 * PI()) * 2.0) + (RANDOM() * 1.0 - 0.5),
    55.0 + (COS(EXTRACT(EPOCH FROM ts) / 86400.0 * 2 * PI()) * 5.0) + (RANDOM() * 5.0 - 2.5),
    CASE 
        WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 400.0 + (RANDOM() * 200.0)
        ELSE 400.0 * 0.05 + (RANDOM() * 10.0)
    END,
    (SELECT id FROM sensors WHERE name = 'Capteur Cuisine')
FROM generate_series(
    NOW() - INTERVAL '7 days',
    NOW(),
    INTERVAL '15 minutes'
) AS ts;

-- Capteur 4: Extérieur
INSERT INTO measurements (timestamp, temperature, humidity, light, idSensor)
SELECT 
    ts,
    15.0 + (SIN(EXTRACT(EPOCH FROM ts) / 86400.0 * 2 * PI()) * 2.0) + (RANDOM() * 1.0 - 0.5),
    70.0 + (COS(EXTRACT(EPOCH FROM ts) / 86400.0 * 2 * PI()) * 5.0) + (RANDOM() * 5.0 - 2.5),
    CASE 
        WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 1000.0 + (RANDOM() * 200.0)
        ELSE 1000.0 * 0.05 + (RANDOM() * 10.0)
    END,
    (SELECT id FROM sensors WHERE name = 'Capteur Extérieur')
FROM generate_series(
    NOW() - INTERVAL '7 days',
    NOW(),
    INTERVAL '15 minutes'
) AS ts;

-- Afficher un résumé
SELECT 
    s.name,
    s.location,
    COUNT(m.id) as nb_mesures,
    ROUND(AVG(m.temperature)::numeric, 2) as temp_moyenne,
    ROUND(AVG(m.humidity)::numeric, 2) as humidity_moyenne,
    ROUND(AVG(m.light)::numeric, 2) as light_moyenne
FROM sensors s
LEFT JOIN measurements m ON s.id = m.idSensor
GROUP BY s.id, s.name, s.location
ORDER BY s.id;
