import 'package:tflite_flutter/tflite_flutter.dart';

class ModelService {
  static final ModelService instance = ModelService._init();

  Interpreter? _heartInterpreter;
  Interpreter? _murmurInterpreter;
  Interpreter? _lungInterpreter;

  ModelService._init();

  Future<void> loadModels() async {
    try {
      _heartInterpreter =
          await Interpreter.fromAsset('assets/models/heart_model.tflite');

      _murmurInterpreter =
          await Interpreter.fromAsset(
              'assets/models/heart_murmur_model.tflite');

      _lungInterpreter =
          await Interpreter.fromAsset('assets/models/lung_model.tflite');

      print("✅ All 3 models loaded successfully");
    } catch (e) {
      print("❌ Model loading failed: $e");
    }
  }

  /// 🔥 Simulated AI Prediction
  /// (Safe version – replace with real inference later)
  String predict(String mode) {
    if (mode == "Heart") {
      bool heartAbnormal = false; // simulated result

      if (heartAbnormal) {
        bool murmurDetected = true; // simulated result
        return murmurDetected
            ? "Abnormal Heart Sound (Murmur Detected)"
            : "Abnormal Heart Sound (No Murmur)";
      } else {
        return "Heart Sounds Normal";
      }
    } else if (mode == "Lung") {
      bool lungAbnormal = false; // simulated result

      return lungAbnormal
          ? "Lung Abnormality Detected"
          : "Lungs Clear";
    }

    return "Unknown Result";
  }

  void dispose() {
    _heartInterpreter?.close();
    _murmurInterpreter?.close();
    _lungInterpreter?.close();
  }
}