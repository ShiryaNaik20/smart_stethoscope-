import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class PredictionService {
  final String serverUrl;

  PredictionService(this.serverUrl);

  // ✅ UPDATED: Now accepts mode parameter (heart or lung)
  Future<Map<String, dynamic>> predict(
      List<int> int16Samples, String mode) async {
    final byteData = ByteData(int16Samples.length * 2);
    for (int i = 0; i < int16Samples.length; i++) {
      byteData.setInt16(i * 2, int16Samples[i], Endian.little);
    }

    print('[HTTP] Sending ${int16Samples.length} samples '
        'to $serverUrl/predict_all?mode=$mode');

    // ✅ UPDATED: Changed endpoint to /predict_all with mode query parameter
    final response = await http
        .post(
          Uri.parse('$serverUrl/predict_all?mode=$mode'),
          headers: {
            'Content-Type': 'application/octet-stream',
            'ngrok-skip-browser-warning': 'true',
          },
          body: byteData.buffer.asUint8List(),
        )
        .timeout(const Duration(seconds: 30));

    print('[HTTP] Response ${response.statusCode}: '
        '${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
          'Server error ${response.statusCode}: '
          '${response.body}');
    }

    final decoded =
        json.decode(response.body) as Map<String, dynamic>;

    if (decoded.containsKey('error')) {
      throw Exception('Model error: ${decoded['error']}');
    }

    // ✅ Ensure bpm field always exists with a default of 0.0
    decoded['bpm'] ??= 0.0;

    return decoded;
  }
}