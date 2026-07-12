from arduino.app_utils import *
import time
import requests

BACKEND_URL = "http://localhost:8000/sensors/update"

def loop():
    temperature = Bridge.call("getTemperature")
    humidity = Bridge.call("getHumidity")
    soil = Bridge.call("getSoilMoisture")

    print("----------------------------------")
    print(f"Temperature : {temperature:.2f} °C")
    print(f"Humidity    : {humidity:.2f} %")
    print(f"Soil Raw    : {soil}")

    try:
        response = requests.post(
            BACKEND_URL,
            data={
                "temperature": temperature,
                "humidity": humidity,
                "soil_moisture": soil
            },
            timeout=2
        )
        if response.status_code == 200:
            print("Successfully updated backend with sensor data.")
        else:
            print(f"Failed to update backend. Status: {response.status_code}")
    except Exception as e:
        print(f"Error updating backend: {e}")

    time.sleep(1)

App.run(user_loop=loop)