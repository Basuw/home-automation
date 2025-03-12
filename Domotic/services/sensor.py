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

MQTT_PORT = int(os.getenv('MQTT_PORT', 1883))
DB_CONFIG = {
    "dbname": "sensor_data",
    "user": "postgres",
    "password": "password",
    "host": "db"
}

def on_message(client, userdata, msg):
    data = json.loads(msg.payload.decode())
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()
    cur.execute("INSERT INTO measurements (temperature, humidity, light) VALUES (%s, %s, %s)", 
                (data["temperature"], data["humidity"], data["light"]))
    conn.commit()
    cur.close()
    conn.close()

client = mqtt.Client()
client.username_pw_set(MQTT_USER, MQTT_PASSWORD)
client.connect(MQTT_BROKER, MQTT_PORT, 60)
client.subscribe(MQTT_TOPIC)
client.on_message = on_message
client.loop_forever()
