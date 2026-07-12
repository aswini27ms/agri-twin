from fastapi import APIRouter, Depends, Form
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional

from backend.database.db import get_db
from backend.database import models
from backend.models.schemas import SensorUpdateResponse

router = APIRouter(prefix="/sensors", tags=["Sensors"])

@router.post("/update", response_model=SensorUpdateResponse)
def update_sensors(
    temperature: float = Form(...),
    humidity: float = Form(...),
    soil_moisture: float = Form(...),
    db: Session = Depends(get_db)
):
    now = datetime.utcnow()
    reading = models.SensorReading(
        temperature=temperature,
        humidity=humidity,
        soil_moisture=soil_moisture,
        timestamp=now
    )
    db.add(reading)
    db.commit()
    db.refresh(reading)
    
    return {
        "status": "ok",
        "reading": {
            "temperature": reading.temperature,
            "humidity": reading.humidity,
            "soil_moisture": reading.soil_moisture,
            "last_updated": reading.timestamp.isoformat()
        }
    }

@router.get("/latest")
def get_latest_sensors(db: Session = Depends(get_db)):
    reading = db.query(models.SensorReading).order_by(models.SensorReading.timestamp.desc()).first()
    if reading:
        return {
            "temperature": reading.temperature,
            "humidity": reading.humidity,
            "soil_moisture": reading.soil_moisture,
            "last_updated": reading.timestamp.isoformat()
        }
    return {"temperature": None, "humidity": None, "soil_moisture": None, "last_updated": None}

@router.get("/status")
def get_sensor_status(db: Session = Depends(get_db)):
    reading = db.query(models.SensorReading).order_by(models.SensorReading.timestamp.desc()).first()
    if not reading:
        return {"connected": False, "seconds_since_update": None}
    
    seconds = (datetime.utcnow() - reading.timestamp).total_seconds()
    return {
        "connected": seconds < 15,
        "seconds_since_update": round(seconds, 1),
        "reading": {
            "temperature": reading.temperature,
            "humidity": reading.humidity,
            "soil_moisture": reading.soil_moisture,
            "last_updated": reading.timestamp.isoformat()
        }
    }
