import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/utils/constants.dart';

class AIService {
  // Direct HTTP for better control over Vision calls with Gemini 2.5 Flash
  Future<String> getAIResponse(String prompt) async {
    final String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${AppConstants.geminiApiKey}";
    
    return await _makePostRequest(url, {
      "contents": [
        {
          "parts": [{"text": prompt}]
        }
      ]
    });
  }

  Future<String> getAIImageResponse(String prompt, Uint8List imageBytes) async {
    final String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${AppConstants.geminiApiKey}";

    // Multi-modal request structure for Gemini
    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt.isEmpty ? "What is in this image?" : prompt},
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Encode(imageBytes)
              }
            }
          ]
        }
      ]
    };

    return await _makePostRequest(url, body);
  }

  Future<String> _makePostRequest(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
        return "AI returned an empty response.";
      } else {
        final errorData = jsonDecode(response.body);
        return "Error ${response.statusCode}: ${errorData['error']['message']}";
      }
    } catch (e) {
      return "Connection Error: $e";
    }
  }
}
