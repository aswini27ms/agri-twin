import math
import json
from datetime import datetime
from sqlalchemy.orm import Session
from backend.database import models

class DigitalTwinService:
    def __init__(self, db: Session, rows: int = 6, cols: int = 6):
        self.db = db
        self.rows = rows
        self.cols = cols
        self.MAX_TIMELINE = 50
        self.MAX_HEALTH_HISTORY = 200

        # Ensure grid cells exist in DB
        existing_count = self.db.query(models.GridCell).count()
        if existing_count < (rows * cols):
            for r in range(rows):
                for c in range(cols):
                    grid_id = f"{chr(65 + r)}{c + 1}"
                    if not self.db.query(models.GridCell).filter(models.GridCell.grid_id == grid_id).first():
                        new_cell = models.GridCell(grid_id=grid_id)
                        self.db.add(new_cell)
            self.db.commit()

    def _status_color(self, disease: str, severity: float) -> str:
        if disease is None or disease == "Unscanned":
            return "gray"
        if disease == "Tomato_Healthy":
            return "green"
        if severity >= 70:
            return "red"
        if severity >= 40:
            return "orange"
        if severity > 0:
            return "yellow"
        return "green"

    def update_cell(self, grid_id: str, pipeline_result: dict, sensor_data: dict) -> dict:
        cell = self.db.query(models.GridCell).filter(models.GridCell.grid_id == grid_id).first()
        if not cell:
            cell = models.GridCell(grid_id=grid_id)
            self.db.add(cell)

        old_color = cell.status_color
        was_unscanned = cell.disease == "Unscanned"

        crop_type = "Tomato" if "Tomato" in pipeline_result["disease"] else \
                    "Rice" if "Rice" in pipeline_result["disease"] else cell.crop

        new_color = self._status_color(pipeline_result["disease"], pipeline_result["spread_risk"])
        now = datetime.utcnow()

        cell.crop = crop_type
        cell.disease = pipeline_result["disease"]
        cell.confidence = pipeline_result["confidence"]
        cell.severity = pipeline_result["spread_risk"]
        cell.risk_level = pipeline_result["risk_level"]
        cell.status_color = new_color
        cell.temperature = sensor_data.get("temperature")
        cell.humidity = sensor_data.get("humidity")
        cell.soil_moisture = sensor_data.get("soil_moisture")
        cell.crop_age_days = sensor_data.get("crop_age_days")
        cell.recommendation_json = json.dumps(pipeline_result.get("recommendation", {}))
        cell.last_updated = now
        
        self.db.commit()

        # Add history entries
        if was_unscanned:
            self._add_history(grid_id, "Scanned", pipeline_result, new_color, now)
        else:
            self._add_history(grid_id, "Re-scanned", pipeline_result, new_color, now)
            
        self._add_history(grid_id, f"Risk updated to {pipeline_result['spread_risk']}%", pipeline_result, new_color, now)
        
        if pipeline_result.get("recommendation"):
            self._add_history(grid_id, "Recommendation generated", pipeline_result, new_color, now)

        self._log_health_snapshot(now)
        
        # We don't have a specific global timeline table in DB, we rely on CellHistory.
        return self._cell_to_dict(cell)

    def _add_history(self, grid_id, event, result, color, now):
        hist = models.CellHistory(
            grid_id=grid_id,
            timestamp=now,
            event=event,
            disease=result["disease"],
            severity=result["spread_risk"],
            status_color=color
        )
        self.db.add(hist)
        self.db.commit()

    def _log_health_snapshot(self, now):
        score = self.compute_health_score()["farm_health_score"]
        fh = models.FarmHealthHistory(timestamp=now, farm_health_score=score)
        self.db.add(fh)
        self.db.commit()
        
        # Optional: Prune old history to keep size in check
        count = self.db.query(models.FarmHealthHistory).count()
        if count > self.MAX_HEALTH_HISTORY:
            oldest = self.db.query(models.FarmHealthHistory).order_by(models.FarmHealthHistory.timestamp.asc()).first()
            if oldest:
                self.db.delete(oldest)
                self.db.commit()

    def _cell_to_dict(self, cell: models.GridCell) -> dict:
        return {
            "grid_id": cell.grid_id,
            "crop": cell.crop,
            "disease": cell.disease,
            "confidence": cell.confidence,
            "severity": cell.severity,
            "risk_level": cell.risk_level,
            "status_color": cell.status_color,
            "temperature": cell.temperature,
            "humidity": cell.humidity,
            "soil_moisture": cell.soil_moisture,
            "crop_age_days": cell.crop_age_days,
            "recommendation": json.loads(cell.recommendation_json) if cell.recommendation_json else None,
            "last_updated": cell.last_updated.isoformat() if cell.last_updated else None,
            "history": self.get_cell_history(cell.grid_id)
        }

    def get_cell(self, grid_id: str) -> dict:
        cell = self.db.query(models.GridCell).filter(models.GridCell.grid_id == grid_id).first()
        if not cell:
            return None
        return self._cell_to_dict(cell)

    def get_cell_history(self, grid_id: str) -> list:
        hists = self.db.query(models.CellHistory).filter(models.CellHistory.grid_id == grid_id).order_by(models.CellHistory.timestamp.asc()).all()
        return [{
            "timestamp": h.timestamp.isoformat(),
            "event": h.event,
            "disease": h.disease,
            "severity": h.severity,
            "status_color": h.status_color
        } for h in hists]

    def get_timeline(self) -> list:
        hists = self.db.query(models.CellHistory).order_by(models.CellHistory.timestamp.desc()).limit(self.MAX_TIMELINE).all()
        return [{
            "timestamp": h.timestamp.isoformat(),
            "grid_id": h.grid_id,
            "event": h.event,
            "disease": h.disease,
            "severity": h.severity,
            "status_color": h.status_color
        } for h in hists]

    def get_health_history(self) -> list:
        hists = self.db.query(models.FarmHealthHistory).order_by(models.FarmHealthHistory.timestamp.asc()).all()
        return [{"timestamp": h.timestamp.isoformat(), "farm_health_score": h.farm_health_score} for h in hists]

    def compute_health_score(self) -> dict:
        cells = self.db.query(models.GridCell).all()
        scanned = [c for c in cells if c.disease != "Unscanned"]
        infected = [c for c in scanned if c.disease not in (None, "Tomato_Healthy")]

        if not scanned:
            return {
                "farm_health_score": 100, "grids_scanned": 0, "grids_total": len(cells),
                "infected_grids": 0, "average_risk": 0, "average_soil_moisture": None,
                "breakdown": {"disease_impact": 0, "moisture_stress": 0, "temp_stress": 0, "healthy_area_pct": 100},
            }

        avg_severity = sum(c.severity for c in scanned) / len(scanned)
        moisture_vals = [c.soil_moisture for c in scanned if c.soil_moisture is not None]
        avg_moisture = sum(moisture_vals) / max(1, len(moisture_vals)) if moisture_vals else 0
        moisture_deficit = max(0, 40 - avg_moisture)
        
        temp_vals = [c.temperature for c in scanned if c.temperature is not None]
        avg_temp = sum(temp_vals) / max(1, len(temp_vals)) if temp_vals else 26
        temp_stress_raw = max(0, abs(avg_temp - 26) * 2)

        disease_impact = round(avg_severity * 0.4 + avg_severity * 0.3, 1)
        moisture_stress = round(moisture_deficit * 0.2, 1)
        temp_stress = round(temp_stress_raw * 0.1, 1)

        health_score = max(0, min(100, 100 - (disease_impact + moisture_stress + temp_stress)))
        healthy_cells = [c for c in scanned if c.disease == "Tomato_Healthy"]
        healthy_area_pct = round(100 * len(healthy_cells) / len(scanned), 1)

        return {
            "farm_health_score": round(health_score, 1),
            "grids_scanned": len(scanned), "grids_total": len(cells),
            "infected_grids": len(infected),
            "average_risk": round(avg_severity, 1),
            "average_soil_moisture": round(avg_moisture, 1),
            "breakdown": {
                "disease_impact": disease_impact,
                "moisture_stress": moisture_stress,
                "temp_stress": temp_stress,
                "healthy_area_pct": healthy_area_pct,
            },
        }

    def compute_analytics(self) -> dict:
        cells = self.db.query(models.GridCell).all()
        scanned = [c for c in cells if c.disease != "Unscanned"]
        healthy = [c for c in scanned if c.disease == "Tomato_Healthy"]
        low = [c for c in scanned if c.disease != "Tomato_Healthy" and 0 < c.severity < 40]
        medium = [c for c in scanned if 40 <= c.severity < 70]
        high = [c for c in scanned if 70 <= c.severity < 85]
        critical = [c for c in scanned if c.severity >= 85]

        return {
            "healthy": len(healthy), "low_risk": len(low), "medium_risk": len(medium),
            "high_risk": len(high), "critical": len(critical),
            "unscanned": len(cells) - len(scanned),
        }

    def _favorability_multiplier(self, cell: models.GridCell) -> float:
        humidity = cell.humidity or 50
        moisture = cell.soil_moisture or 40
        temperature = cell.temperature or 26

        mult = 1.0
        if humidity >= 85:
            mult += 0.5
        elif humidity >= 70:
            mult += 0.2
        if moisture >= 60:
            mult += 0.25
        if 20 <= temperature <= 32:
            mult += 0.2
        return mult

    def simulate_future(self, hours: int) -> dict:
        cells = self.db.query(models.GridCell).all()
        projected_grid = {}
        for cell in cells:
            gid = cell.grid_id
            if cell.disease in (None, "Unscanned", "Tomato_Healthy"):
                projected_grid[gid] = {
                    "grid_id": gid, "disease": cell.disease, "severity": cell.severity,
                    "status_color": cell.status_color, "projected_severity": cell.severity,
                    "projected_status_color": cell.status_color,
                }
                continue

            k_base = 0.012
            mult = self._favorability_multiplier(cell)
            k = k_base * mult
            current = cell.severity
            projected = current + (100 - current) * (1 - math.exp(-k * hours))
            projected = round(min(100, projected), 1)
            projected_color = self._status_color(cell.disease, projected)

            projected_grid[gid] = {
                "grid_id": gid, "disease": cell.disease, "severity": current,
                "status_color": cell.status_color, "projected_severity": projected,
                "projected_status_color": projected_color,
            }

        scanned_projected = [c for c in projected_grid.values() if c["disease"] not in (None, "Unscanned")]
        if scanned_projected:
            avg_proj_severity = sum(c["projected_severity"] for c in scanned_projected) / len(scanned_projected)
            current_health = self.compute_health_score()
            delta = (avg_proj_severity - current_health["average_risk"]) * 0.7
            projected_health_score = max(0, min(100, current_health["farm_health_score"] - delta))
        else:
            projected_health_score = self.compute_health_score()["farm_health_score"]

        return {
            "hours_ahead": hours,
            "projected_grid": projected_grid,
            "current_farm_health": self.compute_health_score()["farm_health_score"],
            "projected_farm_health": round(projected_health_score, 1),
        }

    def to_dict(self) -> dict:
        cells = self.db.query(models.GridCell).all()
        grid_dict = {c.grid_id: self._cell_to_dict(c) for c in cells}
        return {
            "rows": self.rows, "cols": self.cols, "grid": grid_dict,
            "health": self.compute_health_score(),
            "analytics": self.compute_analytics(),
            "timeline": self.get_timeline()[:10],
        }

    def get_neighbors(self, grid_id: str) -> list:
        try:
            row_letter, col_num = grid_id[0], int(grid_id[1:])
        except (IndexError, ValueError):
            return []
        row_idx = ord(row_letter) - 65
        neighbors = []
        deltas = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        cells = {c.grid_id: c for c in self.db.query(models.GridCell).all()}
        for dr, dc in deltas:
            nr, nc = row_idx + dr, col_num + dc
            if 0 <= nr < self.rows and 1 <= nc <= self.cols:
                nid = f"{chr(65 + nr)}{nc}"
                if nid in cells:
                    neighbors.append(nid)
        return neighbors

    def get_spread_risk_neighbors(self, grid_id: str) -> dict:
        cells = {c.grid_id: c for c in self.db.query(models.GridCell).all()}
        cell = cells.get(grid_id)
        if not cell or cell.disease in (None, "Unscanned", "Tomato_Healthy"):
            return {"source": grid_id, "is_infected": False, "neighbors": []}

        neighbor_ids = self.get_neighbors(grid_id)
        neighbors_info = []
        for nid in neighbor_ids:
            ncell = cells[nid]
            exposure_risk = round(cell.severity * 0.35, 1) if ncell.disease in (None, "Unscanned", "Tomato_Healthy") else None
            neighbors_info.append({
                "grid_id": nid,
                "current_status": ncell.status_color,
                "current_disease": ncell.disease,
                "exposure_risk_from_source": exposure_risk,
            })
        return {"source": grid_id, "is_infected": True, "source_severity": cell.severity, "neighbors": neighbors_info}

    def reset_twin(self):
        self.db.query(models.GridCell).delete()
        self.db.query(models.CellHistory).delete()
        self.db.query(models.FarmHealthHistory).delete()
        self.db.commit()
        self.__init__(self.db, self.rows, self.cols)
