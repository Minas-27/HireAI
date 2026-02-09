import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

/// ElevenLabs Service - Premium English Voice Synthesis
class ElevenLabsService {
  static const String _baseUrl = 'https://api.elevenlabs.io/v1';

  // Default voice ID (Rachel - professional female voice)
  static const String defaultVoiceId = '21m00Tcm4TlvDq8ikWAM';

  // API Key from .env
  static String get _apiKey => dotenv.env['ELEVEN_LABS_API_KEY'] ?? '';

  /// Check if configured
  static bool get isConfigured => _apiKey.isNotEmpty;

  /// Generate speech audio from text
  static Future<String?> generateAudio(String text, [String? voiceId]) async {
    if (!isConfigured) {
      print('❌ [ElevenLabs] API key not configured');
      return null;
    }

    final voice = voiceId ?? defaultVoiceId;
    final url = '$_baseUrl/text-to-speech/$voice';

    print(
      '🔊 [ElevenLabs] Generating audio for: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."',
    );

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'audio/mpeg',
          'Content-Type': 'application/json',
          'xi-api-key': _apiKey,
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_turbo_v2',
          'voice_settings': {'stability': 0.5, 'similarity_boost': 0.5},
        }),
      );

      print('📡 [ElevenLabs] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (kIsWeb) {
          final base64String = base64Encode(response.bodyBytes);
          final dataUri = 'data:audio/mpeg;base64,$base64String';
          print('🌐 [ElevenLabs] Using Data URI for audio on Web');
          return dataUri;
        } else {
          // Save audio to temp file
          final tempPath = await _getSafeTempDirPath();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filePath = '$tempPath/elevenlabs_$timestamp.mp3';

          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          print('✅ [ElevenLabs] Audio saved to: $filePath');
          return filePath;
        }
      } else {
        print('❌ [ElevenLabs] Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ [ElevenLabs] Exception: $e');
      return null;
    }
  }

  /// Get available voices
  static Future<List<Map<String, dynamic>>> getVoices() async {
    if (!isConfigured) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/voices'),
        headers: {'xi-api-key': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['voices'] ?? []);
      }
    } catch (e) {
      print('❌ [ElevenLabs] Error fetching voices: $e');
    }

    return [];
  }

  /// Get service info
  static Map<String, dynamic> getServiceInfo() {
    return {
      'name': 'ElevenLabs',
      'base_url': _baseUrl,
      'is_configured': isConfigured,
      'default_voice_id': defaultVoiceId,
      'features': ['tts', 'voice_cloning'],
    };
  }

  /// Helper to get temp directory path with Windows fallback
  static Future<String> _getSafeTempDirPath() async {
    if (kIsWeb) return '';

    try {
      final dir = await getTemporaryDirectory();
      return dir.path;
    } catch (e) {
      if (!kIsWeb && Platform.isWindows) {
        return Platform.environment['TEMP'] ??
            Platform.environment['TMP'] ??
            Directory.systemTemp.path;
      }
      rethrow;
    }
  }
}
