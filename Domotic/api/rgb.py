from fastapi import FastAPI, Query
import paho.mqtt.client as mqtt
import os

MQTT_BROKER = os.getenv('MQTT_BROKER', 'mosquitto')
MQTT_TOPIC = "esp32/led"

app = FastAPI()
mqtt_client = mqtt.Client()
mqtt_client.connect(MQTT_BROKER, 1883, 60)

@app.get("/setColor")
def set_color(
    r: int = Query(..., description="Red value"),
    g: int = Query(..., description="Green value"),
    b: int = Query(..., description="Blue value"),
    brightness: int = Query(..., description="Brightness value")
):
    message = f"{r},{g},{b},{brightness}"
    mqtt_client.publish(MQTT_TOPIC, message)
    return {"message": "Color sent", "values": (r, g, b, brightness)}