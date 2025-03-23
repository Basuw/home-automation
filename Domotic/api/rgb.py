from fastapi import FastAPI, Query
import paho.mqtt.client as mqtt
import os
from dotenv import load_dotenv

load_dotenv()

MQTT_BROKER = "mosquitto"
MQTT_TOPIC = "esp32/led"
MQTT_USER = os.getenv('MQTT_USER')  # Add user
MQTT_PASSWORD = os.getenv('MQTT_PASSWORD')  # Add password
MQTT_PORT = int(os.getenv('MQTT_PORT', 1883))

app = FastAPI()
client = mqtt.Client(client_id="api")
client.username_pw_set(MQTT_USER, MQTT_PASSWORD)

@app.get("/setColor")
def set_color(
    r: int = Query(..., description="Red value"),
    g: int = Query(..., description="Green value"),
    b: int = Query(..., description="Blue value"),
    brightness: int = Query(..., description="Brightness value")
):
    client.connect(MQTT_BROKER, MQTT_PORT, 60)
    message = f"{r},{g},{b},{brightness}"
    client.publish(MQTT_TOPIC, message)  # Change mqtt_client to client
    client.disconnect()
    return {"message": "Color sent", "values": (r, g, b, brightness)}
    