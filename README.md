# Home Automation System

## Overview
This project is a **home automation system** that allows you to:
- Control **RGB LEDs** remotely via an API.
- Collect and store **sensor data** from an ESP32 using MQTT.
- Visualize the collected data in **Grafana dashboards**.
- Manage all services using **Docker** and **Docker Compose**.

This project is link to [my arduino project](https://github.com/Basuw/Moisture_termic_sensor-Arduino).

## Architecture
The system consists of the following components:

1. **ESP32**: Connects sensors and LEDs, sends/receives MQTT messages.
2. **FastAPI Server**: Exposes an API to control LEDs via MQTT.
3. **MQTT Broker (Mosquitto)**: Handles communication between ESP32 and backend services.
4. **Listener Service**: Listens to sensor data from ESP32 and stores it in a PostgreSQL database.
5. **PostgreSQL Database**: Stores sensor data.
6. **Grafana**: Provides a web dashboard for visualizing sensor data.

## Features
- Control **LED colors and brightness** via an HTTP API.
- Collect **temperature, humidity, and light sensor data**.
- Store sensor readings in a **PostgreSQL database**.
- Display sensor data in **Grafana** for real-time monitoring.
- Fully containerized with **Docker Compose**.

## Setup and Installation

### Prerequisites
- **Docker** and **Docker Compose** installed on your system.
- An **ESP32** with sensors and RGB LEDs.

### Clone the Repository
```sh
git clone https://github.com/your-repo/home-automation.git
cd home-automation
```

### Build and Run the Project
```sh
docker-compose up --build
```

### API Usage
Once the system is running, you can control the LEDs by sending requests to the FastAPI server.

#### Change LED Color
```sh
curl "http://localhost:8000/setColor?r=255&g=100&b=50&brightness=80"
```

### Access Grafana
Once the containers are up, you can access the **Grafana dashboard** at:
```
http://localhost:3000
```
Default login:
- **Username**: `admin`
- **Password**: `admin`

## Project Structure
```
home-automation/
│── api/
│   ├── api.py
│   ├── requirements.txt
│   ├── Dockerfile
│── listener/
│   ├── listener.py
│   ├── requirements.txt
│   ├── Dockerfile
│── db/
│   ├── init.sql
│── docker-compose.yml
│── mosquitto.conf
│── README.md
```

## Future Improvements
- Add **authentication** for the API.
- Improve **error handling** in MQTT communication.
- Implement **WebSockets** for real-time LED updates.

## License
This project is open-source and licensed under the MIT License.

## Author
Bastien Jacquelin
