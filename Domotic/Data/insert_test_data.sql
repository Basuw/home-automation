-- Script pour insérer des données de test dans la base de données
-- Usage: docker compose exec db psql -U admin -d domotic -f /docker-entrypoint-initdb.d/insert_test_data.sql

-- Nettoyer les données existantes
TRUNCATE TABLE measurements CASCADE;
TRUNCATE TABLE sensors CASCADE;

-- Insérer des capteurs de test
INSERT INTO sensors (name, location) VALUES 
    ('Capteur Salon', 'Salon'),
    ('Capteur Chambre', 'Chambre'),
    ('Capteur Cuisine', 'Cuisine'),
    ('Capteur Extérieur', 'Jardin');

-- Fonction pour générer des données de test sur les 7 derniers jours
DO $$
DECLARE
    sensor_id INT;
    current_time TIMESTAMP WITHOUT TIME ZONE;
    end_time TIMESTAMP WITHOUT TIME ZONE;
    base_temp FLOAT;
    base_humidity FLOAT;
    base_light FLOAT;
BEGIN
    -- Pour chaque capteur
    FOR sensor_id IN 1..4 LOOP
        -- Définir les valeurs de base selon l'emplacement
        CASE sensor_id
            WHEN 1 THEN -- Salon
                SELECT 21.0, 45.0, 300.0 INTO base_temp, base_humidity, base_light;
            WHEN 2 THEN -- Chambre
                SELECT 19.0, 50.0, 100.0 INTO base_temp, base_humidity, base_light;
            WHEN 3 THEN -- Cuisine
                SELECT 22.0, 55.0, 400.0 INTO base_temp, base_humidity, base_light;
            WHEN 4 THEN -- Extérieur
                SELECT 15.0, 70.0, 1000.0 INTO base_temp, base_humidity, base_light;
        END CASE;
        
        -- Générer des données toutes les 15 minutes sur les 7 derniers jours
        SELECT (NOW() - INTERVAL '7 days')::TIMESTAMP WITHOUT TIME ZONE INTO current_time;
        SELECT NOW()::TIMESTAMP WITHOUT TIME ZONE INTO end_time;
        
        WHILE current_time <= end_time LOOP
            -- Ajouter des variations réalistes
            -- Température: variation journalière et aléatoire
            -- Humidité: variation journalière et aléatoire
            -- Lumière: forte variation jour/nuit
            INSERT INTO measurements (timestamp, temperature, humidity, light, idSensor)
            VALUES (
                current_time,
                -- Température avec cycle jour/nuit et variations aléatoires
                base_temp 
                    + (SIN(EXTRACT(EPOCH FROM current_time) / 86400.0 * 2 * PI()) * 2.0)  -- Cycle journalier
                    + (RANDOM() * 1.0 - 0.5),  -- Variation aléatoire
                -- Humidité avec variations
                base_humidity 
                    + (COS(EXTRACT(EPOCH FROM current_time) / 86400.0 * 2 * PI()) * 5.0)  -- Cycle journalier
                    + (RANDOM() * 5.0 - 2.5),  -- Variation aléatoire
                -- Lumière avec forte variation jour/nuit
                CASE 
                    WHEN EXTRACT(HOUR FROM current_time) BETWEEN 6 AND 20 THEN
                        base_light + (RANDOM() * 200.0)  -- Jour
                    ELSE
                        base_light * 0.05 + (RANDOM() * 10.0)  -- Nuit
                END,
                sensor_id
            );
            
            -- Avancer de 15 minutes (avec cast explicite pour éviter les problèmes de type)
            SELECT (current_time + INTERVAL '15 minutes')::TIMESTAMP WITHOUT TIME ZONE INTO current_time;
        END LOOP;
    END LOOP;
END $$;

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
