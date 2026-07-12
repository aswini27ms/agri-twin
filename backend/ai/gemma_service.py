import json
import re
from typing import Optional
import requests

OLLAMA_URL = "http://localhost:11434/api/chat"
GEMMA_MODEL = "gemma2:9b"
GEMMA_TIMEOUT_SECONDS = 180
GEMMA_CONNECT_TIMEOUT_SECONDS = 10

LANGUAGE_RANGES = {
    "Tamil": (0x0B80, 0x0BFF),
    "Telugu": (0x0C00, 0x0C7F),
    "Hindi": (0x0900, 0x097F),
}

CROP_TERM_LOCKS = {
    "Tamil": {
        "plant": "செடி",
        "tree": "மரம்",
        "fertilizer": "உரம்",
        "pesticide": "பூச்சிக்கொல்லி",
        "fungicide": "பூஞ்சைக்கொல்லி",
        "irrigation": "நீர்ப்பாசனம்",
        "soil": "மண்",
    },
    "Telugu": {
        "plant": "మొక్క",
        "tree": "చెట్టు",
        "fertilizer": "ఎరువు",
        "pesticide": "పురుగుమందు",
        "fungicide": "శిలీంధ్రనాశకం",
        "irrigation": "నీటిపారుదల",
        "soil": "నేల",
    },
    "Hindi": {
        "plant": "पौधा",
        "tree": "पेड़",
        "fertilizer": "उर्वरक",
        "pesticide": "कीटनाशक",
        "fungicide": "फफूंदनाशक",
        "irrigation": "सिंचाई",
        "soil": "मिट्टी",
    },
}


def detect_language(text: str) -> str:
    for lang, (lo, hi) in LANGUAGE_RANGES.items():
        if any(lo <= ord(ch) <= hi for ch in text):
            return lang
    return "English"


GEMMA_SYSTEM_PROMPT = """You are AgriTwin AI, an experienced agricultural extension officer.

Rules you always follow:
- Explain AI predictions in simple, practical language a farmer can act on.
- Never invent diseases, sensor values, or facts not given to you.
- Only answer using the information provided in the Digital Twin state below.
- If information is missing, clearly say so instead of guessing.
- Always explain WHY a recommendation is given.
- Recommend practical, specific actions.
- Always respond in the same language the farmer writes in (Tamil, Hindi, Telugu, or English). Match their language exactly.
- Keep responses concise - 2-4 sentences unless asked for more detail."""

GEMMA_CHAT_SYSTEM_PROMPT = """You are AgriTwin AI, an experienced agricultural extension officer helping a farmer.

Rules you always follow:
- Answer the farmer's question directly and practically, using your general agricultural knowledge.
- If a Digital Twin state for their field is provided below, use it to tailor your answer.
- Do NOT invent specific sensor readings, diagnoses, or confidence values.
- Do NOT introduce a different crop category than the one given.
- Give a specific, actionable answer rather than a vague non-answer.
- Always respond in ENGLISH regardless of what language the farmer wrote in.
- Keep responses concise - 2-4 sentences unless asked for more detail."""


class GemmaUnavailableError(Exception):
    pass


def build_gemma_context(cell: dict, farm_health: float) -> dict:
    rec = cell.get("recommendation") or {}
    return {
        "farm_health": farm_health,
        "grid": cell.get("grid_id"),
        "crop": cell.get("crop"),
        "disease": str(cell.get("disease", "")).replace("_", " "),
        "confidence": round((cell.get("confidence") or 0) * 100, 1),
        "severity": cell.get("severity"),
        "temperature": cell.get("temperature"),
        "humidity": cell.get("humidity"),
        "soil_moisture": cell.get("soil_moisture"),
        "recommendation": {
            "water": rec.get("water_required"),
            "pesticide": rec.get("pesticide"),
            "priority": rec.get("priority"),
        },
    }


def call_gemma(
    user_prompt: str,
    extra_system: str = "",
    temperature: float = 0.3,
    timeout: Optional[float] = None,
    system_prompt: Optional[str] = None,
) -> str:
    request_timeout = timeout if timeout is not None else GEMMA_TIMEOUT_SECONDS
    base_system = system_prompt if system_prompt is not None else GEMMA_SYSTEM_PROMPT
    try:
        resp = requests.post(
            OLLAMA_URL,
            json={
                "model": GEMMA_MODEL,
                "messages": [
                    {"role": "system", "content": base_system + ("\n\n" + extra_system if extra_system else "")},
                    {"role": "user", "content": user_prompt},
                ],
                "stream": False,
                "options": {"temperature": temperature},
            },
            timeout=(GEMMA_CONNECT_TIMEOUT_SECONDS, request_timeout),
        )
        resp.raise_for_status()
        return resp.json()["message"]["content"].strip()
    except requests.exceptions.ConnectionError:
        raise GemmaUnavailableError("Cannot reach Gemma (Ollama). Start it with: ollama serve")
    except requests.exceptions.ReadTimeout:
        raise GemmaUnavailableError(f"Gemma took longer than {request_timeout}s to respond.")
    except Exception as e:
        raise GemmaUnavailableError(f"Gemma call failed: {e}")


def warmup_gemma() -> bool:
    try:
        call_gemma("hi", extra_system="Reply with just: ok", temperature=0.0, timeout=GEMMA_TIMEOUT_SECONDS)
        return True
    except GemmaUnavailableError:
        return False


def extract_json(text: str) -> dict:
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if not match:
        return {"summary": text.strip(), "reason": None, "action": None, "warning": None, "next_scan": None}
    try:
        return json.loads(match.group(0))
    except json.JSONDecodeError:
        return {"summary": text.strip(), "reason": None, "action": None, "warning": None, "next_scan": None}


def explain_context(context: dict) -> dict:
    prompt = (
        "Here is the current Digital Twin state for one farm grid:\n\n"
        + json.dumps(context, indent=2)
        + "\n\nRespond ONLY with a JSON object with exactly these keys: "
        '"summary" (one sentence on what was detected), '
        '"reason" (why the risk/severity is what it is, referencing the actual temperature/humidity/moisture values above), '
        '"action" (the specific practical action to take right now), '
        '"warning" (what to watch for or check next), '
        '"next_scan" (when to re-check this grid). '
        "No extra text outside the JSON."
    )
    raw = call_gemma(prompt)
    return extract_json(raw)


TRANSLATE_SYSTEM_PROMPT = """You are a professional agricultural translator. Translate the given English \
farm advice into natural, simple, fluent {language} that a farmer would easily understand.

Strict rules:
- Translate ONLY what is written. Do not add, remove, guess, or change any facts, numbers, crop names, product names, or recommendations.
- Preserve the exact meaning of key terms. Use these fixed translations wherever the term appears:
{term_lock_block}
- Do not include any English text, romanized text, or the original text in your reply.
- Reply with the translation only, nothing else."""


def _build_term_lock_block(language: str) -> str:
    terms = CROP_TERM_LOCKS.get(language, {})
    if not terms:
        return "(no fixed terms for this language - translate naturally)"
    return "\n".join(f'  - "{en}" -> "{local}"' for en, local in terms.items())


def translate_to_language(english_text: str, language: str) -> str:
    term_lock_block = _build_term_lock_block(language)
    prompt = f"English text to translate:\n\n{english_text}"
    return call_gemma(
        prompt,
        system_prompt=TRANSLATE_SYSTEM_PROMPT.format(language=language, term_lock_block=term_lock_block),
        temperature=0.1,
    )


def chat_reply(message: str, context: Optional[dict] = None, debug: bool = False):
    detected = detect_language(message)

    extra_system = "Respond in English, in 1-3 short, simple, practical sentences."
    if context:
        extra_system += (
            "\n\nDigital Twin state for the grid the farmer is asking about:\n" + json.dumps(context, indent=2)
        )
    else:
        extra_system += "\n\nNo Digital Twin state was provided for this question."

    english_answer = call_gemma(
        message,
        extra_system=extra_system,
        temperature=0.3,
        system_prompt=GEMMA_CHAT_SYSTEM_PROMPT,
    )

    if detected == "English":
        final_reply = english_answer
    else:
        final_reply = translate_to_language(english_answer, detected)

    if debug:
        return {
            "reply": final_reply,
            "detected_language": detected,
            "english_answer": english_answer,
        }
    return final_reply
