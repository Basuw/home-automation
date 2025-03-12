from fastapi import FastAPI, Query
import paho.mqtt.client as mqtt
import os
from dotenv import load_dotenv

load_dotenv()

#MQTT_BROKER = os.getenv('MQTT_BROKER')
MQTT_BROKER = "mosquitto"
MQTT_TOPIC = "esp32/led"
MQTT_USER = os.getenv('MQTT_USER')  # Add user
MQTT_PASSWORD = os.getenv('MQTT_PASSWORD')  # Add password

print(MQTT_USER)
print(MQTT_PASSWORD)

app = FastAPI()
client = mqtt.Client()
client.username_pw_set(MQTT_USER, MQTT_PASSWORD)  # Set username and password
client.connect(MQTT_BROKER, 1883, 60)

@app.get("/setColor")
def set_color(
    r: int = Query(..., description="Red value"),
    g: int = Query(..., description="Green value"),
    b: int = Query(..., description="Blue value"),
    brightness: int = Query(..., description="Brightness value")
):
    message = f"{r},{g},{b},{brightness}"
    client.publish(MQTT_TOPIC, message)  # Change mqtt_client to client
    return {"message": "Color sent", "values": (r, g, b, brightness)}