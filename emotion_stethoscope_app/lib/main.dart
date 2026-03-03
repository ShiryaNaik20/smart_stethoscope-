import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  IOWebSocketChannel? channel;
  bool isConnected = false;

  List<double> samples = [];

  void connectToESP32() {
    try {
      channel = IOWebSocketChannel.connect(
        'ws://192.168.1.100:81', // 🔴 CHANGE THIS TO YOUR ESP32 IP
      );

      channel!.stream.listen(
        (message) {
          Uint8List bytes = message;

          final int16List = Int16List.view(bytes.buffer);

          final newSamples =
              int16List.map((e) => e / 32768.0).toList();

          setState(() {
            samples.addAll(newSamples);

            if (samples.length > 1024) {
              samples =
                  samples.sublist(samples.length - 1024);
            }
          });
        },
        onDone: () {
          setState(() {
            isConnected = false;
          });
        },
        onError: (error) {
          setState(() {
            isConnected = false;
          });
        },
      );

      setState(() {
        isConnected = true;
      });
    } catch (e) {
      print("Connection Error: $e");
    }
  }

  void disconnect() {
    channel?.sink.close(status.goingAway);
    setState(() {
      isConnected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("ESP32 Heart Monitor")),
        body: Column(
          children: [
            SizedBox(height: 20),

            Text(
              isConnected ? "Connected ✅" : "Disconnected ❌",
              style: TextStyle(
                fontSize: 18,
                color:
                    isConnected ? Colors.green : Colors.red,
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed:
                  isConnected ? disconnect : connectToESP32,
              child: Text(
                  isConnected ? "Disconnect" : "Connect"),
            ),

            SizedBox(height: 20),

            Expanded(
              child: CustomPaint(
                painter: WaveformPainter(samples),
                size: Size(double.infinity, 200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> samples;

  WaveformPainter(this.samples);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;

    final middleY = size.height / 2;
    final scaleX = size.width /
        (samples.isEmpty ? 1 : samples.length);

    for (int i = 0; i < samples.length - 1; i++) {
      final x1 = i * scaleX;
      final y1 = middleY - samples[i] * middleY;

      final x2 = (i + 1) * scaleX;
      final y2 =
          middleY - samples[i + 1] * middleY;

      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant WaveformPainter oldDelegate) =>
      true;
}