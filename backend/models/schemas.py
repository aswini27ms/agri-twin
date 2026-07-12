from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime

# Sensor Data
class SensorData(BaseModel):
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    soil_moisture: Optional[float] = None
    last_updated: Optional[str] = None

class SensorUpdateResponse(BaseModel):
    status: str
    reading: SensorData

# Digital Twin Cell
class RecommendationData(BaseModel):
    water_required: Optional[str] = None
    water_amount_liters: Optional[float] = None
    pesticide: Optional[str] = None
    fertilizer_guidance: Optional[str] = None
    nitrogen_advice: Optional[str] = None
    priority: Optional[str] = None
    recheck_in_hours: Optional[int] = None

class GridCellSchema(BaseModel):
    grid_id: str
    crop: Optional[str] = None
    disease: str
    confidence: Optional[float] = None
    severity: float
    risk_level: str
    status_color: str
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    soil_moisture: Optional[float] = None
    crop_age_days: Optional[int] = None
    recommendation: Optional[RecommendationData] = None
    last_updated: Optional[str] = None

class CellHistorySchema(BaseModel):
    timestamp: str
    event: str
    disease: str
    severity: float
    status_color: str

# Scan Response
class ScanResponse(BaseModel):
    pipeline_result: Dict[str, Any]
    grid_cell: GridCellSchema
    farm_health: Dict[str, Any]

# Gemma Chat
class ExplainRequest(BaseModel):
    grid_id: str

class ChatRequest(BaseModel):
    message: str
    grid_id: Optional[str] = None

# Village
class ShareAlertRequest(BaseModel):
    grid_id: str
    village_id: Optional[str] = None
    device_id: Optional[str] = None
    farm_name: Optional[str] = None
