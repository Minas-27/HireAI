import 'package:uuid/uuid.dart';

/// Candidate - Represents a job candidate and their interview results
class Candidate {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String campaignId;
  final String jobTitle;
  final InterviewResult? interviewResult;
  final DateTime appliedAt;
  final String
  status; // 'pending', 'interviewed', 'pending_review', 'reviewed', 'shortlisted', 'hired', 'rejected'

  Candidate({
    String? id,
    required this.name,
    required this.email,
    this.phone = '',
    required this.campaignId,
    required this.jobTitle,
    this.interviewResult,
    DateTime? appliedAt,
    this.status = 'pending',
  }) : id = id ?? const Uuid().v4(),
       appliedAt = appliedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'campaignId': campaignId,
    'jobTitle': jobTitle,
    'interviewResult': interviewResult?.toJson(),
    'appliedAt': appliedAt.toIso8601String(),
    'status': status,
  };

  factory Candidate.fromJson(Map<String, dynamic> json) => Candidate(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    phone: json['phone'] ?? '',
    campaignId: json['campaignId'],
    jobTitle: json['jobTitle'],
    interviewResult:
        json['interviewResult'] != null
            ? InterviewResult.fromJson(json['interviewResult'])
            : null,
    appliedAt: DateTime.parse(json['appliedAt']),
    status: json['status'] ?? 'pending',
  );

  Candidate copyWith({InterviewResult? interviewResult, String? status}) =>
      Candidate(
        id: id,
        name: name,
        email: email,
        phone: phone,
        campaignId: campaignId,
        jobTitle: jobTitle,
        interviewResult: interviewResult ?? this.interviewResult,
        appliedAt: appliedAt,
        status: status ?? this.status,
      );

  /// Overall match score (0-100)
  int get matchScore => interviewResult?.overallScore ?? 0;
}

/// Interview Result - AI-generated assessment from the interview
class InterviewResult {
  final String? _id;
  final List<String>? _transcript;
  final String? _language;
  final int? _technicalScore;
  final int? _communicationScore;
  final int? _problemSolvingScore;
  final int? _cultureFitScore;
  final String? _aiSummary;
  final List<String>? _strengths;
  final List<String>? _areasForImprovement;
  final Map<String, int>? _metricScores; // Backing field for safety
  final Map<String, int>? _originalMetricScores; // Backing field for safety
  final String? scoreAdjustmentReason; // Why the recruiter changed it
  final String? reviewerNotes; // General manual notes from recruiter
  final String
  recommendation; // 'highly_recommended', 'recommended', 'consider', 'not_recommended'
  final DateTime completedAt;
  final int durationMinutes;

  /// Safe getters to prevent null safety crashes even during hot reloads
  String get id => _id ?? '';
  List<String> get transcript => _transcript ?? const [];
  String get language => _language ?? 'en';
  int get technicalScore => _technicalScore ?? 0;
  int get communicationScore => _communicationScore ?? 0;
  int get problemSolvingScore => _problemSolvingScore ?? 0;
  int get cultureFitScore => _cultureFitScore ?? 0;
  String get aiSummary => _aiSummary ?? '';
  List<String> get strengths => _strengths ?? const [];
  List<String> get areasForImprovement => _areasForImprovement ?? const [];
  Map<String, int> get metricScores => _metricScores ?? const {};
  Map<String, int> get originalMetricScores =>
      _originalMetricScores ?? const {};

  InterviewResult({
    String? id,
    required List<String> transcript,
    required String language,
    required int technicalScore,
    required int communicationScore,
    required int problemSolvingScore,
    required int cultureFitScore,
    Map<String, int>? metricScores,
    Map<String, int>? originalMetricScores,
    this.scoreAdjustmentReason,
    this.reviewerNotes,
    required String aiSummary,
    required List<String> strengths,
    required List<String> areasForImprovement,
    required this.recommendation,
    DateTime? completedAt,
    this.durationMinutes = 0,
  }) : _id = id ?? const Uuid().v4(),
       completedAt = completedAt ?? DateTime.now(),
       _transcript = transcript,
       _language = language,
       _technicalScore = technicalScore,
       _communicationScore = communicationScore,
       _problemSolvingScore = problemSolvingScore,
       _cultureFitScore = cultureFitScore,
       _metricScores = metricScores ?? const {},
       _originalMetricScores = originalMetricScores ?? const {},
       _aiSummary = aiSummary,
       _strengths = strengths,
       _areasForImprovement = areasForImprovement;

  /// Overall score (average of all scores)
  int get overallScore {
    if (metricScores.isNotEmpty) {
      // If we have custom metrics, use them
      final total = metricScores.values.fold(0, (sum, score) => sum + score);
      return (total / metricScores.length).round();
    }
    // Fallback to legacy scores
    return ((technicalScore +
                communicationScore +
                problemSolvingScore +
                cultureFitScore) /
            4)
        .round();
  }

  InterviewResult copyWith({
    String? id,
    List<String>? transcript,
    String? language,
    int? technicalScore,
    int? communicationScore,
    int? problemSolvingScore,
    int? cultureFitScore,
    Map<String, int>? metricScores,
    Map<String, int>? originalMetricScores,
    String? scoreAdjustmentReason,
    String? reviewerNotes,
    String? aiSummary,
    List<String>? strengths,
    List<String>? areasForImprovement,
    String? recommendation,
    DateTime? completedAt,
    int? durationMinutes,
  }) => InterviewResult(
    id: id ?? this.id,
    transcript: transcript ?? this.transcript,
    language: language ?? this.language,
    technicalScore: technicalScore ?? this.technicalScore,
    communicationScore: communicationScore ?? this.communicationScore,
    problemSolvingScore: problemSolvingScore ?? this.problemSolvingScore,
    cultureFitScore: cultureFitScore ?? this.cultureFitScore,
    metricScores: metricScores ?? this.metricScores,
    originalMetricScores: originalMetricScores ?? this.originalMetricScores,
    scoreAdjustmentReason: scoreAdjustmentReason ?? this.scoreAdjustmentReason,
    reviewerNotes: reviewerNotes ?? this.reviewerNotes,
    aiSummary: aiSummary ?? this.aiSummary,
    strengths: strengths ?? this.strengths,
    areasForImprovement: areasForImprovement ?? this.areasForImprovement,
    recommendation: recommendation ?? this.recommendation,
    completedAt: completedAt ?? this.completedAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'transcript': transcript,
    'language': language,
    'technicalScore': technicalScore,
    'communicationScore': communicationScore,
    'problemSolvingScore': problemSolvingScore,
    'cultureFitScore': cultureFitScore,
    'metricScores': metricScores,
    'originalMetricScores': originalMetricScores,
    'scoreAdjustmentReason': scoreAdjustmentReason,
    'reviewerNotes': reviewerNotes,
    'aiSummary': aiSummary,
    'strengths': strengths,
    'areasForImprovement': areasForImprovement,
    'recommendation': recommendation,
    'completedAt': completedAt.toIso8601String(),
    'durationMinutes': durationMinutes,
  };

  factory InterviewResult.fromJson(Map<String, dynamic> json) {
    // Defensive type handling for maps
    Map<String, int> safeMap(dynamic data) {
      if (data == null || data is! Map) return {};
      try {
        return Map<String, int>.from(
          data.map(
            (key, value) => MapEntry(
              key.toString(),
              value is int ? value : int.tryParse(value.toString()) ?? 0,
            ),
          ),
        );
      } catch (e) {
        return {};
      }
    }

    return InterviewResult(
      id: json['id'],
      transcript: List<String>.from(json['transcript'] ?? []),
      language: json['language'] ?? 'en',
      technicalScore: json['technicalScore'] ?? 0,
      communicationScore: json['communicationScore'] ?? 0,
      problemSolvingScore: json['problemSolvingScore'] ?? 0,
      cultureFitScore: json['cultureFitScore'] ?? 0,
      metricScores: safeMap(json['metricScores']),
      originalMetricScores: safeMap(json['originalMetricScores']),
      scoreAdjustmentReason: json['scoreAdjustmentReason'],
      reviewerNotes: json['reviewerNotes'],
      aiSummary: json['aiSummary'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      areasForImprovement: List<String>.from(json['areasForImprovement'] ?? []),
      recommendation: json['recommendation'] ?? 'consider',
      completedAt:
          DateTime.tryParse(json['completedAt'] ?? '') ?? DateTime.now(),
      durationMinutes: json['durationMinutes'] ?? 0,
    );
  }

  /// Mock interview results for demo
  static List<Candidate> getMockCandidatesWithResults() => [
    Candidate(
      id: 'cand_selamawit',
      name: 'Selamawit Tekle',
      email: 'selam.tekle@example.com',
      phone: '+251 91 122 3344',
      campaignId: 'campaign_bilingual_ops',
      jobTitle: 'Bilingual Operations Head',
      status: 'pending_review',
      interviewResult: InterviewResult(
        transcript: [
          'AI (አማርኛ): ሰላም ሰላምነቱ! ስለ ስራ ልምድዎ እና በቡድን ውስጥ ስላከናወኑት ስራ ሊነግሩኝ ይችላሉ?',
          'Candidate: ሰላም! ባለፉት አምስት ዓመታት በኦፕሬሽን ዘርፍ ሰርቻለሁ። በተለይ ደግሞ የቡድን ቅንጅትን በማሻሻል ረገድ ትልቅ ልምድ አለኝ።',
          'AI (አማርኛ): በጣም ጥሩ። በስራዎ ላይ ያጋጠመዎትን ትልቅ ፈተና እና እንዴት እንደፈቱት ቢገልጹልኝ?',
        ],
        language: 'am',
        technicalScore: 94,
        communicationScore: 91,
        problemSolvingScore: 89,
        cultureFitScore: 95,
        metricScores: {
          'Technical Skills': 94,
          'Communication': 91,
          'Problem Solving': 89,
          'Cultural Fit': 95,
        },
        aiSummary:
            'Exceptional bilingual candidate with deep operational insight. Demonstrated native-level fluency in Amharic while discussing complex management strategies. Highly proactive and culturally aligned with TechCorp origins.',
        strengths: [
          'Native Amharic fluency with professional terminology.',
          'Strategic approach to operational bottlenecks.',
          'Strong evidence of team-building across cultures.',
        ],
        areasForImprovement: [
          'Could provide more specific data points for her previous projects.',
        ],
        recommendation: 'highly_recommended',
        durationMinutes: 24,
      ),
    ),
    Candidate(
      id: 'cand_dawit',
      name: 'Dawit Abraham',
      email: 'd.abraham@outlook.com',
      phone: '+254 711 223 344',
      campaignId: 'campaign_bilingual_ops',
      jobTitle: 'Bilingual Operations Head',
      status: 'reviewed',
      interviewResult: InterviewResult(
        transcript: [
          'AI: Welcome Dawit. Tell me about your strategy for optimizing cross-border logistics.',
          'Candidate: I believe in decentralized hubs. By using regional data points, we can reduce latency by 15%.',
        ],
        language: 'en',
        technicalScore: 84,
        communicationScore: 82,
        problemSolvingScore: 94,
        cultureFitScore: 78,
        metricScores: {
          'Technical Skills': 84,
          'Communication': 82,
          'Problem Solving': 94,
          'Cultural Fit': 78,
        },
        originalMetricScores: {
          'Technical Skills': 75,
          'Communication': 82,
          'Problem Solving': 94,
          'Cultural Fit': 78,
        },
        scoreAdjustmentReason:
            'I upgraded the Technical Score after reviewing his portfolio on Hub-Logistics. His interview response was humble, but his actual work is world-class.',
        reviewerNotes:
            'Dawit is a genius in problem solving. His communication is brief, but very effective.',
        aiSummary:
            'A highly analytical candidate with a focus on optimization. While communication is efficient, his problem-solving capability is in the top 1% of monitored interviews.',
        strengths: [
          'Exceptional systematic thinking.',
          'Data-driven decision making.',
          'Deep understanding of logistics latency.',
        ],
        areasForImprovement: [
          'Communicates only the essentials; could be more descriptive in team settings.',
        ],
        recommendation: 'recommended',
        durationMinutes: 19,
      ),
    ),
  ];
}
