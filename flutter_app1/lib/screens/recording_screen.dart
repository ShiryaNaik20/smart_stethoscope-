import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'save_report_screen.dart';

class RecordingScreen extends StatefulWidget {
  final String mode;

  const RecordingScreen({super.key, required this.mode});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool isRecording = false;
  int seconds = 0;
  Timer? timer;

  String? result;

  late RecorderController recorderController;

  @override
  void initState() {
    super.initState();
    recorderController = RecorderController();
  }

  void startRecording() {
    setState(() {
      isRecording = true;
      seconds = 0;
      result = null;
    });

    recorderController.record(); // start waveform animation

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        seconds++;
      });
    });
  }

  void stopRecording() {
    timer?.cancel();
    recorderController.stop(); // stop waveform

    setState(() {
      isRecording = false;
      result = widget.mode == "Heart"
          ? "Heart sound is Normal"
          : "Lung sound is Clear";
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("AI Analysis Result"),
        content: Text(result!),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void saveReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaveReportScreen(
          result: result!,
          mode: widget.mode,
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recording - ${widget.mode}"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic,
              size: 100,
              color: isRecording ? Colors.red : Colors.grey,
            ),

            const SizedBox(height: 20),

            Text(
              "$seconds sec",
              style: const TextStyle(fontSize: 28),
            ),

            const SizedBox(height: 20),

            // 🔥 WAVEFORM
            if (isRecording)
  Container(
    height: 100,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: AudioWaveforms(
      enableGesture: false,
      size: const Size(double.infinity, 100),
      recorderController: recorderController,
      waveStyle: const WaveStyle(
        waveColor: Colors.red,
        extendWaveform: true,
        showMiddleLine: false,
      ),
    ),
  )
else
  const SizedBox(height: 100),


            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: isRecording ? stopRecording : startRecording,
              child: Text(isRecording ? "Stop Recording" : "Start Recording"),
            ),

            const SizedBox(height: 30),

            if (result != null) ...[
              Text(
                "Result: $result",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: saveReport,
                child: const Text("Save Report"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}