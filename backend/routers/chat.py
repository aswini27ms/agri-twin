from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Optional

from backend.database.db import get_db
from backend.services.digital_twin_service import DigitalTwinService
from backend.ai.gemma_service import (
    build_gemma_context, explain_context, chat_reply,
    GemmaUnavailableError, warmup_gemma, OLLAMA_URL, GEMMA_MODEL,
)
from backend.ai.explainability import get_full_explanation
from backend.models.schemas import ExplainRequest, ChatRequest
from backend.database import models
from backend.services.village_intelligence_service import VillageIntelligenceService

import requests as _requests

router = APIRouter(prefix="/gemma", tags=["AI Assistant"])


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def get_dt(db: Session = Depends(get_db)):
    return DigitalTwinService(db)


def get_vi(db: Session = Depends(get_db)):
    return VillageIntelligenceService(db)


def get_scanned_cell_or_error(grid_id: str, dt: DigitalTwinService):
    cell = dt.get_cell(grid_id)
    if not cell:
        raise HTTPException(status_code=404, detail="Grid cell not found")
    if cell["disease"] == "Unscanned":
        raise HTTPException(status_code=400, detail="This grid hasn't been scanned yet")
    return cell


def _ollama_is_live() -> bool:
    try:
        # Hardcode base URL since OLLAMA_URL from gemma_service includes /api/chat
        r = _requests.get("http://localhost:11434/api/tags", timeout=3)
        return r.status_code == 200
    except Exception:
        return False


# ─────────────────────────────────────────────────────────────────────────────
# Explain endpoints
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/explain")
def gemma_explain(req: ExplainRequest, dt: DigitalTwinService = Depends(get_dt)):
    cell = get_scanned_cell_or_error(req.grid_id, dt)
    health = dt.compute_health_score()["farm_health_score"]
    context = build_gemma_context(cell, health)
    try:
        explanation = explain_context(context)
    except GemmaUnavailableError as e:
        raise HTTPException(status_code=503, detail=str(e))
    return {"grid_id": req.grid_id, "context_used": context, "explanation": explanation}


@router.get("/explain/{grid_id}")
def get_cell_explanation(grid_id: str, dt: DigitalTwinService = Depends(get_dt)):
    cell = get_scanned_cell_or_error(grid_id, dt)
    health = dt.compute_health_score()["farm_health_score"]
    return get_full_explanation(cell, health)


# ─────────────────────────────────────────────────────────────────────────────
# Chat history
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/chat")
def get_chat_history(db: Session = Depends(get_db)):
    history = (
        db.query(models.ChatHistory)
        .order_by(models.ChatHistory.timestamp.asc())
        .all()
    )
    return {"history": [{"role": h.role, "message": h.message} for h in history]}


# ─────────────────────────────────────────────────────────────────────────────
# Chat POST  — with auto-retry if Ollama just woke up
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/chat")
def gemma_chat_endpoint(
    req: ChatRequest,
    db: Session = Depends(get_db),
    dt: DigitalTwinService = Depends(get_dt),
    vi: VillageIntelligenceService = Depends(get_vi),
):
    # ── 1. Quick Ollama health check before spending time building context ──
    if not _ollama_is_live():
        raise HTTPException(
            status_code=503,
            detail=(
                "Gemma (Ollama) is still starting up. "
                "Please wait a few seconds and try again."
            ),
        )

    # ── 2. Build context ───────────────────────────────────────────────────
    context = None
    health = dt.compute_health_score()["farm_health_score"]

    if req.grid_id:
        cell = get_scanned_cell_or_error(req.grid_id, dt)
        context = build_gemma_context(cell, health)
    else:
        # Global village/farm context
        summary = vi.get_village_summary(narrate=False)
        dt_stats = dt.compute_analytics()
        context = (
            f"The farm currently has an overall health score of {health} out of 100.\n"
            f"The farm has {dt_stats['healthy']} healthy grids, "
            f"{dt_stats['low_risk']} low risk grids, "
            f"{dt_stats['medium_risk']} medium risk grids, and "
            f"{dt_stats['high_risk']} high risk grids.\n"
        )

        grid_data = dt.to_dict().get("grid", {})
        infected = [
            c for c in grid_data.values()
            if c.get("disease") not in ["Unscanned", "Tomato_Healthy", None]
        ]
        if infected:
            context += "Here is the list of infected grids on the farm and their details:\n"
            for c in infected:
                context += (
                    f"- Grid {c['grid_id']}: {c['disease']} "
                    f"(Severity: {c.get('severity', 0)}%, Crop: {c.get('crop')})\n"
                )
        else:
            context += "There are currently no infected grids on the farm.\n"

        if summary and summary.get("stats"):
            stats = summary["stats"]
            context += (
                f"In the village, there have been {stats.get('affected_farms', 0)} affected farms recently. "
                f"The most common issues in the village are: {stats.get('disease_counts', {})}.\n"
            )

    # ── 3. Call Gemma ──────────────────────────────────────────────────────
    try:
        reply = chat_reply(req.message, context=context)
    except GemmaUnavailableError as e:
        raise HTTPException(status_code=503, detail=str(e))

    # ── 4. Persist chat history ────────────────────────────────────────────
    db.add(models.ChatHistory(role="user",      message=req.message, grid_id=req.grid_id))
    db.add(models.ChatHistory(role="assistant", message=reply,       grid_id=req.grid_id))
    db.commit()

    return {"reply": reply, "context_used": context}


# ─────────────────────────────────────────────────────────────────────────────
# Warmup endpoint (call manually from Flutter or dev tooling)
# ─────────────────────────────────────────────────────────────────────────────

@router.post("/warmup")
def trigger_warmup():
    """Manually trigger a Gemma warmup ping."""
    if not _ollama_is_live():
        raise HTTPException(status_code=503, detail="Ollama is not running.")
    ok = warmup_gemma()
    return {"success": ok, "model": GEMMA_MODEL}
