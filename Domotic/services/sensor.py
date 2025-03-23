import os
import paho.mqtt.client as mqtt
import psycopg2
import json
from dotenv import load_dotenv

load_dotenv()

#MQTT_BROKER = os.getenv('MQTT_BROKER')
MQTT_BROKER = "mosquitto"
MQTT_TOPIC = "esp32/sensor"
MQTT_USER = os.getenv('MQTT_USER')  # Add user
MQTT_PASSWORD = os.getenv('MQTT_PASSWORD')  # Add password

DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_HOST = os.getenv('DB_HOST')
DB_PORT = os.getenv('DB_PORT')
DB_NAME = os.getenv('DB_NAME')

MQTT_PORT = int(os.getenv('MQTT_PORT', 1883))
DB_CONFIG = {
    "dbname": DB_NAME,
    "user": DB_USER,
    "password": DB_PASSWORD,
    "port": DB_PORT,
    "host": DB_HOST
}

def on_message(client, userdata, msg):
    try:
        data = json.loads(msg.payload.decode())
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()
        cur.execute("INSERT INTO measurements (temperature, humidity, idSensor) VALUES (%s, %s, %s)", 
                    (data["temperature"], data["humidity"], data["idSensor"]))
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Failed to process message: {msg.payload.decode()}")
        print(f"Error: {e}")

client = mqtt.Client()
client.username_pw_set(MQTT_USER, MQTT_PASSWORD)
client.connect(MQTT_BROKER, MQTT_PORT, 60)
client.subscribe(MQTT_TOPIC)
client.on_message = on_message
client.loop_forever()
