import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  GenerativeModel _createModel(String modelName) {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env');
    }
    return GenerativeModel(model: modelName, apiKey: apiKey);
  }

  /// Analyze the interview transcript and return structured scores and feedback
  Future<Map<String, dynamic>> analyzeInterview({
    required String jobTitle,
    required List<String> transcript,
    required List<String> evaluationMetrics,
  }) async {
    final models = [
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-pro',
    ];

    if (transcript.isEmpty) {
      throw Exception('Transcript is empty');
    }

    final prompt = _buildAnalysisPrompt(
      jobTitle,
      transcript,
      evaluationMetrics,
    );

    final content = [Content.text(prompt)];

    for (final modelName in models) {
      try {
        print('🧠 [GeminiService] Trying model: $modelName');
        final model = _createModel(modelName);

        final response = await model.generateContent(content);

        if (response.text == null) {
          throw Exception('Empty response from Gemini');
        }

        print('🧠 [GeminiService] Success with $modelName');
        final cleanedJson = _cleanJson(response.text!);
        return jsonDecode(cleanedJson);
      } catch (e) {
        print('⚠️ [GeminiService] Failed with $modelName: $e');
        if (modelName == models.last) rethrow; // Rethrow if all fail
      }
    }

    throw Exception('All Gemini models failed');
  }

  String _buildAnalysisPrompt(
    String jobTitle,
    List<String> transcript,
    List<String> metrics,
  ) {
    return '''
    You are an expert HR Recruiter and Technical Interviewer. 
    Analyze the following interview transcript for the role of "$jobTitle".
    
    Evalute the candidate based on these specific metrics:
    ${metrics.map((m) => "- $m").join('\n')}

    TRANSCRIPT:
    ${transcript.join('\n')}
    
    OUTPUT FORMAT (JSON ONLY):
    {
      "metricScores": {
        "${metrics[0]}": 0-100,
        ... (for all metrics)
      },
      "overallScore": 0-100 (weighted average),
      "aiSummary": "2-3 sentences summarizing the candidate's performance",
      "strengths": ["point 1", "point 2", "point 3"],
      "areasForImprovement": ["point 1", "point 2"],
      "recommendation": "highly_recommended" | "recommended" | "consider" | "not_recommended"
    }

    Scoring Guidelines:
    - 90-100: Exceptional (Expert level)
    - 75-89: Strong (Above average, minor gaps)
    - 60-74: Satisfactory (Meets basic requirements)
    - 0-59: Unsatisfactory (Significant gaps or "I don't know" answers)
    
    CRITICAL: If the candidate answers "I don't know" or similar to key questions, the score for that metric MUST be low (<50). Be strict and realistic.
    ''';
  }

  String _cleanJson(String text) {
    text = text.replaceAll('```json', '').replaceAll('```', '');
    final startIndex = text.indexOf('{');
    final endIndex = text.lastIndexOf('}');

    if (startIndex != -1 && endIndex != -1) {
      return text.substring(startIndex, endIndex + 1);
    }

    return text.trim();
  }
}
