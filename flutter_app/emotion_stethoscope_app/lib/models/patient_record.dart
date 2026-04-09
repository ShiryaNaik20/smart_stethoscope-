class PatientRecord {
  final int? id;
  final String patientId;
  final String name;
  final String age;
  final String phone;
  final String prediction;
  final String murmur;
  final double confidence;
  final String? audioPath;
  final String timestamp;
  final String mode; // ✅ ADDED: 'heart' or 'lung'

  PatientRecord({
    this.id,
    required this.patientId,
    required this.name,
    required this.age,
    required this.phone,
    required this.prediction,
    required this.murmur,
    required this.confidence,
    this.audioPath,
    required this.timestamp,
    required this.mode, // ✅ ADDED
  });

  Map<String, dynamic> toMap() => {
        'patient_id': patientId,
        'name': name,
        'age': age,
        'phone': phone,
        'prediction': prediction,
        'murmur': murmur,
        'confidence': confidence,
        'audio_path': audioPath,
        'timestamp': timestamp,
        'mode': mode, // ✅ ADDED
      };

  factory PatientRecord.fromMap(Map<String, dynamic> map) => PatientRecord(
        id: map['id'],
        patientId: map['patient_id'],
        name: map['name'],
        age: map['age'],
        phone: map['phone'],
        prediction: map['prediction'],
        murmur: map['murmur'] ?? '',
        confidence: map['confidence'],
        audioPath: map['audio_path'],
        timestamp: map['timestamp'],
        mode: map['mode'] ?? 'heart', // ✅ ADDED: default to 'heart' for old records
      );
}