import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  IOWebSocketChannel? channel;

  bool connected = false;

  List<double> samples = [];
  List<double> recordedSamples = [];

  bool recording = false;

  String result = "No Prediction";

  // CONNECT TO ESP32
  void connectESP() {

    channel = IOWebSocketChannel.connect(
        "ws://192.168.0.105:81"   // CHANGE TO ESP32 IP
    );

    channel!.stream.listen((message) {

      Uint8List bytes = message;

      final int16List = Int16List.view(bytes.buffer);

      final newSamples =
      int16List.map((e) => e / 32768.0).toList();

      setState(() {

        samples.addAll(newSamples);

        if (samples.length > 1024) {
          samples = samples.sublist(samples.length - 1024);
        }

        if (recording) {
          recordedSamples.addAll(newSamples);
        }

      });

    });

    setState(() {
      connected = true;
    });
  }

  // RECORD 5 SECONDS
  Future record5Seconds() async {

    recordedSamples.clear();

    recording = true;

    await Future.delayed(Duration(seconds: 5));

    recording = false;

    sendToModel();
  }

  // CONVERT AUDIO BYTES
  Uint8List convertBytes() {

    final intSamples =
    recordedSamples.map((e) => (e * 32767).toInt()).toList();

    final buffer = Int16List.fromList(intSamples);

    return buffer.buffer.asUint8List();
  }

  // SEND TO AI SERVER
  Future sendToModel() async {

    var audio = convertBytes();

    var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://10.209.26.118:5000/predict")   // YOUR PYTHON SERVER
    );

    request.files.add(
      http.MultipartFile.fromBytes(
          "audio",
          audio,
          filename: "heart.wav"
      ),
    );

    var response = await request.send();

    var body = await response.stream.bytesToString();

    var data = jsonDecode(body);

    setState(() {
      result = data["prediction"];
    });
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      home: Scaffold(

        appBar: AppBar(
          title: Text("AI Heart Detector"),
        ),

        body: Column(

          children: [

            SizedBox(height: 20),

            Text(
              connected ? "Connected ✅" : "Disconnected ❌",
              style: TextStyle(fontSize: 20),
            ),

            ElevatedButton(
              onPressed: connectESP,
              child: Text("Connect ESP32"),
            ),

            ElevatedButton(
              onPressed: record5Seconds,
              child: Text("Record Heart Sound"),
            ),

            SizedBox(height: 20),

            Text(
              "Prediction:",
              style: TextStyle(fontSize: 18),
            ),

            Text(
              result,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold
              ),
            ),

            SizedBox(height: 20),

            Expanded(
              child: CustomPaint(
                painter: WavePainter(samples),
                size: Size(double.infinity, 200),
              ),
            )

          ],

        ),

      ),

    );
  }
}

// WAVEFORM PAINTER
class WavePainter extends CustomPainter {

  final List<double> samples;

  WavePainter(this.samples);

  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;

    final middle = size.height / 2;

    final scaleX =
        size.width / (samples.isEmpty ? 1 : samples.length);

    for (int i = 0; i < samples.length - 1; i++) {

      final x1 = i * scaleX;
      final y1 = middle - samples[i] * middle;

      final x2 = (i + 1) * scaleX;
      final y2 = middle - samples[i + 1] * middle;

      canvas.drawLine(
          Offset(x1, y1),
          Offset(x2, y2),
          paint
      );
    }
  }

  @override
  bool shouldRepaint(oldDelegate) => true;
}