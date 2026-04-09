import 'package:flutter/material.dart';
import '../widgets/acubeat_header.dart';
import '../services/database_service.dart';
import 'record_screen.dart';
import 'history_screen.dart';
import 'emotion_record.dart';

class LoginScreen extends StatefulWidget {
  final String mode; // 'medical' or 'emotion'
  
  const LoginScreen({super.key, required this.mode});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _nextPatientId = '';
  bool _isLoading = true;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _loadNextPatientId();
  }

  Future<void> _loadNextPatientId() async {
    try {
      final nextId = await DatabaseService.getNextPatientId();
      setState(() {
        _nextPatientId = nextId.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _nextPatientId = '1';
        _isLoading = false;
      });
    }
  }

  void _onRecord() {
    if (_isNavigating) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isNavigating = true);

    // Navigate based on mode
    if (widget.mode == 'medical') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecordScreen(
            patientId: _nextPatientId,
            name: _nameCtrl.text.trim(),
            age: _ageCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
          ),
        ),
      ).then((_) {
        if (mounted) setState(() => _isNavigating = false);
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmotionRecordScreen(
            patientId: _nextPatientId,
            name: _nameCtrl.text.trim(),
            age: _ageCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
          ),
        ),
      ).then((_) {
        if (mounted) setState(() => _isNavigating = false);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = widget.mode == 'medical' 
        ? Colors.red.shade400 
        : Colors.orange.shade400;
    
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          Column(
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.black87))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        widget.mode == 'medical' 
                                            ? Icons.favorite 
                                            : Icons.emoji_emotions,
                                        size: 50,
                                        color: primaryColor,
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        widget.mode == 'medical' 
                                            ? 'Medical Mode' 
                                            : 'Emotion Mode',
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                _buildPatientIdDisplay(primaryColor),
                                const SizedBox(height: 24),

                                _buildField(
                                  label: 'NAME',
                                  controller: _nameCtrl,
                                  keyboardType: TextInputType.name,
                                  primaryColor: primaryColor,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 18),
                                _buildField(
                                  label: 'AGE',
                                  controller: _ageCtrl,
                                  keyboardType: TextInputType.number,
                                  primaryColor: primaryColor,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    final age = int.tryParse(v.trim());
                                    if (age == null) return 'Enter a valid age';
                                    if (age < 1 || age > 150) return 'Enter age between 1-150';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                _buildField(
                                  label: 'PHONE NUMBER',
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  primaryColor: primaryColor,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    final phone = v.trim().replaceAll(RegExp(r'\D'), '');
                                    if (phone.length != 10) return 'Phone number must be exactly 10 digits';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 36),

                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isNavigating ? null : _onRecord,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 0,
                                    ),
                                    child: _isNavigating
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : Text(
                                            widget.mode == 'medical' ? 'Record Medical' : 'Record Emotion',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                          ),
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

          if (widget.mode == 'medical')
            Positioned(
              bottom: 25,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                    ),
                    child: const Icon(Icons.history, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPatientIdDisplay(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.badge_outlined, color: Colors.grey.shade600, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PATIENT ID',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 1.2),
              ),
              const SizedBox(height: 4),
              Text(_nextPatientId, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('AUTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required Color primaryColor,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 1.4),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade200,
            errorStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.red.shade300, width: 1)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          ),
        ),
      ],
    );
  }
}