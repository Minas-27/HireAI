import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/job_campaign.dart';
import 'interview_screen.dart';

/// Campaign Detail Screen - View full campaign details and apply
class CampaignDetailScreen extends StatefulWidget {
  final JobCampaign campaign;

  const CampaignDetailScreen({super.key, required this.campaign});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedLanguage = 'en';
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.campaign.language == 'am' ? 'am' : 'en';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Job Details', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.business,
                          color: AppTheme.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(campaign.title, style: AppTheme.heading2),
                            const SizedBox(height: 4),
                            Text(
                              campaign.companyName,
                              style: AppTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildInfoBadge(Icons.location_on, campaign.location),
                      const SizedBox(width: 12),
                      _buildInfoBadge(
                        Icons.business_center,
                        campaign.department,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Description
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About This Role', style: AppTheme.heading3),
                  const SizedBox(height: 12),
                  Text(
                    campaign.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Required Skills
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Required Skills', style: AppTheme.heading3),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        campaign.requiredSkills.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Interview Info
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mic, color: AppTheme.info),
                      const SizedBox(width: 12),
                      const Text(
                        'AI-Powered Interview',
                        style: AppTheme.heading3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This position uses an AI interviewer. You\'ll have a voice conversation with NEXA, our AI assistant, who will ask you questions about your experience and skills.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInterviewFeature(Icons.timer, '15-20 min'),
                      const SizedBox(width: 24),
                      _buildInterviewFeature(
                        Icons.language,
                        campaign.language == 'am'
                            ? 'Amharic'
                            : campaign.language == 'both'
                            ? 'English / Amharic'
                            : 'English',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Apply Form
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.cardDecoration,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Apply Now', style: AppTheme.heading3),
                    const SizedBox(height: 20),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Full Name',
                        prefixIcon: Icon(
                          Icons.person,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      validator:
                          (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Email Address',
                        prefixIcon: Icon(
                          Icons.email,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator:
                          (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Phone Number',
                        prefixIcon: Icon(
                          Icons.phone,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator:
                          (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Language Selection (if both available)
                    if (campaign.language == 'both') ...[
                      const Text(
                        'Select Interview Language',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLanguageOption('English', 'en'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _buildLanguageOption('አማርኛ', 'am')),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isApplying ? null : _startInterview,
                        child:
                            _isApplying
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.mic, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Start AI Interview'),
                                  ],
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.info),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: AppTheme.info, fontSize: 13)),
      ],
    );
  }

  Widget _buildLanguageOption(String label, String value) {
    final isSelected = _selectedLanguage == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppTheme.primary.withOpacity(0.2)
                  : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startInterview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isApplying = true);

    // Simulate brief delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      // Create a modified campaign with the selected language
      final campaignWithLanguage = JobCampaign(
        id: widget.campaign.id,
        title: widget.campaign.title,
        companyName: widget.campaign.companyName,
        description: widget.campaign.description,
        department: widget.campaign.department,
        location: widget.campaign.location,
        requiredSkills: widget.campaign.requiredSkills,
        customQuestions: widget.campaign.customQuestions,
        evaluationMetrics: widget.campaign.evaluationMetrics,
        joinCode: widget.campaign.joinCode,
        language: _selectedLanguage,
        candidatesInterviewed: widget.campaign.candidatesInterviewed,
        status: widget.campaign.status,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => InterviewScreen(
                candidateName: _nameController.text,
                email: _emailController.text,
                phone: _phoneController.text,
                campaign: campaignWithLanguage,
              ),
        ),
      );
    }
  }
}
