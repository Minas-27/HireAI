import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Addis AI Service - For Amharic AI Interviews
/// Handles Amharic chat and text-to-speech capabilities
class AddisAIService {
  // Addis AI API endpoints
  static const String _baseUrl = 'https://api.addisassistant.com/api/v1';
  static const String _chatEndpoint = '$_baseUrl/chat_generate';
  static const String _ttsEndpoint = '$_baseUrl/audio';

  // API Key from .env file
  static String get _apiKey => dotenv.env['ADDIS_AI_API_KEY'] ?? '';

  // Check if API key is available
  static bool get hasApiKey => _apiKey.isNotEmpty;

  /// System prompt for AI Interviewer
  static String getInterviewerPrompt({
    required String jobTitle,
    required String companyName,
    required String candidateName,
    List<String>? customQuestions,
  }) {
    return '''
You are NEXA, an AI interviewer for $companyName conducting an interview for the $jobTitle position with $candidateName.

Your role:
- Conduct a professional but friendly interview in Amharic
- Ask relevant questions about the candidate's experience and skills
- Listen carefully and ask follow-up questions
- Evaluate responses for technical competence, communication skills, and cultural fit
- Be encouraging but objective

Interview Guidelines:
- Start with a warm greeting and introduction
- Ask about their background and experience
- Probe technical skills relevant to $jobTitle
- Assess problem-solving abilities
- Evaluate communication and cultural fit
- End with asking if they have questions

${customQuestions != null && customQuestions.isNotEmpty ? 'Custom questions to include:\n${customQuestions.map((q) => '- $q').join('\n')}' : ''}

Remember: Be conversational, use natural Amharic, and make the candidate feel comfortable. 
CRITICAL RULE: NEVER use slashes (/) like 'አቶ/ወይዘሮ' or 'አደሩ/ዋልሽ'. 
Instead of time-specific greetings, ALWAYS use the neutral and professional 'ጤና ይስጥልኝ' (Tena Yistilign) to start. 
Address the candidate simply by their name ($candidateName) or use the formal 'እርስዎ' (you). 
NEVER use 'Mr/Mrs' (አቶ/ወይዘሮ) as it sounds like a bot template.
''';
  }

  /// Send Amharic chat message for interview
  static Future<Map<String, dynamic>> sendInterviewChat(
    String userMessage, {
    required String jobTitle,
    required String companyName,
    required String candidateName,
    List<String>? conversationHistory,
    List<String>? customQuestions,
  }) async {
    if (!hasApiKey) {
      return {'success': false, 'error': 'API key not configured'};
    }

    print('🤖 [Addis AI] Sending interview message: "$userMessage"');

    try {
      // Build conversation context
      final systemPrompt = getInterviewerPrompt(
        jobTitle: jobTitle,
        companyName: companyName,
        candidateName: candidateName,
        customQuestions: customQuestions,
      );

      String fullPrompt = systemPrompt;

      // Add conversation history
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        fullPrompt +=
            '\n\nConversation so far:\n${conversationHistory.join('\n')}';
      }

      fullPrompt += '\n\nCandidate: $userMessage\n\nNEXA (Interviewer):';

      final response = await http.post(
        Uri.parse(_chatEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': _apiKey,
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'prompt': fullPrompt,
          'target_language': 'am',
          'generation_config': {'temperature': 0.7, 'stream': false},
        }),
      );

      print('📡 [Addis AI] Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String responseText = '';
        if (data['status'] == 'success' && data['data'] != null) {
          responseText = data['data']['response_text'] ?? '';
        } else {
          responseText = data['response_text'] ?? '';
        }

        return {
          'success': true,
          'response_text': responseText,
          'language': 'am',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error':
              errorData['error'] ??
              errorData['message'] ??
              'Chat request failed',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ [Addis AI] Exception: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Convert Amharic text to speech
  static Future<Map<String, dynamic>> synthesizeSpeech(String text) async {
    if (!hasApiKey) {
      return {'success': false, 'error': 'API key not configured'};
    }

    print('🔊 [Addis AI TTS] Converting: "$text"');

    try {
      final response = await http.post(
        Uri.parse(_ttsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': _apiKey,
          'Accept': 'application/json',
        },
        body: jsonEncode({'text': text, 'language': 'am'}),
      );

      print('📡 [Addis AI TTS] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audioBase64 = data['audio'] ?? '';

        return {
          'success': true,
          'audio_base64': audioBase64,
          'text': text,
          'language': 'am',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'TTS request failed',
          'status_code': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ [Addis AI TTS] Exception: $e');
      return {'success': false, 'error': 'TTS network error: $e'};
    }
  }

  /// Check if text contains Amharic characters
  static bool isAmharicText(String text) {
    return text.contains(RegExp(r'[\u1200-\u137F]'));
  }

  /// Test connection to Addis AI
  static Future<Map<String, dynamic>> testConnection() async {
    if (!hasApiKey) {
      return {'success': false, 'error': 'API key not configured'};
    }

    try {
      final result = await sendInterviewChat(
        'ሰላም',
        jobTitle: 'Test Position',
        companyName: 'Test Company',
        candidateName: 'Test Candidate',
      );
      return {
        'success': result['success'],
        'message':
            result['success'] ? 'Connection successful' : result['error'],
      };
    } catch (e) {
      return {'success': false, 'error': 'Connection test failed: $e'};
    }
  }

  /// Get service info
  static Map<String, dynamic> getServiceInfo() {
    return {
      'name': 'Addis AI',
      'version': 'v1',
      'base_url': _baseUrl,
      'has_api_key': hasApiKey,
      'supported_languages': ['am'],
      'features': ['chat', 'tts', 'interview'],
    };
  }
}
