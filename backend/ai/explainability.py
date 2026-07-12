from backend.ai.gemma_service import build_gemma_context, explain_context, GemmaUnavailableError

def get_reason_trace(cell: dict) -> dict:
    rec = cell.get("recommendation") or {}
    return {
        "grid_id": cell.get("grid_id"),
        "crop": cell.get("crop"),
        "disease": str(cell.get("disease", "")).replace("_", " "),
        "confidence_pct": round((cell.get("confidence") or 0) * 100, 1),
        "spread_risk_pct": cell.get("severity", 0),
        "risk_level": cell.get("risk_level", "Unknown"),
        "sensor_inputs": {
            "temperature": cell.get("temperature"),
            "humidity": cell.get("humidity"),
            "soil_moisture": cell.get("soil_moisture"),
            "crop_age_days": cell.get("crop_age_days"),
        },
        "recommendation": {
            "water_required": rec.get("water_required"),
            "water_amount_liters": rec.get("water_amount_liters"),
            "pesticide": rec.get("pesticide"),
            "fertilizer_guidance": rec.get("fertilizer_guidance"),
            "nitrogen_advice": rec.get("nitrogen_advice"),
            "priority": rec.get("priority"),
            "recheck_in_hours": rec.get("recheck_in_hours"),
        },
    }

def _fallback_explanation(context: dict) -> dict:
    disease = context["disease"]
    severity = context["severity"]
    rec = context["recommendation"]

    if disease == "Tomato Healthy":
        return {
            "summary": f"Grid {context['grid']} is healthy, no disease detected.",
            "reason": "Sensor readings and crop appearance are within normal ranges.",
            "action": "No action needed - continue regular monitoring.",
            "warning": "Recheck periodically in case conditions change.",
            "next_scan": "Within the next few days.",
            "source": "fallback",
        }

    risk_word = "high" if severity >= 70 else "medium" if severity >= 40 else "low"
    return {
        "summary": f"{disease} detected in grid {context['grid']} with {context['confidence']}% confidence.",
        "reason": (
            f"Current conditions (temperature {context['temperature']}C, humidity {context['humidity']}%, "
            f"soil moisture {context['soil_moisture']}%) are contributing to a spread risk of {severity}%, "
            f"classified as {risk_word} risk."
        ),
        "action": (
            f"Apply {rec['pesticide']}. "
            + ("Irrigation is not needed right now." if rec["water"] == "NO" else "Irrigation is recommended.")
        ),
        "warning": "Inspect neighboring grids for early signs of the same disease within 24-48 hours.",
        "next_scan": (
            "Recheck this grid in "
            + ("24 hours" if rec["priority"] == "High" else "48 hours" if rec["priority"] == "Medium" else "3-4 days")
            + "."
        ),
        "source": "fallback",
    }

def get_full_explanation(cell: dict, farm_health: float, timeout_ok: bool = True) -> dict:
    reason_trace = get_reason_trace(cell)
    context = build_gemma_context(cell, farm_health)

    if not timeout_ok:
        return {
            "machine_recommendation": reason_trace,
            "farmer_explanation": _fallback_explanation(context),
        }

    try:
        explanation = explain_context(context)
        explanation["source"] = "gemma"
    except GemmaUnavailableError:
        explanation = _fallback_explanation(context)

    return {
        "machine_recommendation": reason_trace,
        "farmer_explanation": explanation,
    }
