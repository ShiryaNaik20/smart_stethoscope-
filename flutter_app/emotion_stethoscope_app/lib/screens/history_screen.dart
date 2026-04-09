import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import '../models/patient_record.dart';
import '../services/database_service.dart';
import '../widgets/acubeat_header.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<PatientRecord> _records = [];
  bool _loading = true;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingIndex;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _load();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
        if (state == PlayerState.completed) {
          _playingIndex = null;
          _isPlaying = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final records = await DatabaseService.getAllRecords();
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _delete(int id) async {
    // Stop audio if playing the deleted record
    if (_playingIndex != null && _records[_playingIndex!].id == id) {
      await _audioPlayer.stop();
      setState(() {
        _playingIndex = null;
        _isPlaying = false;
      });
    }
    
    await DatabaseService.deleteRecord(id);
    _load();
  }

  Future<void> _toggleAudio(int index) async {
    final record = _records[index];
    
    // Check if audio file exists
    if (record.audioPath == null || record.audioPath!.isEmpty) {
      _showSnack('No audio file available', isError: true);
      return;
    }

    final audioFile = File(record.audioPath!);
    if (!await audioFile.exists()) {
      _showSnack('Audio file not found', isError: true);
      return;
    }

    // If same record is playing, pause/resume
    if (_playingIndex == index && _isPlaying) {
      await _audioPlayer.pause();
      return;
    }

    // If same record is paused, resume
    if (_playingIndex == index && !_isPlaying) {
      await _audioPlayer.resume();
      return;
    }

    // Play new audio
    setState(() => _playingIndex = index);
    await _audioPlayer.stop();
    await _audioPlayer.play(DeviceFileSource(record.audioPath!));
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.day}/${dt.month}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const AcuBeatHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'History',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${_records.length} records',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _records.isEmpty
                            ? Center(
                                child: Text(
                                  'No saved records yet',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 15,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: _records.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final r = _records[index];
                                  final isAbnormal = r.prediction
                                      .toLowerCase()
                                      .contains('abnormal');
                                  final hasAudio = r.audioPath != null && 
                                      r.audioPath!.isNotEmpty;
                                  final isThisPlaying = _playingIndex == index;
                                  // ✅ NEW: Check mode
                                  final isLungMode = r.mode == 'lung';

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isAbnormal
                                          ? Colors.red.shade50
                                          : Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isAbnormal
                                            ? Colors.red.shade200
                                            : Colors.green.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(
                                        backgroundColor: isAbnormal
                                            ? Colors.red.shade100
                                            : Colors.green.shade100,
                                        child: Icon(
                                          // ✅ NEW: Different icon based on mode
                                          isLungMode
                                              ? Icons.air
                                              : (isAbnormal
                                                  ? Icons.warning_rounded
                                                  : Icons.check_circle_rounded),
                                          color: isAbnormal
                                              ? Colors.red.shade700
                                              : Colors.green.shade700,
                                          size: 22,
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              r.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          // ✅ NEW: Mode badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isLungMode
                                                  ? Colors.blue.shade100
                                                  : Colors.red.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isLungMode ? 'LUNG' : 'HEART',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isLungMode
                                                    ? Colors.blue.shade700
                                                    : Colors.red.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 2),
                                          Text(
                                            'ID: ${r.patientId}  Age: ${r.age}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            '${r.prediction}  '
                                            '${r.confidence.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isAbnormal
                                                  ? Colors.red.shade700
                                                  : Colors.green.shade700,
                                            ),
                                          ),
                                          Text(
                                            _formatDate(r.timestamp),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // ✅ Play/Pause Audio Button
                                          if (hasAudio)
                                            IconButton(
                                              icon: Icon(
                                                isThisPlaying && _isPlaying
                                                    ? Icons.pause_circle_filled
                                                    : Icons.play_circle_filled,
                                                color: isThisPlaying && _isPlaying
                                                    ? Colors.blue.shade600
                                                    : Colors.grey.shade600,
                                                size: 28,
                                              ),
                                              onPressed: () => _toggleAudio(index),
                                            ),
                                          
                                          // Delete Button
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Colors.grey.shade400,
                                              size: 20,
                                            ),
                                            onPressed: () => _delete(r.id!),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}