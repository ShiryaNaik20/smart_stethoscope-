import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class EmotionService {
  // ⚠️ UPDATE THIS with your Colab ngrok URL
  static const String baseUrl = 'https://tyler-bucks-experience-merchant.trycloudflare.com';

  Future<Map<String, dynamic>> predictEmotion(String audioPath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict_emotion'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('audio', audioPath),
      );

      print('🎤 Sending to: $baseUrl/predict_emotion');

      var streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      var response = await http.Response.fromStream(streamedResponse);

      print('📊 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error in predictEmotion: $e');
      throw Exception('Error predicting emotion: $e');
    }
  }

  Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(Duration(seconds: 5));
      
      print('🏥 Health check: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }
}