from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
import datetime
from .db import Base

class SensorReading(Base):
    __tablename__ = "sensor_readings"
    
    id = Column(Integer, primary_key=True, index=True)
    temperature = Column(Float, nullable=True)
    humidity = Column(Float, nullable=True)
    soil_moisture = Column(Float, nullable=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)

class GridCell(Base):
    __tablename__ = "grid_cells"
    
    grid_id = Column(String, primary_key=True, index=True)
    crop = Column(String, nullable=True)
    disease = Column(String, default="Unscanned")
    confidence = Column(Float, nullable=True)
    severity = Column(Float, default=0.0)
    risk_level = Column(String, default="Unknown")
    status_color = Column(String, default="gray")
    temperature = Column(Float, nullable=True)
    humidity = Column(Float, nullable=True)
    soil_moisture = Column(Float, nullable=True)
    crop_age_days = Column(Integer, nullable=True)
    recommendation_json = Column(String, nullable=True) # store as JSON string
    last_updated = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

class CellHistory(Base):
    __tablename__ = "cell_history"
    
    id = Column(Integer, primary_key=True, index=True)
    grid_id = Column(String, ForeignKey("grid_cells.grid_id"))
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    event = Column(String)
    disease = Column(String)
    severity = Column(Float)
    status_color = Column(String)
    
    cell = relationship("GridCell")

class FarmHealthHistory(Base):
    __tablename__ = "farm_health_history"
    
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    farm_health_score = Column(Float)

class VillageAlert(Base):
    __tablename__ = "village_alerts"
    
    id = Column(Integer, primary_key=True, index=True)
    village_id = Column(String, index=True)
    device_id = Column(String)
    farm_name = Column(String)
    grid_id = Column(String)
    crop = Column(String)
    disease = Column(String)
    severity = Column(Float)
    risk_level = Column(String)
    confidence_pct = Column(Float)
    temperature = Column(Float)
    humidity = Column(Float)
    soil_moisture = Column(Float)
    timestamp = Column(Float) # UNIX timestamp for ease of use in vi layer

class ChatHistory(Base):
    __tablename__ = "chat_history"
    
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    role = Column(String) # 'user' or 'assistant'
    message = Column(String)
    grid_id = Column(String, nullable=True)
