import 'package:uuid/uuid.dart';

/// Job Campaign - Created by companies for recruiting
class JobCampaign {
  final String id;
  final String title;
  final String companyName;
  final String description;
  final String department;
  final String location;
  final List<String> requiredSkills;
  final List<String> customQuestions;
  final List<String> evaluationMetrics;
  final String joinCode;
  final String agentType;
  final String language;
  final int candidatesInterviewed;
  final DateTime createdAt;
  final String status;

  JobCampaign({
    String? id,
    required this.title,
    required this.companyName,
    required this.description,
    required this.department,
    required this.location,
    required this.requiredSkills,
    List<String>? customQuestions,
    List<String>? evaluationMetrics,
    String? joinCode,
    this.language = 'en',
    this.agentType = 'Inbound qualification',
    this.candidatesInterviewed = 0,
    DateTime? createdAt,
    this.status = 'active',
  }) : id = id ?? const Uuid().v4(),
       customQuestions = customQuestions ?? [],
       evaluationMetrics =
           evaluationMetrics ??
           ['Technical Skills', 'Communication', 'Cultural Fit'],
       joinCode = joinCode ?? _generateJoinCode(),
       createdAt = createdAt ?? DateTime.now();

  static String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code =
        List.generate(
          6,
          (i) =>
              chars[(DateTime.now().millisecondsSinceEpoch + i * 7) %
                  chars.length],
        ).join();
    return code;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'companyName': companyName,
    'description': description,
    'department': department,
    'location': location,
    'requiredSkills': requiredSkills,
    'customQuestions': customQuestions,
    'evaluationMetrics': evaluationMetrics,
    'joinCode': joinCode,
    'language': language,
    'agentType': agentType,
    'candidatesInterviewed': candidatesInterviewed,
    'createdAt': createdAt.toIso8601String(),
    'status': status,
  };

  factory JobCampaign.fromJson(Map<String, dynamic> json) => JobCampaign(
    id: json['id'],
    title: json['title'],
    companyName: json['companyName'],
    description: json['description'],
    department: json['department'],
    location: json['location'],
    requiredSkills: List<String>.from(json['requiredSkills']),
    customQuestions: List<String>.from(json['customQuestions'] ?? []),
    evaluationMetrics: List<String>.from(json['evaluationMetrics'] ?? []),
    joinCode: json['joinCode'],
    language: json['language'] ?? 'en',
    agentType: json['agentType'] ?? 'Inbound qualification',
    candidatesInterviewed: json['candidatesInterviewed'] ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    status: json['status'] ?? 'active',
  );

  JobCampaign copyWith({
    String? title,
    String? description,
    String? status,
    int? candidatesInterviewed,
  }) => JobCampaign(
    id: id,
    title: title ?? this.title,
    companyName: companyName,
    description: description ?? this.description,
    department: department,
    location: location,
    requiredSkills: requiredSkills,
    customQuestions: customQuestions,
    joinCode: joinCode,
    language: language,
    agentType: agentType,
    candidatesInterviewed: candidatesInterviewed ?? this.candidatesInterviewed,
    createdAt: createdAt,
    status: status ?? this.status,
  );

  /// Mock data for demo
  static List<JobCampaign> getMockCampaigns() => [
    JobCampaign(
      id: 'campaign_bilingual_ops',
      title: 'Bilingual Operations Head',
      companyName: 'TechCorp Africa',
      description:
          'Searching for a strategic leader to bridge our tech operations between English and Amharic speaking regions. Requires deep technical oversight and cultural leadership.',
      department: 'Operations',
      location: 'Addis Ababa / Nairobi',
      requiredSkills: [
        'Operational Strategy',
        'Cross-cultural Leadership',
        'Systems Optimization',
      ],
      customQuestions: [
        'How do you manage operational friction in a bilingual environment?',
        'Describe a time you used data to improve efficiency across teams.',
      ],
      language: 'both',
      agentType: 'Inbound qualification',
      candidatesInterviewed: 24,
    ),
    JobCampaign(
      id: 'campaign_ai_ethics',
      title: 'AI Ethics Specialist',
      companyName: 'HireAI Labs',
      description:
          'Focus on auditing AI decision-making models for fairness, bias reduction, and transparency in recruitment.',
      department: 'Compliance',
      location: 'Remote (Africa)',
      requiredSkills: ['AI Governance', 'Data Ethics', 'Regulatory Compliance'],
      language: 'en',
      agentType: 'Executive screening',
      candidatesInterviewed: 5,
    ),
    JobCampaign(
      id: 'campaign_success_am',
      title: 'Customer Success (Amharic Focus)',
      companyName: 'EthioFintech',
      description:
          'Engage natively with our growing customer base in Ethiopia. Technical support and relationship management in Amharic.',
      department: 'Customer Growth',
      location: 'Addis Ababa',
      requiredSkills: ['Technical Support', 'Client Retention', 'Amharic'],
      language: 'am',
      agentType: 'Inbound qualification',
      candidatesInterviewed: 18,
    ),
  ];
}
