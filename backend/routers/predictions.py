from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from typing import Optional

from backend.database.db import get_db
from backend.services.digital_twin_service import DigitalTwinService
from backend.services.village_intelligence_service import VillageIntelligenceService
from backend.ai.disease_model import full_digital_twin_pipeline
from backend.models.schemas import ScanResponse

router = APIRouter(prefix="/predict", tags=["Predictions"])

# For demo purposes
VILLAGE_ID = "coimbatore-north-01"
DEVICE_ID = "farm-device-01"
FARM_NAME = "Demo Farm 1"

def get_dt(db: Session = Depends(get_db)):
    return DigitalTwinService(db)

def get_vi(db: Session = Depends(get_db)):
    return VillageIntelligenceService(db)

@router.post("/scan", response_model=ScanResponse)
async def scan_crop(
    image: UploadFile = File(...),
    grid_id: str = Form(...),
    temperature: Optional[float] = Form(None),
    humidity: Optional[float] = Form(None),
    soil_moisture: Optional[float] = Form(None),
    crop_age_days: int = Form(...),
    previous_severity: float = Form(0.3),
    db: Session = Depends(get_db),
    dt: DigitalTwinService = Depends(get_dt),
    vi: VillageIntelligenceService = Depends(get_vi)
):
    cell = dt.get_cell(grid_id)
    if not cell:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid grid_id '{grid_id}'. Must be a valid grid cell.",
        )

    if temperature is None or humidity is None or soil_moisture is None:
        # Fall back to latest sensor reading
        from backend.database import models
        reading = db.query(models.SensorReading).order_by(models.SensorReading.timestamp.desc()).first()
        if not reading:
            temperature = temperature if temperature is not None else 28.5
            humidity = humidity if humidity is not None else 65.0
            soil_moisture = soil_moisture if soil_moisture is not None else 45.0
        else:
            if temperature is None: temperature = reading.temperature
            if humidity is None: humidity = reading.humidity
            if soil_moisture is None: soil_moisture = reading.soil_moisture

    image_bytes = await image.read()
    
    # Run AI inference
    result = full_digital_twin_pipeline(
        image_bytes, temperature, humidity, soil_moisture, crop_age_days, previous_severity
    )
    
    sensor_data = {
        "temperature": temperature, 
        "humidity": humidity,
        "soil_moisture": soil_moisture, 
        "crop_age_days": crop_age_days
    }
    
    updated_cell = dt.update_cell(grid_id, result, sensor_data)
    
    # Share to village intelligence
    try:
        vi.share_alert(cell=updated_cell, village_id=VILLAGE_ID, device_id=DEVICE_ID, farm_name=FARM_NAME)
    except Exception as e:
        print(f"Failed to share alert: {e}")

    return {
        "pipeline_result": result,
        "grid_cell": updated_cell,
        "farm_health": dt.compute_health_score()
    }

@router.get("/yield")
def predict_yield(crop: str, db: Session = Depends(get_db)):
    from backend.database import models
    reading = db.query(models.SensorReading).order_by(models.SensorReading.timestamp.desc()).first()
    
    crop_data = {
        'Sweet Corn': {'base': 3.5, 'max': 5.0, 'unit': 'ton/acre', 'lastYear': 3.8},
        'Roma Tomato': {'base': 10.0, 'max': 14.0, 'unit': 'ton/acre', 'lastYear': 11.0},
        'Rice': {'base': 2.5, 'max': 3.5, 'unit': 'ton/acre', 'lastYear': 2.7},
        'Wheat': {'base': 2.0, 'max': 3.0, 'unit': 'ton/acre', 'lastYear': 2.2},
    }
    cd = crop_data.get(crop, {'base': 3.0, 'max': 4.0, 'unit': 'ton/acre', 'lastYear': 3.0})
    
    temp = reading.temperature if reading and reading.temperature else 28.0
    hum = reading.humidity if reading and reading.humidity else 60.0
    soil = reading.soil_moisture if reading and reading.soil_moisture else 40.0
    
    soil_score = min(100, int((soil / 50.0) * 100))
    rain_score = min(100, int((hum / 80.0) * 100))
    temp_score = min(100, max(0, int(100 - abs(28.0 - temp) * 3)))
    
    dt = DigitalTwinService(db)
    health = dt.compute_health_score()
    pest_risk_score = int(health.get("farm_health_score", 100))
    
    confidence = int((soil_score + rain_score + temp_score + pest_risk_score) / 4)
    yield_val = round(cd['base'] + (cd['max'] - cd['base']) * (confidence / 100.0), 1)
    
    grade = 'A' if confidence > 85 else 'B+' if confidence > 75 else 'B' if confidence > 65 else 'C'
    grade_color = 0xFF4CAF50 if grade == 'A' else 0xFF8BC34A if grade == 'B+' else 0xFFFF7043
    
    return {
        'predicted': yield_val,
        'unit': cd['unit'],
        'lastYear': cd['lastYear'],
        'confidence': confidence,
        'grade': grade,
        'gradeColor': grade_color,
        'factors': [
            {'label': 'Soil Quality', 'score': soil_score, 'color': 0xFF795548},
            {'label': 'Rainfall', 'score': rain_score, 'color': 0xFF42A5F5},
            {'label': 'Temperature', 'score': temp_score, 'color': 0xFFFF7043},
            {'label': 'Pest Risk', 'score': pest_risk_score, 'color': 0xFFAB47BC},
        ],
        'monthly': [
            round(yield_val * 0.7, 1),
            round(yield_val * 0.8, 1),
            round(yield_val * 0.9, 1),
            round(yield_val * 0.95, 1),
            yield_val,
            yield_val
        ]
    }
