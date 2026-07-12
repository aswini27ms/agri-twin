from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from backend.database.db import get_db
from backend.services.digital_twin_service import DigitalTwinService

router = APIRouter(prefix="/irrigation", tags=["Irrigation"])

def get_dt(db: Session = Depends(get_db)):
    return DigitalTwinService(db)

@router.post("/")
def calculate_irrigation(db: Session = Depends(get_db), dt: DigitalTwinService = Depends(get_dt)):
    cells = dt.get_all_cells() if hasattr(dt, 'get_all_cells') else dt.to_dict()["grid"].values()
    
    total_water_liters = 0.0
    grids_needing_water = []

    for cell in cells:
        rec = cell.get("recommendation")
        if rec and rec.get("water_required") == "YES":
            amount = rec.get("water_amount_liters", 0.0)
            total_water_liters += amount
            grids_needing_water.append({
                "grid_id": cell["grid_id"],
                "amount": amount
            })

    return {
        "status": "calculated",
        "total_water_liters_required": round(total_water_liters, 1),
        "grids_needing_water": grids_needing_water
    }
