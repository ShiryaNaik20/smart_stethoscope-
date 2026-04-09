import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/emotion_service.dart';
import 'dart:io';
import 'dart:async';

class EmotionRecordScreen extends StatefulWidget {
  final String patientId;
  final String name;
  final String age;
  final String phone;

  const EmotionRecordScreen({
    Key? key,
    required this.patientId,
    required this.name,
    required this.age,
    required this.phone,
  }) : super(key: key);

  @override
  _EmotionRecordScreenState createState() => _EmotionRecordScreenState();
}

class _EmotionRecordScreenState extends State<EmotionRecordScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  final EmotionService _emotionService = EmotionService();

  bool _isRecording = false;
  bool _isProcessing = false;
  String? _recordingPath;
  String _detectedEmotion = '';
  double _confidence = 0.0;
  Map<String, double> _allEmotions = {};
  int _recordingSeconds = 0;

  // Animated text cycling
  final List<String> _recordingMessages = [
    '🎙️ Listening to your voice...',
    '💬 Speak clearly into the mic',
    '🧠 Capturing tone & emotion',
    '😊 Express yourself naturally',
    '⏱️ Stay within 10 seconds',
  ];
  int _messageIndex = 0;
  Timer? _messageTimer;

  // Pulse animation for mic button
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkPermissions();

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission required')),
      );
    }
  }

  void _startMessageCycling() {
    _messageTimer = Timer.periodic(Duration(milliseconds: 1800), (_) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _recordingMessages.length;
        });
      }
    });
  }

  void _stopMessageCycling() {
    _messageTimer?.cancel();
    _messageTimer = null;
    _messageIndex = 0;
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final Directory appDirectory = await getApplicationDocumentsDirectory();
        final String filePath =
            '${appDirectory.path}/emotion_${widget.patientId}_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 22050,
            numChannels: 1,
          ),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordingPath = filePath;
          _detectedEmotion = '';
          _recordingSeconds = 0;
        });

        _pulseController.repeat(reverse: true);
        _startMessageCycling();
        _startTimer();
      }
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  void _startTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingSeconds++;
        });
        if (_recordingSeconds < 10) {
          _startTimer();
        } else {
          _stopRecording();
        }
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stop();
      _pulseController.stop();
      _pulseController.reset();
      _stopMessageCycling();

      setState(() {
        _isRecording = false;
      });

      if (_recordingPath != null) {
        File audioFile = File(_recordingPath!);
        if (await audioFile.exists()) {
          int fileSize = await audioFile.length();
          print('Audio file: $fileSize bytes');
          _analyzeEmotion();
        } else {
          throw Exception('Audio file not found');
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _analyzeEmotion() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      print('Analyzing: $_recordingPath');
      final result = await _emotionService.predictEmotion(_recordingPath!);

      setState(() {
        _detectedEmotion = result['emotion'];
        _confidence = result['confidence'];
        _allEmotions = Map<String, double>.from(
          result['all_probabilities'].map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          ),
        );
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), duration: Duration(seconds: 5)),
      );
    }
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Colors.amber;
      case 'sad':
        return Colors.blue;
      case 'angry':
        return Colors.red;
      case 'fearful':
        return Colors.purple;
      case 'disgust':
        return Colors.green;
      case 'surprised':
        return Colors.orange;
      case 'calm':
        return Colors.teal;
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_very_dissatisfied;
      case 'angry':
        return Icons.sentiment_dissatisfied;
      case 'fearful':
        return Icons.warning_amber;
      case 'disgust':
        return Icons.sick;
      case 'surprised':
        return Icons.sentiment_satisfied;
      case 'calm':
        return Icons.self_improvement;
      case 'neutral':
        return Icons.sentiment_neutral;
      default:
        return Icons.emoji_emotions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'ID: ${widget.patientId}',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      SizedBox(height: 20),

                      Text(
                        'Emotion Detection',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade400,
                        ),
                      ),

                      SizedBox(height: 40),

                      // Mic button with pulse animation
                      ScaleTransition(
                        scale: _isRecording ? _pulseAnimation : AlwaysStoppedAnimation(1.0),
                        child: GestureDetector(
                          onTap: _isRecording ? _stopRecording : _startRecording,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isRecording
                                    ? [Colors.red, Colors.red.shade700]
                                    : [
                                        Colors.orange.shade400,
                                        Colors.yellow.shade300,
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRecording
                                          ? Colors.red
                                          : Colors.orange)
                                      .withOpacity(0.4),
                                  blurRadius: 35,
                                  offset: Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              size: 90,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 28),

                      // ── Recording State Text ──
                      if (_isRecording) ...[
                        // Progress bar
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _recordingSeconds / 10,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.red.shade400,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 14),

                        // Timer
                        Text(
                          '${_recordingSeconds}s / 10s',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade400,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Animated cycling hint text
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 500),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: Container(
                            key: ValueKey(_messageIndex),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.orange.shade200,
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              _recordingMessages[_messageIndex],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Tap to Record (max 10s)',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],

                      SizedBox(height: 50),

                      // ── Results ──
                      if (_isProcessing)
                        Column(
                          children: [
                            CircularProgressIndicator(
                              color: Colors.orange.shade400,
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Analyzing emotion...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                      else if (_detectedEmotion.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: _getEmotionColor(
                              _detectedEmotion,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getEmotionColor(_detectedEmotion),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _getEmotionIcon(_detectedEmotion),
                                size: 100,
                                color: _getEmotionColor(_detectedEmotion),
                              ),
                              SizedBox(height: 20),
                              Text(
                                _detectedEmotion.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: _getEmotionColor(_detectedEmotion),
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              SizedBox(height: 30),
                              Divider(thickness: 2),
                              SizedBox(height: 20),

                              Text(
                                'All Detected Emotions',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 20),

                              ..._allEmotions.entries.map((entry) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getEmotionIcon(entry.key),
                                        color: _getEmotionColor(entry.key),
                                        size: 30,
                                      ),
                                      SizedBox(width: 15),
                                      Expanded(
                                        child: Text(
                                          entry.key.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getEmotionColor(
                                            entry.key,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${(entry.value * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: _getEmotionColor(entry.key),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }
}