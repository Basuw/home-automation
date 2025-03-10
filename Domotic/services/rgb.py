from fastapi import FastAPI
import paho.mqtt.client as mqtt

MQTT_BROKER = "mqtt_broker"
MQTT_TOPIC = "esp32/led"

app = FastAPI()
mqtt_client = mqtt.Client()
mqtt_client.connect(MQTT_BROKER, 1883, 60)

@app.get("/setColor")
def set_color(r: int, g: int, b: int, brightness: int):
    message = f"{r},{g},{b},{brightness}"
    mqtt_client.publish(MQTT_TOPIC, message)
    return {"message": "Color sent", "values": (r, g, b, brightness)}