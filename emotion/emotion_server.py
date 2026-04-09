!pip install flask flask-cors pyngrok librosa tensorflow

from google.colab import files
files.upload()

# ================================================================
# EMOTION SERVER — runs on Cloudflare Tunnel (no account needed)
# ================================================================
from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import librosa
import tensorflow as tf
import pickle
import io
import threading
import subprocess
import time
import re

app = Flask(__name__)
CORS(app)

# ── Load models ──────────────────────────────────────────────────
interpreter = tf.lite.Interpreter(model_path="emotion_model.tflite")
interpreter.allocate_tensors()
input_details  = interpreter.get_input_details()
output_details = interpreter.get_output_details()

with open("scaler.pkl", "rb") as f:
    scaler = pickle.load(f)
with open("label_encoder.pkl", "rb") as f:
    le = pickle.load(f)

print("✅ Emotion model loaded")

# ── Feature extraction ────────────────────────────────────────────
def extract_features(audio_data, sample_rate):
    if sample_rate != 22050:
        audio_data  = librosa.resample(audio_data, orig_sr=sample_rate, target_sr=22050)
        sample_rate = 22050
    mfcc   = np.mean(librosa.feature.mfcc(y=audio_data, sr=sample_rate, n_mfcc=60).T, axis=0)
    zcr    = np.mean(librosa.feature.zero_crossing_rate(audio_data).T, axis=0)
    energy = np.mean(librosa.feature.rms(y=audio_data).T, axis=0)
    return np.hstack([mfcc, zcr, energy])

# ── Routes ────────────────────────────────────────────────────────
@app.route("/")
def home():
    return "🎭 Emotion Server Running"

@app.route("/health")
def health():
    return jsonify({"status": "healthy", "server": "emotion", "emotions": le.classes_.tolist()})

@app.route("/predict_emotion", methods=["POST"])
def predict():
    try:
        if "audio" not in request.files:
            return jsonify({"error": "No audio file"}), 400
        audio_bytes    = request.files["audio"].read()
        audio_data, sr = librosa.load(io.BytesIO(audio_bytes), duration=4, offset=0.5, sr=None)
        features       = extract_features(audio_data, sr)
        scaled         = scaler.transform(features.reshape(1, -1))
        input_data     = np.expand_dims(scaled, axis=2).astype(np.float32)
        interpreter.set_tensor(input_details[0]["index"], input_data)
        interpreter.invoke()
        prediction = interpreter.get_tensor(output_details[0]["index"])
        idx        = np.argmax(prediction[0])
        confidence = float(np.max(prediction[0]))
        emotion    = le.inverse_transform([idx])[0]
        return jsonify({
            "emotion":           emotion,
            "confidence":        confidence,
            "all_probabilities": dict(zip(le.classes_.tolist(), prediction[0].tolist()))
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ── Start Flask in background ─────────────────────────────────────
threading.Thread(
    target=lambda: app.run(host="0.0.0.0", port=5001),
    daemon=True
).start()

time.sleep(2)
print("✅ Flask running on port 5001")

# ── Install + start Cloudflare tunnel (no login needed) ───────────
subprocess.run(
    ["wget", "-q", "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64",
     "-O", "/usr/local/bin/cloudflared"],
    check=True
)
subprocess.run(["chmod", "+x", "/usr/local/bin/cloudflared"], check=True)
print("✅ cloudflared installed")

# Start tunnel and capture URL from logs
cf_proc = subprocess.Popen(
    ["cloudflared", "tunnel", "--url", "http://localhost:5001"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True
)

print("⏳ Waiting for Cloudflare URL...")
cf_url = None
for line in cf_proc.stdout:
    print(line, end="")  # show all logs
    match = re.search(r'https://[a-z0-9\-]+\.trycloudflare\.com', line)
    if match:
        cf_url = match.group(0)
        break

print("\n" + "="*50)
print("🌩️  Emotion URL:", cf_url)
print("="*50)