import 'package:flutter/material.dart';
import '../models/patient_record.dart';
import '../services/database_service.dart';
import '../widgets/acubeat_header.dart';
import 'login_screen.dart';
import 'history_screen.dart';

class ResultScreen extends StatefulWidget {
  final String patientId, name, age, phone, prediction;
  final double confidence;
  final double bpm;
  final String audioPath;
  final String murmur;
  final String mode; // ✅ ADDED: 'heart' or 'lung'
  final String lungClass; // ✅ ADDED: For lung predictions (Normal, Crackle, Wheeze, Both)

  const ResultScreen({
    super.key,
    required this.patientId,
    required this.name,
    required this.age,
    required this.phone,
    required this.prediction,
    required this.confidence,
    required this.bpm,
    required this.audioPath,
    required this.murmur,
    required this.mode, // ✅ ADDED
    required this.lungClass, // ✅ ADDED
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _saved  = false;
  bool _saving = false;

  bool get _isAbnormal =>
      widget.prediction.toLowerCase().contains('abnormal');

  // ✅ NEW: Check if mode is lung
  bool get _isLungMode => widget.mode == 'lung';

  Future<void> _saveRecord() async {
    if (_saved) { _showSnack('Already saved!'); return; }
    setState(() => _saving = true);
    try {
      final record = PatientRecord(
        patientId:  widget.patientId,
        name:       widget.name,
        age:        widget.age,
        phone:      widget.phone,
        prediction: widget.prediction,
        murmur: widget.murmur,
        confidence: widget.confidence,
        audioPath:  widget.audioPath,
        timestamp:  DateTime.now().toIso8601String(),
        mode: widget.mode, // ✅ ADDED: Save the mode
      );
      await DatabaseService.saveRecord(record);
      if (!mounted) return;
      setState(() { _saved = true; _saving = false; });
      _showSnack('Saved successfully', isSuccess: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('Failed to save: $e', isError: true);
    }
  }

  // void _goHome() => Navigator.pushAndRemoveUntil(
  //       context,
  //       MaterialPageRoute(builder: (_) => const LoginScreen()),
  //       (_) => false,
  //     );

  void _goHome() => Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(
    builder: (_) => LoginScreen(mode: 'medical'),
  ),
  (_) => false,
);

  void _goHistory() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      );

  void _showSnack(String msg,
      {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess
            ? Colors.green.shade700
            : isError
                ? Colors.red.shade700
                : Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          const AcuBeatHeader(),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft:  Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                          28, 28, 28, 16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // ── Result card ──────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 24),
                            decoration: BoxDecoration(
                              color: _isAbnormal
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              borderRadius:
                                  BorderRadius.circular(18),
                              border: Border.all(
                                color: _isAbnormal
                                    ? Colors.red.shade300
                                    : Colors.green.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _isAbnormal
                                      ? Icons.warning_rounded
                                      : Icons
                                          .check_circle_rounded,
                                  color: _isAbnormal
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                  size: 44,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.prediction,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: _isAbnormal
                                        ? Colors.red.shade800
                                        : Colors.green.shade800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Confidence: '
                                  '${widget.confidence.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: _isAbnormal
                                        ? Colors.red.shade600
                                        : Colors.green.shade600,
                                  ),
                                ),

                                // ✅ NEW: Show lung class if lung mode
                                if (_isLungMode && widget.lungClass.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(
                                              20),
                                      border: Border.all(
                                        color: _isAbnormal
                                            ? Colors.red.shade200
                                            : Colors
                                                .green.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize:
                                          MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.air,
                                          color: Colors
                                              .blue.shade400,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          widget.lungClass,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.bold,
                                            color: Colors
                                                .black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // ── BPM badge (only for heart) ──
                                if (!_isLungMode && widget.bpm > 0) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(
                                              20),
                                      border: Border.all(
                                        color: _isAbnormal
                                            ? Colors.red.shade200
                                            : Colors
                                                .green.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize:
                                          MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons
                                              .favorite_rounded,
                                          color: Colors
                                              .red.shade400,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${widget.bpm.toStringAsFixed(1)} BPM',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.bold,
                                            color: Colors
                                                .black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Details table ─────────────────
                          _row('Patient Name', widget.name),
                          _divider(),
                          _row('Patient ID', widget.patientId),
                          _divider(),
                          _row('Age', widget.age),
                          _divider(),
                          _row('Phone', widget.phone),
                          _divider(),
                          // ✅ NEW: Show mode type
                          _row('Type', _isLungMode ? 'Lung Sound' : 'Heart Sound'),
                          _divider(),
                          _row('Prediction', widget.prediction),
                          _divider(),
                          
                          // ✅ CONDITIONAL: Show lung class OR murmur based on mode
                          if (_isLungMode)
                            _row('Lung Class', widget.lungClass.isEmpty ? 'Unknown' : widget.lungClass)
                          else
                            _row('Murmur', widget.murmur.isEmpty ? 'Not Checked' : widget.murmur),
                          _divider(),
                          
                          _row('Confidence',
                              '${widget.confidence.toStringAsFixed(1)}%'),
                          _divider(),
                          
                          // ✅ CONDITIONAL: Only show BPM for heart mode
                          if (!_isLungMode) ...[
                            _row(
                              'Heart Rate',
                              widget.bpm > 0
                                  ? '${widget.bpm.toStringAsFixed(1)} BPM'
                                  : 'Not detected',
                            ),
                            _divider(),
                          ],
                          
                          _row('Date',
                              _formatDate(DateTime.now())),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // ── Bottom buttons ────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        28, 8, 28, 32),
                    child: Row(
                      children: [
                        // Home
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _goHome,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Text('Home',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Save
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed:
                                  (_saving || _saved)
                                      ? null
                                      : _saveRecord,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _saved
                                    ? Colors.green.shade700
                                    : Colors.black,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: _saved
                                    ? Colors.green.shade600
                                    : Colors.grey.shade300,
                                disabledForegroundColor:
                                    Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _saved ? 'Saved ✓' : 'Save',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // History
                        SizedBox(
                          height: 54,
                          width: 54,
                          child: ElevatedButton(
                            onPressed: _goHistory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.grey.shade800,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Icon(
                                Icons.history, size: 22),
                          ),
                        ),
                      ],
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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                )),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 12,
        thickness: 0.5,
        color: Colors.grey.shade200,
      );

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}