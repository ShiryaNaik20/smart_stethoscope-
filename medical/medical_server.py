!pip install flask librosa numpy pyngrok tensorflow opencv-python flask-cors

from google.colab import files
files.upload()

# ================================================================
# MEDICAL SERVER — runs on ngrok
# ================================================================
from flask import Flask, request, jsonify
import numpy as np
import librosa
import tensorflow as tf
from scipy import signal
import cv2
import threading
from pyngrok import ngrok

app = Flask(__name__)

# ── Load models ──────────────────────────────────────────────────
heart_interpreter = tf.lite.Interpreter(model_path="heart_model.tflite")
heart_interpreter.allocate_tensors()
heart_input  = heart_interpreter.get_input_details()
heart_output = heart_interpreter.get_output_details()

murmur_interpreter = tf.lite.Interpreter(model_path="heart_murmur_model.tflite")
murmur_interpreter.allocate_tensors()
murmur_input  = murmur_interpreter.get_input_details()
murmur_output = murmur_interpreter.get_output_details()

lung_interpreter = tf.lite.Interpreter(model_path="lung_model.tflite")
lung_interpreter.allocate_tensors()
lung_input  = lung_interpreter.get_input_details()
lung_output = lung_interpreter.get_output_details()

with open("threshold.txt") as f:
    HEART_THRESHOLD = float(f.read().strip())

SR = 4000
print("✅ Medical models loaded")

# ── Feature extraction ────────────────────────────────────────────
def extract_heart_mel(audio):
    mel    = librosa.feature.melspectrogram(y=audio, sr=SR, n_mels=128, n_fft=1024, hop_length=256, fmax=2000)
    mel_db = librosa.power_to_db(mel).T
    mel_db = (mel_db - mel_db.mean()) / (mel_db.std() + 1e-6)
    if mel_db.shape[0] < 216:
        mel_db = np.pad(mel_db, ((0, 216 - mel_db.shape[0]), (0, 0)))
    else:
        mel_db = mel_db[:216]
    return mel_db[..., np.newaxis]

def extract_murmur_mel(audio):
    mel    = librosa.feature.melspectrogram(y=audio, sr=SR, n_mels=64, fmin=20, fmax=600)
    mel_db = librosa.power_to_db(mel)
    if mel_db.shape[1] < 430:
        mel_db = np.pad(mel_db, ((0, 0), (0, 430 - mel_db.shape[1])))
    else:
        mel_db = mel_db[:, :430]
    mel_db = (mel_db - np.mean(mel_db)) / (np.std(mel_db) + 1e-6)
    return mel_db[..., np.newaxis]

def extract_lung_mel(audio):
    mel        = librosa.feature.melspectrogram(y=audio, sr=SR, n_mels=128)
    mel_db     = librosa.power_to_db(mel, ref=np.max)
    mel_resized = cv2.resize(mel_db, (128, 128))
    mel_resized = (mel_resized - np.mean(mel_resized)) / (np.std(mel_resized) + 1e-6)
    return mel_resized[..., np.newaxis]

def calculate_bpm(audio, sr):
    try:
        audio  = audio - np.mean(audio)
        env    = np.abs(audio)
        b, a   = signal.butter(4, 5.0 / (sr / 2), btype='low')
        smooth = signal.filtfilt(b, a, env)
        fft_vals = np.abs(np.fft.rfft(smooth))
        freqs    = np.fft.rfftfreq(len(smooth), d=1.0 / sr)
        mask     = (freqs >= 0.75) & (freqs <= 2.5)
        if not np.any(mask):
            return 0.0
        f   = freqs[mask][np.argmax(fft_vals[mask])]
        bpm = f * 60.0
        if bpm > 108:
            bpm /= 2
        return round(bpm, 1)
    except:
        return 0.0

# ── Routes ────────────────────────────────────────────────────────
def predict_heart():
    raw   = request.data
    audio = np.frombuffer(raw, dtype=np.int16).astype(np.float32)
    if len(audio) < 100:
        return jsonify({"error": "Too few samples"}), 400
    max_abs = np.max(np.abs(audio))
    if max_abs == 0:
        return jsonify({"heart_prediction": "No Signal", "bpm": 0})
    audio = audio / (max_abs + 1e-6)

    heart_mel = np.expand_dims(extract_heart_mel(audio), axis=0).astype(np.float32)
    heart_interpreter.set_tensor(heart_input[0]['index'], heart_mel)
    heart_interpreter.invoke()
    heart_score  = float(heart_interpreter.get_tensor(heart_output[0]['index'])[0][0])
    heart_result = "Abnormal" if heart_score > HEART_THRESHOLD else "Normal"

    murmur_result, murmur_conf = "Not Checked", 0.0
    if heart_result == "Abnormal":
        murmur_mel = np.expand_dims(extract_murmur_mel(audio), axis=0).astype(np.float32)
        murmur_interpreter.set_tensor(murmur_input[0]['index'], murmur_mel)
        murmur_interpreter.invoke()
        score         = float(murmur_interpreter.get_tensor(murmur_output[0]['index'])[0][0])
        murmur_result = "Murmur Present" if score > 0.25 else "No Murmur"
        murmur_conf   = round(score * 100, 2)

    return jsonify({
        "heart_prediction":  heart_result,
        "heart_score":       round(heart_score, 4),
        "murmur_prediction": murmur_result,
        "murmur_confidence": murmur_conf,
        "bpm":               calculate_bpm(audio, SR)
    })

def predict_lung():
    raw   = request.data
    audio = np.frombuffer(raw, dtype=np.int16).astype(np.float32)
    if len(audio) < 100:
        return jsonify({"error": "Too few samples"}), 400
    audio    = audio / (np.max(np.abs(audio)) + 1e-6)
    lung_mel = np.expand_dims(extract_lung_mel(audio), axis=0).astype(np.float32)
    lung_interpreter.set_tensor(lung_input[0]['index'], lung_mel)
    lung_interpreter.invoke()
    probs   = lung_interpreter.get_tensor(lung_output[0]['index'])[0]
    idx     = np.argmax(probs)
    classes = ["Normal", "Crackle", "Wheeze", "Both"]
    return jsonify({
        "lung_prediction": "Normal" if idx == 0 else "Abnormal",
        "lung_class":      classes[idx],
        "confidence":      round(float(probs[idx]) * 100, 2)
    })

@app.route('/predict_all', methods=['POST'])
def predict_all():
    mode = request.args.get('mode', 'heart')
    return predict_lung() if mode == 'lung' else predict_heart()

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "OK", "server": "medical"})

# ── Start ngrok + Flask ───────────────────────────────────────────
ngrok.kill()
ngrok.set_auth_token("")  # ← your token

tunnel = ngrok.connect(5000)
print("🏥 Medical URL:", tunnel.public_url)

threading.Thread(
    target=lambda: app.run(host="0.0.0.0", port=5000),
    daemon=True
).start()