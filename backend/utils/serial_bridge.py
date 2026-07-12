import serial
import json
import time
import requests

ARDUINO_PORT = "COM3"
BAUD_RATE = 9600
API_URL = "http://localhost:8000/sensors/update"

def main():
    print(f"Connecting to Arduino on {ARDUINO_PORT} at {BAUD_RATE} baud...")
    try:
        ser = serial.Serial(ARDUINO_PORT, BAUD_RATE, timeout=2)
    except Exception as e:
        print(f"Could not open serial port: {e}")
        return

    time.sleep(2)
    print("Connected. Reading sensor data...\n")

    while True:
        try:
            line = ser.readline().decode("utf-8").strip()
            if not line:
                continue

            data = json.loads(line)

            if "error" in data:
                print(f"Sensor read error from Arduino: {data['error']}")
                continue

            print(f"Reading: temp={data['temperature']}C  humidity={data['humidity']}%  soil={data['soil_moisture']}%")

            resp = requests.post(API_URL, data={
                "temperature": data["temperature"],
                "humidity": data["humidity"],
                "soil_moisture": data["soil_moisture"],
            }, timeout=3)

            if resp.status_code != 200:
                print(f"  -> Server rejected update: {resp.status_code} {resp.text}")

        except json.JSONDecodeError:
            continue
        except requests.exceptions.RequestException as e:
            print(f"  -> Could not reach API server: {e}")
        except KeyboardInterrupt:
            print("\nStopped.")
            break
        except Exception as e:
            print(f"Unexpected error: {e}")

if __name__ == "__main__":
    main()
