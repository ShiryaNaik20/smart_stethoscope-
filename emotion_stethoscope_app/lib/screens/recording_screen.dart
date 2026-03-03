import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class RecordingScreen extends StatefulWidget {
  final String name;
  final String age;
  final String gender;
  final String mode;

  const RecordingScreen({
    Key? key,
    required this.name,
    required this.age,
    required this.gender,
    required this.mode,
  }) : super(key: key);

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool isRecording = false;

  Future<void> saveReport() async {
    await DatabaseHelper.instance.insertReport({
      'patientName': widget.name,
      'patientId': 'PT-${DateTime.now().millisecondsSinceEpoch}',
      'testType': widget.mode,
      'result':
          'Normal | Age: ${widget.age} | Gender: ${widget.gender}',
    });

    // Show success popup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Report Saved Successfully"),
        duration: Duration(seconds: 1),
      ),
    );

    // Wait for snackbar to finish
    await Future.delayed(const Duration(seconds: 1));

    // Go back to Dashboard (HomeScreen)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.mode),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Patient: ${widget.name}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Age: ${widget.age} | Gender: ${widget.gender}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),

            Icon(
              isRecording ? Icons.mic : Icons.mic_none,
              size: 100,
              color: Colors.blue,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                setState(() {
                  isRecording = !isRecording;
                });

                // When stopping recording → save report
                if (!isRecording) {
                  await saveReport();
                }
              },
              child: Text(
                isRecording ? "Stop & Save" : "Start Recording",
              ),
            ),
          ],
        ),
      ),
    );
  }
}