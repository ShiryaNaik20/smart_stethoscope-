import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class HeartModel {
  late Interpreter _interpreter;

  /// Load TFLite Model
  Future<void> loadModel() async {
    _interpreter =
        await Interpreter.fromAsset('assets/models/heart_model1.tflite');

    print("✅ Model Loaded Successfully");
    print("Input Shape: ${_interpreter.getInputTensor(0).shape}");
    print("Output Shape: ${_interpreter.getOutputTensor(0).shape}");
  }

  /// Load MFCC JSON
  Future<List<List<double>>> loadMFCC(String fileName) async {
    String jsonString =
        await rootBundle.loadString('assets/mfcc/$fileName.json');

    List<dynamic> jsonData = jsonDecode(jsonString);

    return jsonData.map<List<double>>((row) {
      return (row as List)
          .map<double>((value) => (value as num).toDouble())
          .toList();
    }).toList();
  }

  /// Run Prediction
  List<double> predict(List<List<double>> mfcc) {
    // Model expects [1, 216, 40, 1]
    var input = [
      mfcc.map((row) => row.map((val) => [val]).toList()).toList()
    ];

    var output = [List.filled(2, 0.0)];
    _interpreter.run(input, output);

    return output[0];
  }

  void close() {
    _interpreter.close();
  }
}
