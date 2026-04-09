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

  // ✅ NEW: Mode selector state ('heart' or 'lung')
  String _selectedMode = 'heart';

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

      // ✅ UPDATED: Pass mode to prediction service
      final result = await _predService.predict(samples, _selectedMode);

      // ✅ SAVE WAV FILE
      final wavPath = await _saveAsWav(samples);

      _wsService.disconnect();

      if (!mounted) return;

      // ✅ NAVIGATE TO RESULT SCREEN WITH MODE
      if (_selectedMode == 'lung') {
        // Lung mode - different result structure
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              patientId: widget.patientId,
              name: widget.name,
              age: widget.age,
              phone: widget.phone,
              prediction: result['lung_prediction'] ?? 'Unknown',
              confidence: (result['confidence'] ?? 0.0).toDouble(),
              murmur: '', // No murmur for lung
              bpm: 0.0, // No BPM for lung
              audioPath: wavPath,
              mode: _selectedMode, // ✅ Pass mode
              lungClass: result['lung_class'] ?? 'Unknown', // ✅ Pass lung class
            ),
          ),
        );
      } else {
        // Heart mode - existing structure
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              patientId: widget.patientId,
              name: widget.name,
              age: widget.age,
              phone: widget.phone,
              prediction: result['heart_prediction'] ?? 'Unknown',
              confidence: (result['heart_score'] ?? 0.0).toDouble(),
              murmur: result['murmur_prediction'] ?? 'Not Checked',
              bpm: (result['bpm'] ?? 0.0).toDouble(),
              audioPath: wavPath,
              mode: _selectedMode, // ✅ Pass mode
              lungClass: '', // ✅ Empty for heart mode
            ),
          ),
        );
      }
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

                  const SizedBox(height: 16),

                  // ✅ NEW: MODE SELECTOR
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMode = 'heart'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedMode == 'heart'
                                    ? Colors.red.shade400
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    color: _selectedMode == 'heart'
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Heart',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedMode == 'heart'
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMode = 'lung'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedMode == 'lung'
                                    ? Colors.blue.shade400
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.air,
                                    color: _selectedMode == 'lung'
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Lung',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedMode == 'lung'
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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