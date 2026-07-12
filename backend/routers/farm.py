from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from backend.database.db import get_db
from backend.services.digital_twin_service import DigitalTwinService

router = APIRouter(prefix="/farm", tags=["Farm"])

def get_dt(db: Session = Depends(get_db)):
    return DigitalTwinService(db)

@router.get("/twin")
def get_twin_state(dt: DigitalTwinService = Depends(get_dt)):
    return dt.to_dict()

@router.get("/twin/cell/{grid_id}")
def get_cell(grid_id: str, dt: DigitalTwinService = Depends(get_dt)):
    cell = dt.get_cell(grid_id)
    if not cell:
        raise HTTPException(status_code=404, detail="Grid cell not found")
    return cell

@router.get("/twin/cell/{grid_id}/neighbors")
def get_cell_neighbors(grid_id: str, dt: DigitalTwinService = Depends(get_dt)):
    return dt.get_spread_risk_neighbors(grid_id)

@router.get("/twin/cell/{grid_id}/history")
def get_cell_history(grid_id: str, dt: DigitalTwinService = Depends(get_dt)):
    return {"history": dt.get_cell_history(grid_id)}

@router.get("/health")
def get_health(dt: DigitalTwinService = Depends(get_dt)):
    return dt.compute_health_score()

@router.get("/health/history")
def get_health_history(dt: DigitalTwinService = Depends(get_dt)):
    return {"history": dt.get_health_history()}

@router.get("/analytics")
def get_analytics(dt: DigitalTwinService = Depends(get_dt)):
    return dt.compute_analytics()

@router.get("/timeline")
def get_timeline(dt: DigitalTwinService = Depends(get_dt)):
    return {"timeline": dt.get_timeline()}

@router.get("/simulate")
def simulate(hours: int = 24, dt: DigitalTwinService = Depends(get_dt)):
    if hours not in (24, 48, 72):
        raise HTTPException(status_code=400, detail="hours must be 24, 48, or 72")
    return dt.simulate_future(hours)

@router.post("/twin/reset")
def reset_twin(dt: DigitalTwinService = Depends(get_dt)):
    dt.reset_twin()
    return {"status": "reset", "grids_total": dt.rows * dt.cols}
