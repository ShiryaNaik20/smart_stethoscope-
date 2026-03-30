import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';

import '../config.dart';
import '../services/websocket_service.dart';
import '../services/prediction_service.dart';
import '../services/database_service.dart';
import '../models/patient_record.dart';
import '../widgets/acubeat_header.dart';
import '../widgets/waveform_painter.dart';
import 'result_screen.dart';

class RecordScreen extends StatefulWidget {
  final String patientId, name, age, phone;

  const RecordScreen({
    super.key,
    required this.patientId,
    required this.name,
    required this.age,
    required this.phone,
  });

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with SingleTickerProviderStateMixin {

  final _wsService   = WebSocketService();
  final _predService = PredictionService(AppConfig.flaskUrl);

  final List<double> _displaySamples =
      List.filled(AppConfig.displayWindow, 0.0, growable: true);

  final List<int> _rawBuffer = [];

  bool _isPredicting  = false;
  bool _connected     = false;
  bool _isConnecting  = true;
  int  _samplesCollected = 0;
  String? _connectionError;

  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker((_) {
      if (mounted) setState(() {});
    });
    _ticker.start();

    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    setState(() {
      _isConnecting = true;
      _connected = false;
      _connectionError = null;
    });

    _wsService.onConnected = () {
      setState(() {
        _connected = true;
        _isConnecting = false;
      });
    };

    _wsService.onWaveformData = (data) {
      _displaySamples.addAll(data);

      if (_displaySamples.length > AppConfig.displayWindow) {
        _displaySamples.removeRange(
          0,
          _displaySamples.length - AppConfig.displayWindow,
        );
      }

      if (!_connected) {
        setState(() {
          _connected = true;
          _isConnecting = false;
        });
      }
    };

    _wsService.onRawSamples = (samples) {
      _rawBuffer.addAll(samples);
      setState(() => _samplesCollected = _rawBuffer.length);
    };

    _wsService.onConnectionError = (err) {
      setState(() {
        _connectionError = err;
        _isConnecting = false;
        _connected = false;
      });
    };

    await _wsService.connect(AppConfig.esp32Ip);
  }

  Future<String> _saveAsWav(List<int> samples) async {
    final dir = await getExternalStorageDirectory();
    final path = '${dir!.path}/${widget.patientId}.wav';
    final file = File(path);

    const sampleRate = 4000;
    final numSamples = samples.length;
    final byteRate = sampleRate * 2;

    final header = BytesBuilder();

    header.add(utf8.encode('RIFF'));
    header.add(_int32(36 + numSamples * 2));
    header.add(utf8.encode('WAVE'));
    header.add(utf8.encode('fmt '));
    header.add(_int32(16));
    header.add(_int16(1));
    header.add(_int16(1));
    header.add(_int32(sampleRate));
    header.add(_int32(byteRate));
    header.add(_int16(2));
    header.add(_int16(16));
    header.add(utf8.encode('data'));
    header.add(_int32(numSamples * 2));

    final audio = BytesBuilder();
    for (var s in samples) {
      audio.add(_int16(s));
    }

    await file.writeAsBytes(header.toBytes() + audio.toBytes());

    return path;
  }

  List<int> _int16(int v) => [v & 0xff, (v >> 8) & 0xff];

  List<int> _int32(int v) => [
        v & 0xff,
        (v >> 8) & 0xff,
        (v >> 16) & 0xff,
        (v >> 24) & 0xff,
      ];

  Future<void> _onPredict() async {
    // ✅ PREVENT DOUBLE EXECUTION
    if (_isPredicting) return;
    
    if (_rawBuffer.length < AppConfig.targetSamples) {
      _showSnack("Not enough samples", isError: true);
      return;
    }

    setState(() => _isPredicting = true);

    try {
      final samples = _rawBuffer.length > AppConfig.targetSamples
          ? _rawBuffer.sublist(
              _rawBuffer.length - AppConfig.targetSamples)
          : List<int>.from(_rawBuffer);

      final result = await _predService.predict(samples);

      // ✅ SAVE WAV FILE (keep this)
      final wavPath = await _saveAsWav(samples);

      // ❌ REMOVED DATABASE SAVE - Will be saved in ResultScreen when user clicks "Save"
      // This was causing duplicate records

      _wsService.disconnect();

      if (!mounted) return;

      // ✅ NAVIGATE TO RESULT SCREEN WITH AUDIO PATH
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            patientId: widget.patientId,
            name: widget.name,
            age: widget.age,
            phone: widget.phone,
            // prediction: result['prediction'] ?? 'Unknown',
            // confidence: (result['confidence'] ?? 0.0).toDouble(),
            prediction: result['heart_prediction'] ?? 'Unknown',
            confidence: (result['heart_score'] ?? 0.0).toDouble(),
            murmur: result['murmur_prediction'] ?? 'Not Checked',
            bpm: (result['bpm'] ?? 0.0).toDouble(),
            audioPath: wavPath, // ✅ PASS THE WAV FILE PATH
          ),
        ),
      );
    } catch (e) {
      setState(() => _isPredicting = false);
      _showSnack("Error: $e", isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _wsService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _samplesCollected >= AppConfig.targetSamples;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const AcuBeatHeader(),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const Text(
                    "Recording...",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: WaveformPainter(_displaySamples),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ BUTTON DISABLED DURING PREDICTION
                  ElevatedButton(
                    onPressed: (ready && !_isPredicting) ? _onPredict : null,
                    child: _isPredicting 
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text("Processing..."),
                            ],
                          )
                        : Text(ready ? "Predict & Save" : "Recording..."),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}