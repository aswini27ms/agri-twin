import time
from sqlalchemy.orm import Session
from backend.database import models
from typing import Optional
from backend.ai.gemma_service import call_gemma, GemmaUnavailableError

HEALTHY_DISEASE_NAMES = {"Tomato_Healthy"}

class VillageIntelligenceService:
    def __init__(self, db: Session):
        self.db = db

    def share_alert(self, cell: dict, village_id: str, device_id: str, farm_name: str = "Unknown Farm", only_if_risky: bool = True):
        if only_if_risky and cell["disease"] in HEALTHY_DISEASE_NAMES:
            return None

        packet = models.VillageAlert(
            village_id=village_id,
            device_id=device_id,
            farm_name=farm_name,
            grid_id=cell["grid_id"],
            crop=cell.get("crop", "Unknown"),
            disease=cell["disease"],
            severity=cell.get("severity", 0.0),
            risk_level=cell.get("risk_level", "Unknown"),
            confidence_pct=cell.get("confidence", 0.0) * 100 if cell.get("confidence") else 0.0,
            temperature=cell.get("temperature", 0.0),
            humidity=cell.get("humidity", 0.0),
            soil_moisture=cell.get("soil_moisture", 0.0),
            timestamp=time.time()
        )
        self.db.add(packet)
        self.db.commit()
        self.db.refresh(packet)
        
        return {
            "id": packet.id,
            "village_id": packet.village_id,
            "device_id": packet.device_id,
            "farm_name": packet.farm_name,
            "grid_id": packet.grid_id,
            "disease": packet.disease,
            "severity": packet.severity,
            "timestamp": packet.timestamp
        }

    def get_alerts(self, village_id: Optional[str] = None, since_hours: float = 24):
        cutoff = time.time() - since_hours * 3600
        query = self.db.query(models.VillageAlert).filter(models.VillageAlert.timestamp >= cutoff)
        if village_id:
            query = query.filter(models.VillageAlert.village_id == village_id)
        
        alerts = query.order_by(models.VillageAlert.timestamp.desc()).all()
        return [
            {
                "id": a.id,
                "village_id": a.village_id,
                "device_id": a.device_id,
                "farm_name": a.farm_name,
                "grid_id": a.grid_id,
                "crop": a.crop,
                "disease": a.disease,
                "severity": a.severity,
                "risk_level": a.risk_level,
                "confidence_pct": a.confidence_pct,
                "temperature": a.temperature,
                "humidity": a.humidity,
                "soil_moisture": a.soil_moisture,
                "timestamp": a.timestamp
            } for a in alerts
        ]

    def reset(self):
        self.db.query(models.VillageAlert).delete()
        self.db.commit()

    def _rule_based_summary(self, alerts: list, since_hours: float) -> dict:
        if not alerts:
            return {
                "headline": "No disease alerts reported in the village recently.",
                "disease_counts": {}, "affected_farms": 0, "affected_grids": 0,
                "high_risk_count": 0, "window_hours": since_hours,
            }

        disease_counts: dict = {}
        farms, grids = set(), set()
        high_risk = 0

        for a in alerts:
            readable = a["disease"].replace("_", " ")
            disease_counts[readable] = disease_counts.get(readable, 0) + 1
            farms.add(a["device_id"])
            grids.add(f"{a['device_id']}:{a['grid_id']}")
            if a["risk_level"] == "High Risk":
                high_risk += 1

        top_disease, top_count = max(disease_counts.items(), key=lambda kv: kv[1])
        humidity_vals = [a["humidity"] for a in alerts if a.get("humidity") is not None]
        avg_humidity = round(sum(humidity_vals) / len(alerts), 1) if humidity_vals else 0

        headline = (
            f"{top_count} nearby farm(s) reported {top_disease} in the last {int(since_hours)} hours "
            f"across {len(farms)} device(s). Average humidity {avg_humidity}%"
            + (" - high humidity may be accelerating spread." if avg_humidity >= 70 else ".")
        )

        return {
            "headline": headline, "disease_counts": disease_counts,
            "affected_farms": len(farms), "affected_grids": len(grids),
            "high_risk_count": high_risk, "window_hours": since_hours,
        }

    def _gemma_narrate(self, summary_stats: dict) -> str:
        import json
        prompt = (
            "Here are village-wide crop disease alert stats from the last "
            f"{int(summary_stats['window_hours'])} hours:\n\n"
            + json.dumps(summary_stats, indent=2)
            + "\n\nRewrite this as 2-3 short, plain-language sentences a farmer with no "
            "technical background would understand. Do not invent numbers that aren't given. "
            "Reply with the sentences only, nothing else."
        )
        return call_gemma(prompt, extra_system="You are summarizing a village-wide alert, not a single grid.")

    def get_village_summary(self, village_id: Optional[str] = None, since_hours: float = 24, narrate: bool = True) -> dict:
        alerts = self.get_alerts(village_id=village_id, since_hours=since_hours)
        stats = self._rule_based_summary(alerts, since_hours)

        narrative, source = stats["headline"], "rule_based"
        if narrate and alerts:
            try:
                narrative = self._gemma_narrate(stats)
                source = "gemma"
            except GemmaUnavailableError:
                pass 

        return {
            "village_id": village_id,
            "stats": stats,
            "narrative": narrative,
            "narrative_source": source,
            "recent_alerts": alerts[:10],
        }
