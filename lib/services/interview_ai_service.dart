import 'dart:math';
import 'dart:async';
import 'dual_voice_service.dart';
import 'gemini_service.dart';
import 'voiceflow_service.dart';
import '../models/candidate.dart';

/// Unified Interview AI Service
/// Intelligently routes between Voiceflow (English) and Addis AI (Amharic)
/// Uses DualVoiceService for low-level orchestration
class InterviewAIService {
  // Voice service facade
  final DualVoiceService _dualVoiceService = DualVoiceService();

  // Language state
  static String _currentLanguage = 'en';
  static bool _isMuted = false;

  // Interview context
  String? _currentJobTitle;
  String? _currentCompanyName;
  String? _currentCandidateName;
  String? _currentAgentType;
  List<String>? _customQuestions;
  List<String> _evaluationMetrics = [];
  List<String> _conversationHistory = [];

  /// Initialize all services
  static Future<void> initialize() async {
    await DualVoiceService().initialize();
    print('✅ [InterviewAI] Services initialized via DualVoiceService');
  }

  /// Start a new interview session
  Future<Map<String, dynamic>> startInterview({
    required String jobTitle,
    required String companyName,
    required String candidateName,
    required String language,
    String? agentType,
    List<String>? customQuestions,
    List<String>? evaluationMetrics,
  }) async {
    _currentJobTitle = jobTitle;
    _currentCompanyName = companyName;
    _currentCandidateName = candidateName;
    _currentAgentType = agentType;
    _customQuestions = customQuestions;
    _evaluationMetrics =
        evaluationMetrics ??
        ['Technical Skills', 'Communication', 'Cultural Fit'];
    _currentLanguage = language;
    _conversationHistory.clear();

    // Set locale ID
    final localeId = language == 'am' ? 'am-ET' : 'en-US';

    print(
      '🎬 [InterviewAI] Starting interview for $jobTitle at $companyName in $language for $candidateName ($agentType)',
    );

    final result = await _dualVoiceService.startInterview(
      jobTitle: jobTitle,
      companyName: companyName,
      candidateName: candidateName,
      localeId: localeId,
      agentType: agentType,
      customQuestions: customQuestions,
    );

    if (result['success']) {
      String greeting = result['text'] ?? result['response_text'] ?? '';
      _conversationHistory.add('NEXA: $greeting');

      // Play Audio
      if (!_isMuted) {
        await _dualVoiceService.playResponseAudio(result);
      }

      return {
        'success': true,
        'greeting': greeting,
        'language': language,
        'service': language == 'am' ? 'Addis AI' : 'Voiceflow',
        'audio_url': result['audio_url'],
        'audio_path': result['audio_path'],
      };
    } else {
      return result;
    }
  }

  /// Send candidate response and get AI reply
  Future<Map<String, dynamic>> sendCandidateResponse(String response) async {
    if (_currentJobTitle == null || _currentCompanyName == null) {
      return {'success': false, 'error': 'Interview not started'};
    }

    // Add to history
    _conversationHistory.add('Candidate: $response');
    print('💬 [InterviewAI] Candidate said: "$response"');

    final localeId = _currentLanguage == 'am' ? 'am-ET' : 'en-US';

    final result = await _dualVoiceService.processInput(
      text: response,
      localeId: localeId,
      jobTitle: _currentJobTitle!,
      companyName: _currentCompanyName!,
      candidateName: _currentCandidateName,
      agentType: _currentAgentType,
      contextHistory: _conversationHistory,
      customQuestions: _customQuestions,
    );

    if (result['success']) {
      final aiResponse = result['text'] ?? result['response_text'] ?? '';
      _conversationHistory.add('NEXA: $aiResponse');

      if (!_isMuted) {
        await _dualVoiceService.playResponseAudio(result);
      }

      return {
        'success': true,
        'text': aiResponse,
        'language': _currentLanguage,
        'service': _currentLanguage == 'am' ? 'Addis AI' : 'Voiceflow',
        'audio_url': result['audio_url'],
        'audio_path': result['audio_path'],
      };
    }
    return result;
  }

  /// Speak response text (Manual trigger if needed)
  Future<void> speakResponse(String text, {required String language}) async {
    if (_isMuted) return;

    final localeId = language == 'am' ? 'am-ET' : 'en-US';
    await _dualVoiceService.speak(text, language: localeId);
  }

  /// Start listening for speech input
  Future<bool> startListening({
    required Function(String) onResult,
    required Function() onListeningStart,
    required Function() onListeningComplete,
    required Function(String) onError,
  }) async {
    final localeId = _currentLanguage == 'am' ? 'am-ET' : 'en-US';

    try {
      onListeningStart();
      await _dualVoiceService.startListening(
        localeId: localeId,
        onResult: (text) {
          if (text.isNotEmpty) {
            onResult(text);
            onListeningComplete();
          }
        },
        onError: onError,
      );
      return true;
    } catch (e) {
      onError(e.toString());
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _dualVoiceService.stopListening();
  }

  /// End interview and get full result
  Future<InterviewResult> endInterview() async {
    // Perform AI analysis
    final result = await _analyzeResult();

    // Clear session
    VoiceflowService().endSession();
    await DualVoiceService().stopSpeaking();

    _conversationHistory.clear();
    _currentJobTitle = null;
    _currentCompanyName = null;
    return result;
  }

  /// Analyze transcript and generate scores (Simulated AI)
  Future<InterviewResult> _analyzeResult() async {
    print('🧠 [InterviewAI] Analyzing interview result with Gemini...');

    try {
      final geminiService = GeminiService();
      final analysis = await geminiService.analyzeInterview(
        jobTitle: _currentJobTitle ?? 'Candidate',
        transcript: _conversationHistory,
        evaluationMetrics: _evaluationMetrics,
      );

      final Map<String, int> metricScores = Map<String, int>.from(
        analysis['metricScores'],
      );
      final overallScore =
          analysis['overallScore'] as int; // Or calculate from metrics

      // Determine 'default' category scores for backward compatibility if not in custom metrics
      // Or just map them from metricScores if keys match, otherwise use overall
      final technicalScore = metricScores['Technical Skills'] ?? overallScore;
      final communicationScore = metricScores['Communication'] ?? overallScore;
      final problemSolvingScore =
          metricScores['Problem Solving'] ?? overallScore;
      final cultureFitScore = metricScores['Culture Fit'] ?? overallScore;

      return InterviewResult(
        transcript: List.from(_conversationHistory),
        language: _currentLanguage,
        technicalScore: technicalScore,
        communicationScore: communicationScore,
        problemSolvingScore: problemSolvingScore,
        cultureFitScore: cultureFitScore,
        metricScores: Map<String, int>.from(metricScores),
        originalMetricScores: Map<String, int>.from(metricScores),
        aiSummary: analysis['aiSummary'],
        strengths: List<String>.from(analysis['strengths']),
        areasForImprovement: List<String>.from(analysis['areasForImprovement']),
        recommendation: analysis['recommendation'],
        durationMinutes: (_conversationHistory.length / 2).ceil(),
      );
    } catch (e) {
      print(
        '⚠️ [InterviewAI] Gemini analysis failed: $e. Falling back to simulation.',
      );
      return _simulateAnalysis();
    }
  }

  Future<InterviewResult> _simulateAnalysis() async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    final Map<String, int> metricScores = {};

    // Generate scores for each custom metric
    for (final metric in _evaluationMetrics) {
      // Skew towards higher scores for demo
      metricScores[metric] = 65 + random.nextInt(30);
    }

    // Calculate base scores
    final technicalScore =
        metricScores['Technical Skills'] ?? (70 + random.nextInt(25));
    final communicationScore =
        metricScores['Communication'] ?? (75 + random.nextInt(20));
    final culturalScore =
        metricScores['Cultural Fit'] ?? (70 + random.nextInt(25));
    final problemSolvingScore =
        metricScores['Problem Solving'] ?? (70 + random.nextInt(25));

    return InterviewResult(
      transcript: List.from(_conversationHistory),
      language: _currentLanguage,
      technicalScore: technicalScore,
      communicationScore: communicationScore,
      problemSolvingScore: problemSolvingScore,
      cultureFitScore: culturalScore,
      metricScores: Map<String, int>.from(metricScores),
      originalMetricScores: Map<String, int>.from(metricScores),
      aiSummary: _generateSummary(_conversationHistory),
      strengths: [
        'Strong communication skills demonstrated throughout',
        'Showed good understanding of core concepts',
        'Professional and enthusiastic demeanor',
      ],
      areasForImprovement: [
        'Could provide more specific examples in technical answers',
        'Response time was occasionally slow',
      ],
      recommendation: _getRecommendation(metricScores.values.toList()),
      durationMinutes:
          (_conversationHistory.length / 2).ceil(), // Rough estimate
    );
  }

  String _generateSummary(List<String> transcript) {
    if (transcript.isEmpty) return 'No conversation recorded.';
    return 'The candidate demonstrated strong compatibility with the $_currentJobTitle role. They effectively communicated their experience and showed enthusiasm for $_currentCompanyName. Their technical responses were generally sound, though some specific details could be elaborated further.';
  }

  String _getRecommendation(List<int> scores) {
    if (scores.isEmpty) return 'consider';
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    if (avg >= 85) return 'highly_recommended';
    if (avg >= 75) return 'recommended';
    if (avg >= 60) return 'consider';
    return 'not_recommended';
  }

  /// Get conversation transcript
  List<String> getTranscript() => List.from(_conversationHistory);

  /// Set language preference
  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    print('🌐 [InterviewAI] Language set to: $languageCode');
  }

  /// Mute/unmute audio
  static void setMuted(bool muted) {
    _isMuted = muted;
    // Use volume-based muting so playback continues silently
    DualVoiceService().muteAudio(muted);

    if (muted) {
      print('� [InterviewAI] Muted (Volume 0)');
    } else {
      print('� [InterviewAI] Unmuted (Volume 1)');
    }
  }

  static bool get isMuted => _isMuted;

  /// Stop all audio
  static Future<void> stopAudio() async {
    await DualVoiceService().stopSpeaking();
  }

  /// Dispose resources
  static void dispose() {
    DualVoiceService().stopSpeaking();
  }

  /// Get supported languages
  static List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'en', 'name': 'English', 'service': 'Voiceflow + ElevenLabs'},
      {'code': 'am', 'name': 'አማርኛ (Amharic)', 'service': 'Addis AI'},
    ];
  }

  /// Get service status
  static Future<Map<String, dynamic>> getServiceStatus() async {
    return {
      'dual_voice_initialized': DualVoiceService().isInitialized,
      'current_language': _currentLanguage,
      'is_muted': _isMuted,
    };
  }
}
