import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/top_notification.dart';
import '../../theme/app_theme.dart';
import '../../models/job_campaign.dart';
import '../../services/interview_ai_service.dart';
import '../../services/campaign_service.dart';

/// Create Campaign Screen - For companies to create new job campaigns
class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _departmentController = TextEditingController();
  final _locationController = TextEditingController();
  final _questionController = TextEditingController();

  String _selectedLanguage = 'en';
  String _selectedAgentType = 'Inbound qualification';

  final List<String> _agentTypes = [
    'Customer support',
    'Receptionist',
    'Lead generation',
    'Outbound sales',
    'Rental service',
    'Appointment booking',
    'Inbound qualification',
    'Product recommendation',
  ];

  List<String> _skills = [];
  List<String> _customQuestions = [];
  final List<String> _evaluationMetrics = [];
  final _skillController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _departmentController.dispose();
    _locationController.dispose();
    _questionController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text(
          'Create Campaign',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _isCreating ? null : _createCampaign,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child:
                  _isCreating
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Create',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Job Title
              _buildSection(
                'Job Title',
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'e.g., Senior Flutter Developer',
                    prefixIcon: Icon(Icons.work, color: AppTheme.textMuted),
                  ),
                  validator:
                      (value) => value?.isEmpty == true ? 'Required' : null,
                ),
              ),

              const SizedBox(height: 24),

              // Description
              _buildSection(
                'Job Description',
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe the role and responsibilities...',
                  ),
                  validator:
                      (value) => value?.isEmpty == true ? 'Required' : null,
                ),
              ),

              const SizedBox(height: 24),

              // Department & Location
              Row(
                children: [
                  Expanded(
                    child: _buildSection(
                      'Department',
                      TextFormField(
                        controller: _departmentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'e.g., Engineering',
                          prefixIcon: Icon(
                            Icons.business,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSection(
                      'Location',
                      TextFormField(
                        controller: _locationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'e.g., Addis Ababa',
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Interview Language
              _buildSection(
                'Interview Language',
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      isExpanded: true,
                      dropdownColor: AppTheme.cardDark,
                      style: const TextStyle(color: Colors.white),
                      items:
                          InterviewAIService.getSupportedLanguages().map((
                            lang,
                          ) {
                            return DropdownMenuItem(
                              value: lang['code'],
                              child: Row(
                                children: [
                                  Icon(
                                    lang['code'] == 'am'
                                        ? Icons.translate
                                        : Icons.language,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(lang['name']!),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged:
                          (value) => setState(() => _selectedLanguage = value!),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Agent Persona
              _buildSection(
                'AI Agent Persona',
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAgentType,
                      isExpanded: true,
                      dropdownColor: AppTheme.cardDark,
                      style: const TextStyle(color: Colors.white),
                      items:
                          _agentTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    color: AppTheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(type),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged:
                          (value) =>
                              setState(() => _selectedAgentType = value!),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Required Skills
              _buildSection(
                'Required Skills',
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _skillController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Add a skill...',
                              prefixIcon: Icon(
                                Icons.code,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            onFieldSubmitted: (_) => _addSkill(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          onPressed: _addSkill,
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (_skills.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            _skills
                                .map(
                                  (skill) => Chip(
                                    label: Text(skill),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 16,
                                    ),
                                    onDeleted:
                                        () => setState(
                                          () => _skills.remove(skill),
                                        ),
                                    backgroundColor: AppTheme.surfaceDark,
                                    labelStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                    deleteIconColor: AppTheme.textMuted,
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Custom Interview Questions
              _buildSection(
                'Custom Interview Questions (Optional)',
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _questionController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Add a custom question...',
                              prefixIcon: Icon(
                                Icons.help_outline,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            onFieldSubmitted: (_) => _addQuestion(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (_customQuestions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._customQuestions.asMap().entries.map(
                        (entry) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.textMuted,
                                  size: 20,
                                ),
                                onPressed:
                                    () => setState(
                                      () =>
                                          _customQuestions.removeAt(entry.key),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Evaluation Metrics
              _buildSection(
                'Evaluation Metrics (AI Evaluation)',
                Column(
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                            'Technical Proficiency',
                            'Communication Skills',
                            'Cultural Fit',
                            'Problem Solving',
                            'Language Fluency',
                          ].map((metric) {
                            final isSelected = _evaluationMetrics.contains(
                              metric,
                            );
                            return FilterChip(
                              label: Text(metric),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _evaluationMetrics.add(metric);
                                  } else {
                                    _evaluationMetrics.remove(metric);
                                  }
                                });
                              },
                              backgroundColor: AppTheme.surfaceDark,
                              selectedColor: AppTheme.primary.withOpacity(0.3),
                              checkmarkColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                color:
                                    isSelected
                                        ? AppTheme.primary
                                        : AppTheme.textMuted,
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How it works',
                            style: TextStyle(
                              color: AppTheme.info,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A unique join code will be generated. Share it with candidates to start AI interviews in ${_selectedLanguage == 'am' ? 'Amharic' : 'English'}.',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.labelLarge),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _addQuestion() {
    final question = _questionController.text.trim();
    if (question.isNotEmpty) {
      setState(() {
        _customQuestions.add(question);
        _questionController.clear();
      });
    }
  }

  Future<void> _createCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    if (_evaluationMetrics.isEmpty) {
      // Add defaults if empty
      _evaluationMetrics.addAll([
        'Technical Proficiency',
        'Communication Skills',
      ]);
    }

    setState(() => _isCreating = true);

    try {
      final campaign = JobCampaign(
        title: _titleController.text.trim(),
        companyName: 'TechCorp Africa', // Would come from auth
        description: _descriptionController.text.trim(),
        department: _departmentController.text.trim(),
        location: _locationController.text.trim(),
        requiredSkills: _skills,
        customQuestions: _customQuestions,
        evaluationMetrics: _evaluationMetrics,
        language: _selectedLanguage,
        agentType: _selectedAgentType,
      );

      // Save using CampaignService
      await CampaignService.createCampaign(campaign);

      if (mounted) {
        // Show success dialog with join code
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                backgroundColor: AppTheme.cardDark,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Campaign Created!',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Share this code with candidates to join the interview:',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            campaign.joinCode,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(
                              Icons.copy,
                              color: AppTheme.primary,
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: campaign.joinCode),
                              );
                              TopNotification.show(
                                context,
                                message: 'Code copied to clipboard!',
                                icon: Icons.content_copy,
                                color: AppTheme.success,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(
                        context,
                        campaign,
                      ); // Return to dashboard with campaign
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        TopNotification.show(
          context,
          message: "Error creating campaign: $e",
          icon: Icons.error_outline,
          color: AppTheme.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }
}
