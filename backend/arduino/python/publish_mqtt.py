import asyncio
import json
import random
import sys
import requests

# Use SelectorEventLoop on Windows to support add_reader/remove_reader for asyncio-mqtt
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

from asyncio_mqtt import Client, MqttError

async def main():
    broker = "localhost"
    topic = "arduino/sensor"
    backend_url = "http://localhost:8000/sensors/update"
    
    print(f"MQTT Client configured for broker at {broker}...")
    print(f"Fallback HTTP POST configured for {backend_url}...")
    
    temp = 25.0
    humidity = 60.0
    soil = 400.0

    while True:
        # Simulate a random walk for sensor readings
        temp += random.uniform(-0.5, 0.5)
        humidity += random.uniform(-1.0, 1.0)
        soil += random.randint(-5, 5)
        
        # Clamp values to reasonable ranges
        temp = max(10.0, min(temp, 45.0))
        humidity = max(20.0, min(humidity, 95.0))
        soil = max(100.0, min(soil, 1023.0))

        payload = {
            "temperature": round(temp, 2),
            "humidity": round(humidity, 2),
            "soil_moisture": round(soil, 1)
        }

        # 1. Try MQTT first
        mqtt_success = False
        try:
            async with Client(broker, timeout=2) as client:
                await client.publish(topic, json.dumps(payload))
                print(f"MQTT Connected! Published to {topic}: {payload}")
                mqtt_success = True
        except (MqttError, Exception):
            pass

        # 2. Fallback to HTTP POST if MQTT failed
        if not mqtt_success:
            try:
                response = requests.post(
                    backend_url,
                    data={
                        "temperature": payload["temperature"],
                        "humidity": payload["humidity"],
                        "soil_moisture": payload["soil_moisture"]
                    },
                    timeout=2
                )
                if response.status_code == 200:
                    print(f"MQTT offline. Fallback HTTP POST successful: {payload}")
                else:
                    print(f"Fallback HTTP POST failed. Status: {response.status_code}")
            except Exception as e:
                print(f"Telemetry update failed (both MQTT and HTTP offline): {e}")

        await asyncio.sleep(3)

if __name__ == "__main__":
    asyncio.run(main())
