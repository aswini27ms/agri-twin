import asyncio
import json
import logging
from typing import Callable

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

# Broadcast helper
from backend.websocket_manager import manager

# DB utilities (adjust imports if your project structure differs)
from backend.database.db import get_db
from backend.database import models

logger = logging.getLogger(__name__)


class SensorService:
    """
    Background service that:
    • Listens to an MQTT topic (default: localhost/arduino/sensor)
    • Reads lines from a serial port (default: COM3 @115200)
    • Stores each JSON payload in the DB
    • Broadcasts the payload to all connected WebSocket clients
    """

    def __init__(self, db_dep: Callable[..., AsyncSession] = Depends(get_db)):
        self._db_dep = db_dep
        self._mqtt_task: asyncio.Task | None = None
        self._serial_task: asyncio.Task | None = None
        self._stop_event = asyncio.Event()

    async def start(self) -> None:
        """Spawn the MQTT & Serial background tasks."""
        logger.info("Starting SensorService background tasks")
        self._mqtt_task = asyncio.create_task(self._mqtt_listener())
        self._serial_task = asyncio.create_task(self._serial_reader())

    async def stop(self) -> None:
        """Signal the tasks to stop and wait for them."""
        logger.info("Stopping SensorService background tasks")
        self._stop_event.set()
        tasks = [t for t in (self._mqtt_task, self._serial_task) if t]
        for t in tasks:
            t.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)
        logger.info("SensorService stopped")

    # ------------------------------------------------------------------ #
    # MQTT listener
    # ------------------------------------------------------------------ #
    async def _mqtt_listener(self) -> None:
        """Connect to the MQTT broker and forward each message with auto-reconnect."""
        from asyncio_mqtt import Client, MqttError

        BROKER_HOST = "localhost"
        TOPIC = "arduino/sensor"

        while not self._stop_event.is_set():
            try:
                async with Client(BROKER_HOST) as client:
                    async with client.unfiltered_messages() as messages:
                        await client.subscribe(TOPIC)
                        logger.info(f"Subscribed to MQTT topic '{TOPIC}'")
                        async for message in messages:
                            if self._stop_event.is_set():
                                break
                            payload = message.payload.decode()
                            await self._process_message(payload)
            except (MqttError, Exception) as exc:
                if self._stop_event.is_set():
                    break
                logger.debug(f"MQTT connection attempt failed: {exc}. Retrying in 5 seconds...")
                await asyncio.sleep(5)

    # ------------------------------------------------------------------ #
    # Serial reader
    # ------------------------------------------------------------------ #
    async def _serial_reader(self) -> None:
        """Read newline‑terminated JSON strings from the serial port."""
        import serial_asyncio

        SERIAL_PORT = "COM3"
        BAUDRATE = 115_200

        try:
            reader, _ = await serial_asyncio.open_serial_connection(
                url=SERIAL_PORT, baudrate=BAUDRATE
            )
            logger.info(f"Opened serial connection on {SERIAL_PORT} ({BAUDRATE} baud)")
            while not self._stop_event.is_set():
                line = await reader.readline()
                if not line:
                    continue
                payload = line.decode().strip()
                await self._process_message(payload)
        except Exception as exc:
            logger.error(f"Serial reader error: {exc}")

    # ------------------------------------------------------------------ #
    # Common processor
    # ------------------------------------------------------------------ #
    async def _process_message(self, payload: str) -> None:
        """Validate JSON, store it, and broadcast."""
        try:
            data = json.loads(payload)
        except json.JSONDecodeError:
            logger.warning(f"Invalid JSON from sensor: {payload!r}")
            return

        # ---- Store in DB -------------------------------------------------
        from backend.database.db import SessionLocal
        from datetime import datetime

        db = SessionLocal()
        try:
            reading = models.SensorReading(
                temperature=data.get("temperature"),
                humidity=data.get("humidity"),
                soil_moisture=data.get("soil_moisture"),
                timestamp=datetime.utcnow()
            )
            db.add(reading)
            db.commit()
        except Exception as exc:
            logger.error(f"Failed to store sensor reading in DB: {exc}")
            db.rollback()
        finally:
            db.close()

        # ---- Broadcast to WebSocket clients -------------------------------
        data["last_updated"] = datetime.utcnow().isoformat()
        await manager.broadcast(json.dumps(data))


# Global singleton that FastAPI will use
service = SensorService()