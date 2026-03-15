from flask import Flask, request, jsonify
import numpy as np
import librosa
import tempfile

app = Flask(__name__)

@app.route('/')
def home():
    return "AI Heart Sound Server Running"

@app.route('/predict', methods=['POST'])
def predict():

    audio = request.files['audio']

    # save temporary file
    temp = tempfile.NamedTemporaryFile(delete=False)
    audio.save(temp.name)

    # load audio
    y, sr = librosa.load(temp.name, sr=16000)

    # simple feature
    energy = np.mean(np.abs(y))

    # simple rule prediction
    if energy > 0.02:
        result = "Abnormal Heartbeat ⚠️"
    else:
        result = "Normal Heartbeat ❤️"

    return jsonify({"prediction": result})


app.run(host="0.0.0.0", port=5000)