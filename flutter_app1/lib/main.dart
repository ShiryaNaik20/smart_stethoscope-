import 'package:flutter/material.dart';
import 'heart_model1.dart';
import 'waveform_painter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ModelTestScreen(),
    );
  }
}

class ModelTestScreen extends StatefulWidget {
  const ModelTestScreen({super.key});

  @override
  State<ModelTestScreen> createState() => _ModelTestScreenState();
}

class _ModelTestScreenState extends State<ModelTestScreen> {
  final HeartModel model = HeartModel();
  String results = "Press button to test CNN model";

  String? selectedFile;
  List<double> waveformSamples = [];

  final List<String> files = [
    "b0028",
    "b0030",
    "b0141",
    "b0144",
    "b0174",
  ];

  @override
  void initState() {
    super.initState();
    model.loadModel();
  }

  Future<void> testModel() async {
    String outputText = "";

    for (String file in files) {
      var mfcc = await model.loadMFCC(file);
      var prediction = model.predict(mfcc);

      double normalProb = prediction[0];
      double abnormalProb = prediction[1];

      String label;
      double confidence;

      if (normalProb > abnormalProb) {
        label = "Normal";
        confidence = normalProb;
      } else {
        label = "Abnormal";
        confidence = abnormalProb;
      }

      outputText += "File: $file\nResult: $label\nConfidence: ${(confidence*100).toStringAsFixed(2)}%\n\n";
    }

    setState(() {
      results = outputText;
    });
  }

  Future<void> _showWaveform(String fileName) async {
    var mfcc = await model.loadMFCC(fileName);

    // Convert 2D MFCC [216,40] to 1D samples
    waveformSamples = mfcc
        .map((frame) => frame.reduce((a, b) => a + b) / frame.length)
        .toList();

    setState(() {
      selectedFile = fileName;
    });
  }

  @override
  void dispose() {
    model.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Stethoscope CNN Test")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: testModel,
              child: const Text("Run CNN Model Test"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Waveform buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: files.map((file) {
                        return ElevatedButton(
                          onPressed: () => _showWaveform(file),
                          child: Text("Show $file waveform"),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Waveform graph
                    if (selectedFile != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Waveform for $selectedFile",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 250,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CustomPaint(
                              painter: WaveformPainter(waveformSamples),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // Results
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade100,
                      ),
                      child: SelectableText(
                        results,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
