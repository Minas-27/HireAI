import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'addis_ai_service.dart';
import 'voiceflow_service.dart';
import 'eleven_labs_service.dart';

/// Dual Voice Service - Orchestrates Amharic (Addis AI) and English (Voiceflow/ElevenLabs)
class DualVoiceService {
  // Singleton instance
  static final DualVoiceService _instance = DualVoiceService._internal();
  factory DualVoiceService() => _instance;
  DualVoiceService._internal();

  // Services
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final VoiceflowService _voiceflowService =
      VoiceflowService(); // Instance for state management
  final AudioPlayer _audioPlayer = AudioPlayer();

  // State
  bool _isInitialized = false;
  bool _isListening = false;
  String _currentLocaleId = 'en-US';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get currentLocaleId => _currentLocaleId;

  // Error Listener
  Function(String error)? _onErrorListener;

  /// Initialize all services
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🎙️ [DualVoiceService] Initializing...');

    // 1. Initialize Speech to Text
    try {
      bool available = await _speech.initialize(
        onStatus: (status) => print('🎤 [STT] Status: $status'),
        onError: (errorNotification) {
          print('❌ [STT] Error: $errorNotification');
          String msg = errorNotification.errorMsg;
          if (msg.contains('error_network')) {
            msg = 'Network error. Please check internet connection.';
          }
          _onErrorListener?.call(msg);
        },
      );
      print('🎤 [STT] Available: $available');
    } catch (e) {
      print('❌ [STT] Init failed: $e');
    }

    // 2. Initialize Flutter TTS (Fallback)
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      print('❌ [FlutterTTS] Init failed: $e');
    }

    // 3. Initialize Voiceflow
    VoiceflowService.initialize();

    _isInitialized = true;
    print('✅ [DualVoiceService] Initialization complete');
  }

  /// Start listening for speech
  Future<void> startListening({
    required Function(String text) onResult,
    required String localeId, // 'en-US' or 'am-ET'
    Function(String error)? onError,
  }) async {
    if (!_isInitialized) await initialize();

    // Stop TTS if playing
    await stopSpeaking();

    _currentLocaleId = localeId;
    _isListening = true;
    _onErrorListener = onError; // Set the current listener

    print('🎤 [DualVoiceService] Listening ($localeId)...');

    // For Amharic, standard STT might be weak on some devices,
    // but we'll try to use the system's best available recognizer.
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _isListening = false;
          onResult(result.recognizedWords);
        }
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.dictation,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Stop speaking/audio
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    await _audioPlayer.stop();
    await VoiceflowService.stopAudio();
  }

  /// Mute/Unmute audio without stopping playback
  Future<void> muteAudio(bool muted) async {
    final double volume = muted ? 0.0 : 1.0;

    // Mute FlutterTTS
    await _flutterTts.setVolume(volume);

    // Mute AudioPlayer (Addis AI / ElevenLabs file playback)
    await _audioPlayer.setVolume(volume);

    // Mute Voiceflow (Remote playback)
    await VoiceflowService.setVolume(volume);

    // Note: If using other players, mute them here too
    if (muted) {
      print('🔇 [DualVoiceService] Audio muted (continuing silently)');
    } else {
      print('🔊 [DualVoiceService] Audio unmuted (restored volume)');
    }
  }

  /// Start Interview Session
  Future<Map<String, dynamic>> startInterview({
    required String jobTitle,
    required String companyName,
    required String candidateName,
    required String localeId,
    String? agentType,
    List<String>? customQuestions,
  }) async {
    print('🎬 [DualVoiceService] Starting interview ($localeId)...');

    if (localeId.startsWith('am')) {
      // --- AMHARIC (Addis AI) ---
      // Send a starting prompt/message with candidate name and agent instruction
      String prompt =
          'ቃለ መጠይቅ ጀምር ለ $candidateName. ሰላምታ በመስጠት ጀምር።'; // Start interview for [Name]. Start with a greeting.
      if (agentType != null) {
        prompt += ' እንደ $agentType ሆነህ ተጫወት።'; // "Act as [AgentType]"
      }

      return processInput(
        text: prompt,
        localeId: localeId,
        jobTitle: jobTitle,
        companyName: companyName,
        candidateName: candidateName,
        contextHistory: [], // New session
        customQuestions: customQuestions,
      );
    } else {
      // --- ENGLISH (Voiceflow) ---
      // Voiceflow has specific launch logic
      final result = await _voiceflowService.startInterviewSession(
        jobTitle: jobTitle,
        companyName: companyName,
        candidateName: candidateName,
        customQuestions: customQuestions,
        agentType: agentType,
      );

      // Handle TTS fallback for English start
      if (result['success'] == true) {
        String? audioUrl = result['audio_url'];
        final String responseText = result['text'];

        if (audioUrl == null && responseText.isNotEmpty) {
          if (ElevenLabsService.isConfigured) {
            final filePath = await ElevenLabsService.generateAudio(
              responseText,
            );
            if (filePath != null) result['audio_path'] = filePath;
          }
        }
      }
      return result;
    }
  }

  /// Process text input and get AI response (Text & Audio)
  Future<Map<String, dynamic>> processInput({
    required String text,
    required String localeId, // 'en-US' or 'am-ET'
    required String jobTitle,
    required String companyName,
    String? candidateName,
    String? agentType,
    List<String>? contextHistory,
    List<String>? customQuestions,
  }) async {
    print('🧠 [DualVoiceService] Processing: "$text" ($localeId)');

    if (localeId.startsWith('am')) {
      // --- AMHARIC (Addis AI) ---
      return _processAmharic(
        text,
        jobTitle,
        companyName,
        candidateName: candidateName,
        history: contextHistory,
        customQuestions: customQuestions,
      );
    } else {
      // --- ENGLISH (Voiceflow) ---
      return _processEnglish(
        text,
        jobTitle,
        companyName,
        candidateName: candidateName,
        agentType: agentType,
        customQuestions: customQuestions,
      );
    }
  }

  /// Handle Amharic Flow
  Future<Map<String, dynamic>> _processAmharic(
    String text,
    String jobTitle,
    String companyName, {
    String? candidateName,
    List<String>? history,
    List<String>? customQuestions,
  }) async {
    // 1. Get AI Response
    final chatResult = await AddisAIService.sendInterviewChat(
      text,
      jobTitle: jobTitle,
      companyName: companyName,
      candidateName: candidateName ?? 'Candidate',
      conversationHistory: history,
      customQuestions: customQuestions,
    );

    if (!chatResult['success']) {
      return chatResult;
    }

    final responseText = chatResult['response_text'];

    // 2. Synthesize Speech (Addis AI)
    // We do this in the background or immediately request it
    final ttsResult = await AddisAIService.synthesizeSpeech(responseText);

    String? audioPath;
    if (ttsResult['success'] && ttsResult['audio_base64'] != null) {
      if (kIsWeb) {
        // On Web, we'll use a Data URI instead of saving to a file
        audioPath = 'data:audio/mpeg;base64,${ttsResult['audio_base64']}';
        print('🌐 [DualVoiceService] Using Data URI for Amharic audio on Web');
      } else {
        try {
          final bytes = base64Decode(ttsResult['audio_base64']);
          final dirPath = await _getSafeTempDirPath();
          final fileName =
              'addis_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
          final filePath = p.join(dirPath, fileName);

          final file = File(filePath);
          await file.writeAsBytes(bytes);
          audioPath = file.path;
          print('✅ [DualVoiceService] Amharic audio saved to: $audioPath');
        } catch (e) {
          print('❌ [DualVoiceService] Amharic Audio Save Error: $e');
        }
      }
    } else if (!ttsResult['success']) {
      print('❌ [DualVoiceService] Amharic TTS Failed: ${ttsResult['error']}');
    }

    return {
      'success': true,
      'text': responseText,
      'audio_path': audioPath,
      'source': 'addis_ai',
      'language': 'am',
    };
  }

  /// Handle English Flow
  Future<Map<String, dynamic>> _processEnglish(
    String text,
    String jobTitle,
    String companyName, {
    String? candidateName,
    String? agentType,
    List<String>? customQuestions,
  }) async {
    // 1. Send to Voiceflow with full context
    final result = await _voiceflowService.sendInterviewMessage(
      text,
      jobTitle: jobTitle,
      companyName: companyName,
      candidateName: candidateName,
      agentType: agentType,
      customQuestions: customQuestions,
    );

    // Voiceflow handles TTS internally usually (returns audio URL)
    // If it returns text but no audio, we can fall back to ElevenLabs
    if (result['success'] == true) {
      String? audioUrl = result['audio_url'];
      final String responseText = result['text'];

      if (audioUrl == null && responseText.isNotEmpty) {
        // Fallback to ElevenLabs if configured
        if (ElevenLabsService.isConfigured) {
          print(
            '🔄 [DualVoiceService] Voiceflow returned no audio, using ElevenLabs fallback...',
          );
          final filePath = await ElevenLabsService.generateAudio(responseText);
          if (filePath != null) {
            result['audio_path'] = filePath; // Use local path
          }
        } else {
          // Fallback to Flutter TTS
          print(
            '🔄 [DualVoiceService] Voiceflow returned no audio, using FlutterTTS fallback...',
          );
          // We don't generate a file for FlutterTTS, we just play it directly usually.
          // But to keep consistency, we might just tag it.
          result['use_flutter_tts'] = true;
        }
      }
    }

    return result;
  }

  /// Play audio from response
  Future<void> playResponseAudio(Map<String, dynamic> response) async {
    await stopSpeaking();

    // 1. Check for local file path or Data URI (Addis AI or ElevenLabs)
    if (response['audio_path'] != null) {
      final String path = response['audio_path'];
      try {
        if (path.startsWith('data:')) {
          print('▶️ [DualVoiceService] Playing Data URI audio');
          await _audioPlayer.play(UrlSource(path));
        } else {
          print('▶️ [DualVoiceService] Playing local file: $path');
          await _audioPlayer.play(DeviceFileSource(path));
        }
        return;
      } catch (e) {
        print('❌ [DualVoiceService] Play audio error: $e');
      }
    }

    // 2. Check for remote URL (Voiceflow)
    if (response['audio_url'] != null) {
      await VoiceflowService.playAudioFromUrl(response['audio_url']);
      return;
    }

    // 3. Fallback: Flutter TTS
    if (response['text'] != null) {
      print(
        '▶️ [DualVoiceService] Playing via FlutterTts: ${response['text']}',
      );
      String lang = response['language'] == 'am' ? 'am-ET' : 'en-US';

      // Note: flutter_tts might not support Amharic on all devices
      if (lang == 'am-ET') {
        // Check if Amharic is supported
        bool isAvailable = await _flutterTts.isLanguageAvailable("am-ET");
        if (!isAvailable) {
          // Fallback to English TTS for error or just silent?
          // Or maybe try to speak it anyway (some engines might try)
          print(
            '⚠️ [DualVoiceService] Amharic TTS not available on device engine',
          );
        }
        await _flutterTts.setLanguage("am-ET");
      } else {
        await _flutterTts.setLanguage("en-US");
      }

      await _flutterTts.speak(response['text']);
    }
  }

  /// Speak simple text immediately (Assistant notifications etc)
  Future<void> speak(String text, {String language = 'en-US'}) async {
    await stopSpeaking();
    await _flutterTts.setLanguage(language);
    await _flutterTts.speak(text);
  }

  /// Helper to get temp directory path with Windows fallback for MissingPluginException
  Future<String> _getSafeTempDirPath() async {
    if (kIsWeb) return ''; // Should not be called on Web

    try {
      final dir = await getTemporaryDirectory();
      return dir.path;
    } catch (e) {
      print('⚠️ [DualVoiceService] path_provider failed, using fallback: $e');
      if (!kIsWeb && Platform.isWindows) {
        final tempDir =
            Platform.environment['TEMP'] ??
            Platform.environment['TMP'] ??
            Directory.systemTemp.path;
        print('📂 [DualVoiceService] Windows fallback temp dir: $tempDir');
        return tempDir;
      }
      rethrow;
    }
  }
}
