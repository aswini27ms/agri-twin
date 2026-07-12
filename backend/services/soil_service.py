"""
soil_service.py
----------------
Real-time soil data layer for AgriTwin.

Design:
- Uses your existing agritwin.db (plain sqlite3, no dependency on your ORM setup,
  so this drops in regardless of how database.py is structured).
- Two data sources feed the SAME table + WebSocket broadcast:
    1. Real sensor (ESP32) -> POST /soil/ingest
    2. Simulator -> replays soil_dataset.csv with small random-walk noise,
       but ONLY when no real reading has arrived in the last SIMULATION_TIMEOUT_S
       seconds. So: plug in a real sensor and it takes over automatically;
       unplug it and simulation quietly resumes.
- Every new reading (real or simulated) is broadcast to all connected
  Flutter WebSocket clients immediately.
"""

import asyncio
import csv
import os
import random
import sqlite3
import json
from datetime import datetime, timezone
from typing import Optional

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "agritwin.db")
DATASET_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "soil_dataset.csv")

SIMULATION_INTERVAL_S = 5      # how often the simulator emits a reading
SIMULATION_TIMEOUT_S = 30      # how long to wait after last REAL reading before simulating again

FIELDS = ["nitrogen", "phosphorus", "potassium", "ph", "moisture", "organic_matter", "zinc", "iron"]


# ── DB setup ──────────────────────────────────────────────────────────────
def init_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS soil_readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nitrogen REAL, phosphorus REAL, potassium REAL, ph REAL,
            moisture REAL, organic_matter REAL, zinc REAL, iron REAL,
            source TEXT NOT NULL,
            field TEXT DEFAULT 'Field A',
            timestamp TEXT NOT NULL
        )
        """
    )
    conn.commit()
    conn.close()


def _row_to_dict(row: sqlite3.Row) -> dict:
    return {k: row[k] for k in row.keys()}


def insert_reading(data: dict, source: str, field: str = "Field A") -> dict:
    ts = datetime.now(timezone.utc).isoformat()
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cur = conn.execute(
        f"""INSERT INTO soil_readings
            ({', '.join(FIELDS)}, source, field, timestamp)
            VALUES ({', '.join(['?'] * len(FIELDS))}, ?, ?, ?)""",
        [data.get(f) for f in FIELDS] + [source, field, ts],
    )
    conn.commit()
    new_id = cur.lastrowid
    row = conn.execute("SELECT * FROM soil_readings WHERE id = ?", (new_id,)).fetchone()
    conn.close()
    return _row_to_dict(row)


def get_latest(field: str = "Field A") -> Optional[dict]:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    row = conn.execute(
        "SELECT * FROM soil_readings WHERE field = ? ORDER BY id DESC LIMIT 1", (field,)
    ).fetchone()
    conn.close()
    return _row_to_dict(row) if row else None


def get_history(field: str = "Field A", limit: int = 50) -> list[dict]:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT * FROM soil_readings WHERE field = ? ORDER BY id DESC LIMIT ?", (field, limit)
    ).fetchall()
    conn.close()
    return [_row_to_dict(r) for r in reversed(rows)]


# ── WebSocket connection manager ─────────────────────────────────────────
class ConnectionManager:
    def __init__(self):
        self.active: list = []

    async def connect(self, websocket):
        await websocket.accept()
        self.active.append(websocket)

    def disconnect(self, websocket):
        if websocket in self.active:
            self.active.remove(websocket)

    async def broadcast(self, payload: dict):
        dead = []
        message = json.dumps(payload)
        for ws in self.active:
            try:
                await ws.send_text(message)
            except Exception:
                dead.append(ws)
        for ws in dead:
            self.disconnect(ws)


manager = ConnectionManager()

# tracks last time a REAL (non-simulated) reading was ingested, per field
_last_real_ts: dict[str, float] = {}


# ── Ingestion (called by the /soil/ingest route when ESP32 posts data) ──
async def ingest_reading(data: dict, field: str = "Field A") -> dict:
    row = insert_reading(data, source="sensor", field=field)
    _last_real_ts[field] = asyncio.get_event_loop().time()
    await manager.broadcast(row)
    return row


# ── Simulator ─────────────────────────────────────────────────────────────
def _load_dataset() -> list[dict]:
    with open(DATASET_PATH, newline="") as f:
        reader = csv.DictReader(f)
        return [{k: float(v) for k, v in r.items()} for r in reader]


async def start_simulator(field: str = "Field A"):
    """
    Background task: call once at app startup, e.g.
        asyncio.create_task(start_simulator())
    Replays dataset rows with small random-walk noise whenever no real
    sensor reading has come in recently.
    """
    init_db()
    dataset = _load_dataset()
    idx = random.randrange(len(dataset))

    while True:
        now = asyncio.get_event_loop().time()
        last_real = _last_real_ts.get(field, 0)
        is_real_fresh = (now - last_real) < SIMULATION_TIMEOUT_S

        if not is_real_fresh:
            base = dataset[idx % len(dataset)]
            idx += 1
            noisy = {
                "nitrogen": round(base["nitrogen"] + random.uniform(-1.5, 1.5), 1),
                "phosphorus": round(base["phosphorus"] + random.uniform(-1.5, 1.5), 1),
                "potassium": round(base["potassium"] + random.uniform(-1.5, 1.5), 1),
                "ph": round(base["ph"] + random.uniform(-0.1, 0.1), 2),
                "moisture": round(base["moisture"] + random.uniform(-2, 2), 1),
                "organic_matter": round(base["organic_matter"] + random.uniform(-0.1, 0.1), 2),
                "zinc": round(base["zinc"] + random.uniform(-0.1, 0.1), 2),
                "iron": round(base["iron"] + random.uniform(-0.2, 0.2), 2),
            }
            row = insert_reading(noisy, source="simulated", field=field)
            await manager.broadcast(row)

        await asyncio.sleep(SIMULATION_INTERVAL_S)