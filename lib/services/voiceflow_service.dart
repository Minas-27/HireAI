import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Voiceflow Service - For English AI Interviews
/// Handles conversation flow and ElevenLabs voice synthesis
class VoiceflowService {
  static const String _baseUrl = 'https://general-runtime.voiceflow.com/state';
  static AudioPlayer? _audioPlayer;

  // Session management
  String? _sessionUserId;

  /// Initialize audio player
  static void initialize() {
    _audioPlayer = AudioPlayer();
  }

  /// Get API credentials
  static String get _apiKey => dotenv.env['VF_API_KEY'] ?? '';
  static String get _projectId => dotenv.env['VF_PROJECT_ID'] ?? '';
  static String get _versionId => dotenv.env['VF_VERSION_ID'] ?? 'production';

  /// Check if configured
  static bool get isConfigured => _apiKey.isNotEmpty && _projectId.isNotEmpty;

  /// Create interview session context
  Map<String, dynamic> _getInterviewContext({
    required String jobTitle,
    required String companyName,
    String? candidateName,
    List<String>? customQuestions,
    String? agentType,
  }) {
    return {
      'job_title': jobTitle,
      'company_name': companyName,
      'candidate_name': candidateName ?? 'Candidate',
      'is_interview': true,
      'custom_questions': customQuestions ?? [],
      'agent_type': agentType ?? 'Interviewer',
    };
  }

  /// Start a new interview session
  Future<Map<String, dynamic>> startInterviewSession({
    required String jobTitle,
    required String companyName,
    required String candidateName,
    List<String>? customQuestions,
    String? agentType,
  }) async {
    // Generate unique session ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _sessionUserId = 'interview_${timestamp}_${timestamp % 1000}';

    // Send launch request with interview context
    return await sendInterviewMessage(
      'Start interview for $jobTitle position at $companyName for $candidateName',
      jobTitle: jobTitle,
      companyName: companyName,
      candidateName: candidateName,
      customQuestions: customQuestions,
      agentType: agentType,
      isLaunch: true,
    );
  }

  /// Send interview message to Voiceflow
  Future<Map<String, dynamic>> sendInterviewMessage(
    String text, {
    required String jobTitle,
    required String companyName,
    String? candidateName,
    List<String>? customQuestions,
    String? agentType,
    bool isLaunch = false,
  }) async {
    try {
      if (!isConfigured) {
        throw Exception('Voiceflow not configured. Check API keys.');
      }

      // Create user ID if not exists
      _sessionUserId ??= 'user_${DateTime.now().millisecondsSinceEpoch}';

      final url = '$_baseUrl/user/$_sessionUserId/interact';

      debugPrint('🌐 [Voiceflow] URL: $url');
      debugPrint('📤 [Voiceflow] Message: "$text"');

      final variables = _getInterviewContext(
        jobTitle: jobTitle,
        companyName: companyName,
        candidateName: candidateName,
        customQuestions: customQuestions,
        agentType: agentType,
      );

      debugPrint(
        '📦 [Voiceflow] Variables being sent: ${jsonEncode(variables)}',
      );

      final requestBody = {
        'request':
            isLaunch ? {'type': 'launch'} : {'type': 'text', 'payload': text},
        'config': {'tts': true},
        'state': {'variables': variables},
      };

      final response = await _sendWithRetry(url, requestBody);

      debugPrint('📥 [Voiceflow] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('📥 [Voiceflow] Raw Response: ${jsonEncode(responseData)}');
        return _parseVoiceflowResponse(responseData);
      } else {
        return {
          'success': false,
          'error':
              'Failed to connect: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      debugPrint('💥 [Voiceflow] Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Parse Voiceflow response
  Map<String, dynamic> _parseVoiceflowResponse(dynamic responseData) {
    String textResponse = '';
    String? audioUrl;
    String? voiceInfo;

    if (responseData is List) {
      // Log all trace types for debugging
      for (var trace in responseData) {
        debugPrint('📋 [Voiceflow] Trace type: ${trace['type']}');
      }

      // Look for speak trace first
      for (var trace in responseData) {
        if (trace['type'] == 'speak') {
          textResponse = _cleanText(trace['payload']['message'] ?? '');
          voiceInfo = trace['payload']['voice'];
          audioUrl = trace['payload']['src'];
          debugPrint('🗣️ [Voiceflow] Speak Trace Found: "$textResponse"');
          break;
        }
      }

      // Check for AI Agent / Completion responses
      if (textResponse.isEmpty) {
        for (var trace in responseData) {
          final type = trace['type'];
          if (type == 'completion' || type == 'agent' || type == 'AI') {
            // AI Agent blocks return content in various payload formats
            final payload = trace['payload'];
            if (payload != null) {
              textResponse = _cleanText(
                payload['output'] ??
                    payload['message'] ??
                    payload['content'] ??
                    payload['text'] ??
                    (payload['result']?['answer'] ?? ''),
              );
              debugPrint('🤖 [Voiceflow] AI Agent Response: "$textResponse"');
              if (textResponse.isNotEmpty) break;
            }
          }
        }
      }

      // Fallback to text trace
      if (textResponse.isEmpty) {
        for (var trace in responseData) {
          if (trace['type'] == 'text') {
            if (trace['payload']['message'] != null) {
              textResponse = _cleanText(trace['payload']['message']);
            } else if (trace['payload']['slate'] != null) {
              textResponse = _parseSlateContent(trace['payload']['slate']);
            }
            audioUrl = trace['payload']['audio']?['src'];
            voiceInfo = trace['payload']['voice'];
            if (textResponse.isNotEmpty) break;
          }
        }
      }
    }

    return {
      'success': true,
      'text': textResponse.isNotEmpty ? textResponse : 'No response received',
      'audio_url': audioUrl,
      'voice_info': voiceInfo,
      'language': 'en',
    };
  }

  /// Parse Slate rich text content
  String _parseSlateContent(Map<String, dynamic> slate) {
    final buffer = StringBuffer();
    final content = slate['content'];

    if (content is List) {
      for (var node in content) {
        if (node['children'] is List) {
          for (var child in node['children']) {
            if (child['text'] != null) {
              buffer.write(child['text']);
            }
          }
        }
      }
    }

    return _cleanText(buffer.toString());
  }

  /// Send request with retry logic
  Future<http.Response> _sendWithRetry(
    String url,
    Map<String, dynamic> body, {
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      attempts++;
      try {
        final response = await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': _apiKey,
                'versionID': _versionId,
                'Accept': 'application/json',
              },
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode != 408 && response.statusCode != 504) {
          return response;
        }

        debugPrint('⚠️ [Voiceflow] Timeout (Attempt $attempts/$maxRetries)');
      } catch (e) {
        debugPrint('⚠️ [Voiceflow] Error (Attempt $attempts/$maxRetries): $e');
        if (attempts >= maxRetries) rethrow;
      }

      await Future.delayed(Duration(seconds: attempts * 2));
    }

    throw Exception('Failed after $maxRetries attempts');
  }

  /// Play audio from URL or Data URI
  static Future<void> playAudioFromUrl(String audioUrl) async {
    try {
      _audioPlayer ??= AudioPlayer();

      debugPrint(
        '🎵 [Voiceflow] Playing audio from: ${audioUrl.length > 50 ? audioUrl.substring(0, 50) + '...' : audioUrl}',
      );

      if (audioUrl.startsWith('data:')) {
        // Data URIs work across Web and Mobile with UrlSource
        await _audioPlayer!.play(UrlSource(audioUrl));
      } else {
        await _audioPlayer!.play(UrlSource(audioUrl));
      }
    } catch (e) {
      debugPrint('❌ [Voiceflow] Audio error: $e');
    }
  }

  /// Play audio from local file
  static Future<void> playAudioFromFile(String filePath) async {
    try {
      _audioPlayer ??= AudioPlayer();
      await _audioPlayer!.play(DeviceFileSource(filePath));
    } catch (e) {
      debugPrint('❌ [Voiceflow] Local audio error: $e');
    }
  }

  /// Stop audio playback
  static Future<void> stopAudio() async {
    await _audioPlayer?.stop();
  }

  /// Set volume (0.0 to 1.0)
  static Future<void> setVolume(double volume) async {
    await _audioPlayer?.setVolume(volume);
  }

  /// Clean text for display
  String _cleanText(String text) {
    String cleanText = text.replaceAll(
      RegExp(r'[^\p{L}\p{N}\s\p{P}]', unicode: true),
      '',
    );
    cleanText = cleanText.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleanText;
  }

  /// End interview session
  void endSession() {
    _sessionUserId = null;
    stopAudio();
  }

  /// Test connection
  Future<Map<String, dynamic>> testConnection() async {
    if (!isConfigured) {
      return {'success': false, 'error': 'Not configured'};
    }

    try {
      final result = await sendInterviewMessage(
        'Hello',
        jobTitle: 'Test',
        companyName: 'Test',
        isLaunch: true,
      );
      return {
        'success': result['success'],
        'message': result['success'] ? 'Connected' : result['error'],
      };
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Get service info
  static Map<String, dynamic> getServiceInfo() {
    return {
      'name': 'Voiceflow',
      'base_url': _baseUrl,
      'is_configured': isConfigured,
      'project_id': _projectId,
      'version_id': _versionId,
      'features': ['conversation', 'tts', 'interview'],
    };
  }
}
