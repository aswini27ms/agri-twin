"""
routers/soil.py
----------------
Mount this in main.py:

    from routers import soil as soil_router
    app.include_router(soil_router.router)

And start the simulator fallback at startup (see main_integration.py for
the exact snippet to paste into your existing main.py).
"""

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, HTTPException
from pydantic import BaseModel, Field

from backend.services import soil_service

router = APIRouter(prefix="/soil", tags=["soil"])


class SoilReadingIn(BaseModel):
    nitrogen: float = Field(..., ge=0)
    phosphorus: float = Field(..., ge=0)
    potassium: float = Field(..., ge=0)
    ph: float = Field(..., ge=0, le=14)
    moisture: float = Field(..., ge=0, le=100)
    organic_matter: float = Field(..., ge=0)
    zinc: float = Field(..., ge=0)
    iron: float = Field(..., ge=0)
    field: str = "Field A"


@router.post("/ingest")
async def ingest(reading: SoilReadingIn):
    """ESP32 / real sensor posts here. Takes over from the simulator automatically."""
    data = reading.model_dump(exclude={"field"})
    row = await soil_service.ingest_reading(data, field=reading.field)
    return {"status": "ok", "reading": row}


@router.get("/latest")
async def latest(field: str = "Field A"):
    row = soil_service.get_latest(field)
    if not row:
        raise HTTPException(status_code=404, detail="No readings yet")
    return row


@router.get("/history")
async def history(field: str = "Field A", limit: int = 50):
    return soil_service.get_history(field, limit)


@router.websocket("/ws")
async def soil_ws(websocket: WebSocket):
    """Flutter connects here for live push updates."""
    await soil_service.manager.connect(websocket)
    try:
        # Send the latest known reading immediately on connect
        latest_row = soil_service.get_latest()
        if latest_row:
            await websocket.send_json(latest_row)

        while True:
            # We don't need client messages, but this keeps the connection alive
            # and detects disconnects promptly.
            await websocket.receive_text()
    except WebSocketDisconnect:
        soil_service.manager.disconnect(websocket)