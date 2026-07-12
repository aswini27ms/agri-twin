import sys
import subprocess
import time
import threading
import requests
import asyncio
from pathlib import Path

# Use SelectorEventLoop on Windows to support add_reader/remove_reader for asyncio-mqtt
if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

# pyrefly: ignore [missing-import]
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
# pyrefly: ignore [missing-import]
from fastapi.middleware.cors import CORSMiddleware
from backend.database.db import engine, Base

# ----------------------------------------------------------------------
# Router imports
# ----------------------------------------------------------------------
from backend.routers import (
    sensors,
    farm,
    predictions,
    alerts,
    chat,
    irrigation,
    soil,
)

# ----------------------------------------------------------------------
# Service imports
# ----------------------------------------------------------------------
from backend.services import soil_service
from backend.services.sensor_service import service as sensor_service  # <-- NEW

import asyncio

# ────────────────────────────────────────────────────────────────────────
# Ollama auto‑start
# ────────────────────────────────────────────────────────────────────────
OLLAMA_URL = "http://localhost:11434"
OLLAMA_EXE = Path(r"C:\Users\aswin\AppData\Local\Programs\Ollama\ollama.exe")
_ollama_ready = False  # module‑level flag read by gemma_service


def _is_ollama_running() -> bool:
    try:
        r = requests.get(f"{OLLAMA_URL}/api/tags", timeout=3)
        return r.status_code == 200
    except Exception:
        return False


def _start_ollama_server():
    """Launch ollama serve in the background if it isn't already up."""
    global _ollama_ready

    if _is_ollama_running():
        print("[AgriTwin] [OK] Ollama already running.")
        _ollama_ready = True
        return

    exe = OLLAMA_EXE if OLLAMA_EXE.exists() else None
    if exe is None:
        # Try PATH
        import shutil

        found = shutil.which("ollama")
        if found:
            exe = Path(found)

    if exe is None:
        print("[AgriTwin] [WARN] Ollama executable not found. Chat will be offline.")
        return

    print(f"[AgriTwin] [START] Starting Ollama server: {exe} serve ...")
    try:
        subprocess.Popen(
            [str(exe), "serve"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=subprocess.CREATE_NO_WINDOW
            if sys.platform == "win32"
            else 0,
        )
    except Exception as e:
        print(f"[AgriTwin] [WARN] Failed to launch Ollama: {e}")
        return

    # Wait up to 30 seconds for it to be ready
    for attempt in range(30):
        time.sleep(1)
        if _is_ollama_running():
            print(f"[AgriTwin] [OK] Ollama is ready (took {attempt + 1}s).")
            _ollama_ready = True
            return

    print("[AgriTwin] [WARN] Ollama did not become ready in 30s. Chat may be offline.")


def _warmup_gemma():
    """Send a tiny warmup message so Gemma loads its weights before first user request."""
    if not _ollama_ready:
        return
    try:
        from backend.ai.gemma_service import warmup_gemma

        ok = warmup_gemma()
        if ok:
            print("[AgriTwin] [OK] Gemma warmup complete - chat is live.")
        else:
            print("[AgriTwin] [WARN] Gemma warmup failed. First chat may be slow.")
    except Exception as e:
        print(f"[AgriTwin] [WARN] Gemma warmup error: {e}")


def _ollama_startup_thread():
    _start_ollama_server()
    _warmup_gemma()


# ────────────────────────────────────────────────────────────────────────
# Create DB tables
# ────────────────────────────────────────────────────────────────────────
Base.metadata.create_all(bind=engine)

# ────────────────────────────────────────────────────────────────────────
# FastAPI app
# ────────────────────────────────────────────────────────────────────────
app = FastAPI(title="AgriTwin API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(sensors.router)
app.include_router(farm.router)
app.include_router(predictions.router)
app.include_router(alerts.router)
app.include_router(chat.router)
app.include_router(irrigation.router)
app.include_router(soil.router)


@app.get("/")
def root():
    return {"status": "AgriTwin API v2 (Modular) is running."}


@app.get("/gemma/status")
def gemma_status():
    """Quick endpoint to check if Ollama + Gemma are reachable."""
    running = _is_ollama_running()
    return {
        "ollama_running": running,
        "gemma_ready": _ollama_ready,
        "ollama_url": OLLAMA_URL,
    }


# ────────────────────────────────────────────────────────────────────────
# Startup / Shutdown hooks
# ────────────────────────────────────────────────────────────────────────
@app.on_event("startup")
async def on_startup():
    t = threading.Thread(target=_ollama_startup_thread, daemon=True)
    t.start()
    asyncio.create_task(soil_service.start_simulator())
    await sensor_service.start()  # <-- start MQTT & Serial background tasks


@app.on_event("shutdown")
async def on_shutdown():
    await sensor_service.stop()  # <-- cleanly stop those background tasks


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)