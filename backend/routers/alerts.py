from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional

from backend.database.db import get_db
from backend.services.digital_twin_service import DigitalTwinService
from backend.services.village_intelligence_service import VillageIntelligenceService
from backend.models.schemas import ShareAlertRequest

router = APIRouter(prefix="/village", tags=["Village Alerts"])

VILLAGE_ID = "coimbatore-north-01"
DEVICE_ID = "farm-device-01"
FARM_NAME = "Demo Farm 1"

def get_dt(db: Session = Depends(get_db)):
    return DigitalTwinService(db)

def get_vi(db: Session = Depends(get_db)):
    return VillageIntelligenceService(db)

@router.post("/share")
def village_share(req: ShareAlertRequest, db: Session = Depends(get_db), dt: DigitalTwinService = Depends(get_dt), vi: VillageIntelligenceService = Depends(get_vi)):
    cell = dt.get_cell(req.grid_id)
    if not cell or cell["disease"] == "Unscanned":
        raise HTTPException(status_code=400, detail="Grid hasn't been scanned yet")

    packet = vi.share_alert(
        cell=cell,
        village_id=req.village_id or VILLAGE_ID,
        device_id=req.device_id or DEVICE_ID,
        farm_name=req.farm_name or FARM_NAME,
    )
    if packet is None:
        return {"stored": False, "reason": "healthy scan, no alert needed"}
    return {"stored": True, "alert": packet}

@router.get("/alerts")
def village_alerts(village_id: Optional[str] = None, hours: float = 24, vi: VillageIntelligenceService = Depends(get_vi)):
    alerts = vi.get_alerts(village_id=village_id or VILLAGE_ID, since_hours=hours)
    return {"count": len(alerts), "alerts": alerts}

@router.get("/summary")
def village_summary(village_id: Optional[str] = None, hours: float = 24, narrate: bool = True, vi: VillageIntelligenceService = Depends(get_vi)):
    return vi.get_village_summary(village_id=village_id or VILLAGE_ID, since_hours=hours, narrate=narrate)

@router.post("/reset")
def village_reset(vi: VillageIntelligenceService = Depends(get_vi)):
    vi.reset()
    return {"status": "reset", "alerts_total": 0}
