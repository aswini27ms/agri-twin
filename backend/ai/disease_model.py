import io
import os
import numpy as np
import onnxruntime as ort
import joblib
from PIL import Image

# Setup paths relative to this file's location
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "models")

ONNX_MODEL_PATH = os.path.join(MODEL_DIR, "model_fp32.onnx")
RISK_MODEL_PATH = os.path.join(MODEL_DIR, "risk_model.pkl")
LABEL_ENCODER_PATH = os.path.join(MODEL_DIR, "disease_label_encoder.pkl")

# Initialize models
try:
    session = ort.InferenceSession(ONNX_MODEL_PATH)
    risk_model = joblib.load(RISK_MODEL_PATH)
    disease_le = joblib.load(LABEL_ENCODER_PATH)
except Exception as e:
    print(f"Warning: Could not load models during initialization: {e}")
    session, risk_model, disease_le = None, None, None

CLASSES = ['Rice_Bacterial_Blight', 'Rice_Brown_Spot', 'Rice_Leaf_Smut',
           'Tomato_Early_Blight', 'Tomato_Healthy', 'Tomato_Late_Blight']

def softmax(x):
    e_x = np.exp(x - np.max(x))
    return e_x / e_x.sum()

def predict_disease(image_bytes: bytes):
    if session is None:
        return "Unknown", 0.0
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB").resize((224, 224))
    arr = np.array(img).astype(np.float32) / 255.0
    mean = np.array([0.485, 0.456, 0.406])
    std = np.array([0.229, 0.224, 0.225])
    arr = ((arr - mean) / std).transpose(2, 0, 1)[np.newaxis, :, :, :].astype(np.float32)
    outputs = session.run(None, {"input": arr})
    probs = softmax(outputs[0][0])
    idx = int(np.argmax(probs))
    return CLASSES[idx], float(probs[idx])

def predict_risk(disease, confidence, temperature, humidity, soil_moisture, crop_age_days, previous_severity=0.3):
    if risk_model is None or disease_le is None:
        return 0.0, "Unknown"
    enc = disease_le.transform([disease])[0]
    feats = np.array([[enc, confidence, temperature, humidity, soil_moisture, crop_age_days, previous_severity]])
    risk = float(np.clip(risk_model.predict(feats)[0], 0, 100))
    level = "Low Risk" if risk < 30 else "Medium Risk" if risk < 65 else "High Risk"
    return risk, level

def recommend_action(disease, severity, soil_moisture, temperature, humidity, crop_type, crop_age_days):
    if soil_moisture < 25:
        water_required = "YES"
        deficit = 40 - soil_moisture
        water_amount_l = round(max(1, deficit * 0.15), 1)
    elif soil_moisture < 40:
        water_required = "YES"
        water_amount_l = round((40 - soil_moisture) * 0.1, 1)
    else:
        water_required = "NO"
        water_amount_l = 0

    DISEASE_TREATMENT = {
        "Tomato_Early_Blight":   {"pesticide": "Mancozeb", "fertilizer": "Balanced NPK, avoid excess Nitrogen"},
        "Tomato_Late_Blight":    {"pesticide": "Chlorothalonil / Copper-based fungicide", "fertilizer": "Avoid excess Nitrogen"},
        "Rice_Bacterial_Blight": {"pesticide": "Copper oxychloride / Streptocycline", "fertilizer": "Reduce Nitrogen, apply Potash"},
        "Rice_Brown_Spot":       {"pesticide": "Mancozeb / Propiconazole", "fertilizer": "Apply Potash + correct Nitrogen deficiency"},
        "Rice_Leaf_Smut":        {"pesticide": "Propiconazole", "fertilizer": "Balanced NPK"},
        "Tomato_Healthy":        {"pesticide": "None", "fertilizer": "Maintain regular schedule"},
    }
    treatment = DISEASE_TREATMENT.get(disease, {"pesticide": "Consult local agronomist", "fertilizer": "Standard schedule"})

    priority = "Low" if disease == "Tomato_Healthy" else "High" if severity >= 70 else "Medium" if severity >= 40 else "Low"
    NITROGEN_SENSITIVE = ["Tomato_Early_Blight", "Tomato_Late_Blight", "Rice_Bacterial_Blight"]
    nitrogen_advice = "Withhold - excess Nitrogen worsens this disease" if disease in NITROGEN_SENSITIVE and severity > 50 else "Normal application OK"
    recheck_hours = 24 if priority == "High" else 48 if priority == "Medium" else 96

    return {
        "water_required": water_required, "water_amount_liters": water_amount_l,
        "pesticide": treatment["pesticide"], "fertilizer_guidance": treatment["fertilizer"],
        "nitrogen_advice": nitrogen_advice, "priority": priority, "recheck_in_hours": recheck_hours
    }

def full_digital_twin_pipeline(image_bytes, temperature, humidity, soil_moisture, crop_age_days, previous_severity=0.3):
    disease, confidence = predict_disease(image_bytes)

    if disease == "Tomato_Healthy":
        risk, level = 0, "Healthy - No Risk"
        recommendation = recommend_action(disease, risk, soil_moisture, temperature, humidity, "Tomato", crop_age_days)
    else:
        risk, level = predict_risk(disease, confidence, temperature, humidity, soil_moisture, crop_age_days, previous_severity)
        crop_type = "Tomato" if "Tomato" in disease else "Rice"
        recommendation = recommend_action(disease, risk, soil_moisture, temperature, humidity, crop_type, crop_age_days)

    return {
        "disease": disease, "confidence": round(confidence, 3),
        "spread_risk": round(risk, 1), "risk_level": level,
        "recommendation": recommendation
    }
