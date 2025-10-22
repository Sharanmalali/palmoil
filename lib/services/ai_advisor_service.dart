import 'dart:convert';
import 'package:http/http.dart' as http;

class AiAdvisorService {
  // =======================================================================
  // ==  1. PASTE YOUR GOOGLE AI API KEY HERE                             ==
  // =======================================================================
  // Get your key from https://aistudio.google.com/
  
  final String _googleAiApiKey = 'AIzaSyBbX04liTbjF_ts-jSUli5BlmBd4VjmXdY';

  // =======================================================================

  Future<String> sendMessage(String message, List<Map<String, String>> history) async {
    if (_googleAiApiKey == 'YOUR_GOOGLE_AI_API_KEY_GOES_HERE') {
      return "Please add your Google AI API key to ai_advisor_service.dart";
    }

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=$_googleAiApiKey');
    
    // Create the conversation history in the format Gemini expects
    final geminiHistory = history.map((msg) {
      return {
        "role": msg['author'] == 'user' ? 'user' : 'model',
        "parts": [{"text": msg['text']}]
      };
    }).toList();

    final systemPrompt = {
      "parts": [
        {"text": "You are Atma-Palm, an expert AI assistant for oil palm farmers. Your purpose is to provide clear, concise, and actionable advice related to oil palm cultivation. Answer only questions related to farming, agriculture, and oil palms."}
      ]
    };
    
    final payload = jsonEncode({
      "contents": [
        ...geminiHistory, // Add the previous chat history
        {
          "role": "user",
          "parts": [{"text": message}]
        }
      ],
      "systemInstruction": systemPrompt,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody['candidates'][0]['content']['parts'][0]['text'];
      } else {
        final errorBody = jsonDecode(response.body);
        return 'Error from API: ${errorBody['error']['message']}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }
}
