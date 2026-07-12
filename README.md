# AgriTwin - AI-Powered Smart Farming Digital Twin

AgriTwin is a state-of-the-art agricultural management system combining **real-time hardware telemetry**, **interactive digital twin simulation**, and **agronomic AI insights** to help farmers make smarter, data-driven decisions.

---

## 🌟 Key Features

### 1. Interactive Digital Twin Dashboard
- **Visual Farm Grid:** Displays the farm layout as a digital grid. Each cell tracks specific crop types, age, disease scans, risk levels, and soil status.
- **Projected Simulation:** Replays timelines up to 72 hours out based on environmental inputs (e.g., temperature changes or water levels) using mock forecasting models.
- **Reset Capabilities:** Quickly reset the twin layout to demo defaults in one tap.

### 2. Live Hardware Node Integration (Arduino Uno Q)
- **Unified Telemetry:** Captures temperature, humidity, and raw soil moisture readings directly from connected microcontrollers.
- **Dual Ingestion Engine:**
  - **MQTT Protocol (Primary):** Back-end subscribes to `arduino/sensor` using a resilient `asyncio-mqtt` connection with built-in auto-reconnect logic.
  - **HTTP POST Fallback (Zero-Config):** If the MQTT broker is offline, the node/simulator automatically falls back to updating the backend using standard HTTP POST requests (`/sensors/update`). This makes testing instant and robust against firewall blocks.
- **Telemetry UI Widget:** Rendered on both the **Home Screen** and **Soil Analysis Screen** to display live hardware node statistics in a glassmorphic dashboard interface.

### 3. Soil Analysis Screen
- **Parameter Analysis:** Detailed metric tracking for Nitrogen (N), Phosphorus (P), Potassium (K), pH Level, Organic Matter, Moisture, Zinc, and Iron.
- **Actionable Recommendations:** Suggests fertilizer adjustments (e.g., applying urea or compost) and watering schedules dynamically based on real-time soil chemistry.

### 4. Crop Vision Diagnostic Chamber
- **Leaf Scanning:** Capture or upload crop leaf photos to detect pest infestations or disease (e.g., Tomato Early Blight) instantly.
- **Groq AI Expert Insights:** Calls Llama 3.1 on Groq API to generate 2-sentence agronomic advice on how to treat the diagnosed crop disease.

### 5. Weather Intelligence
- **IP Geolocation:** Auto-detects location via IP to fetch current weather details and forecasts without requiring manual configuration.
- **Weather Details:** Dynamic temperature, description, and climate suggestions tailored to the local area.

---

## 🛠️ Technical Stack

- **Frontend:**
  - **Flutter & Dart:** Riverpod (state management), Hive (fast local cache storage), Dio (network requests), and FL Chart (data visualization).
- **Backend:**
  - **FastAPI (Python 3.12):** SQLAlchemy, SQLite (`agritwin.db`), asyncio, and Uvicorn.
- **Hardware Integration:**
  - **MQTT & HTTP:** Client simulator in Python (`publish_mqtt.py`) utilizing `asyncio-mqtt` (Paho-MQTT 1.6.1 client) and `requests` for the HTTP fallback mechanism.

---

## 🚀 Getting Started

### Prerequisites
- **Python 3.12+**
- **Flutter SDK**
- **MQTT Broker** (Optional, e.g., Mosquitto. Not required if using the HTTP fallback mode.)

---

### Step-by-Step Run Instructions

#### 1. Setup Python Dependencies
Install required packages in your Python environment:
```bash
python -m pip install fastapi uvicorn sqlalchemy pydantic requests asyncio-mqtt "paho-mqtt<2.0.0"
```

#### 2. Start the Backend Server
From the root directory, start the FastAPI server:
```bash
python backend/main.py
```
This runs the API server on **`http://localhost:8000`**.

#### 3. Run the Hardware Node Simulator
In a separate terminal window, start the telemetry generator script:
```bash
python backend/arduino/python/publish_mqtt.py
```
*Note: If no MQTT broker is detected running on `localhost`, the script will print a connection warning and immediately fall back to updating the backend via HTTP POST. You will see live values shifting every 3 seconds.*

#### 4. Run the Flutter App
To launch the frontend on your development machine in headless web-server mode:
```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```
Open **[http://127.0.0.1:8080](http://127.0.0.1:8080)** in your browser.

---

### 📱 Running on a Physical Phone

If you build the app onto a physical Android or iOS device, the app must connect to your PC's backend over your local network:

1. Connect both your phone and PC to the **same Wi-Fi network**.
2. Find your PC's local IP address (run `ipconfig` on Windows, look for `IPv4 Address` under your active Wi-Fi adapter, e.g., `10.225.67.206`).
3. Open the app on your phone, go to **Settings**, and update the **Backend IP** to:
   `http://<YOUR_PC_IP>:8000` (e.g. **`http://10.225.67.206:8000`**).

---

## 🔒 Recent Security & Platform Fixes

1. **Removed hardcoded API keys:** Cleaned up and replaced hardcoded bearer tokens in [crop_vision_screen.dart](lib/screens/crop_vision_screen.dart) with secure placeholders, meeting GitHub Push Protection rules.
2. **Windows Event Loop Policy:** Configured the event loop policy in both `main.py` and `publish_mqtt.py` to use `WindowsSelectorEventLoopPolicy` on Windows. This fixes the `NotImplementedError` raised by `ProactorEventLoop` when registering/removing socket readers in `asyncio-mqtt`.
3. **Paho-MQTT Version Compatibility:** Downgraded `paho-mqtt` to `1.6.1` to prevent `AttributeError` crashes associated with v2.x changes.
