import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/candidate.dart';
import '../../services/candidate_service.dart';
import '../../widgets/top_notification.dart';

/// Candidate Detail Screen - View full interview report
class CandidateDetailScreen extends StatefulWidget {
  final Candidate candidate;

  const CandidateDetailScreen({super.key, required this.candidate});

  @override
  State<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen> {
  late Candidate _candidate;
  bool _isEditing = false;

  // Edited values
  final Map<String, int> _editedScores = {};
  String? _recommendation;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _adjustmentReasonController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _candidate = widget.candidate;
    _initializeEditValues();
  }

  void _initializeEditValues() {
    if (_candidate.interviewResult != null) {
      final result = _candidate.interviewResult!;

      // Initialize edited scores locally
      if (result.metricScores.isNotEmpty) {
        _editedScores.addAll(result.metricScores);
      } else {
        _editedScores['Technical Skills'] = result.technicalScore;
        _editedScores['Communication'] = result.communicationScore;
        _editedScores['Problem Solving'] = result.problemSolvingScore;
        _editedScores['Culture Fit'] = result.cultureFitScore;
      }

      _recommendation = result.recommendation;
      _notesController.text = result.reviewerNotes ?? '';
      _adjustmentReasonController.text = result.scoreAdjustmentReason ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _adjustmentReasonController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_candidate.interviewResult == null) return;

    final result = _candidate.interviewResult!;
    bool scoresChanged = false;

    // Use existing original scores or establish them now if missing
    // Defensive check: handle mapping failures or hot reload artifacts
    Map<String, int> baseOriginalScores;
    try {
      baseOriginalScores =
          result.originalMetricScores.isNotEmpty
              ? Map<String, int>.from(result.originalMetricScores)
              : Map<String, int>.from(_editedScores);
    } catch (e) {
      print('⚠️ Auditing Initialization Error: $e');
      baseOriginalScores = Map<String, int>.from(_editedScores);
    }

    // Detect if any score has changed from original
    for (var entry in _editedScores.entries) {
      if (baseOriginalScores.containsKey(entry.key)) {
        if (baseOriginalScores[entry.key] != entry.value) {
          scoresChanged = true;
          break;
        }
      }
    }

    // Validation: If scores changed, reason is required
    if (scoresChanged && _adjustmentReasonController.text.trim().isEmpty) {
      TopNotification.show(
        context,
        message: 'Please provide a reason for score adjustments',
        icon: Icons.warning_amber_rounded,
        color: AppTheme.warning,
      );
      return;
    }

    final updatedResult = result.copyWith(
      metricScores: Map<String, int>.from(_editedScores),
      originalMetricScores: baseOriginalScores,
      technicalScore:
          _editedScores['Technical Skills'] ?? result.technicalScore,
      communicationScore:
          _editedScores['Communication'] ?? result.communicationScore,
      problemSolvingScore:
          _editedScores['Problem Solving'] ?? result.problemSolvingScore,
      cultureFitScore: _editedScores['Culture Fit'] ?? result.cultureFitScore,
      reviewerNotes: _notesController.text,
      scoreAdjustmentReason:
          scoresChanged ? _adjustmentReasonController.text : null,
      recommendation: _recommendation ?? result.recommendation,
    );

    setState(() {
      _candidate = _candidate.copyWith(
        interviewResult: updatedResult,
        status: 'reviewed',
      );
      _isEditing = false;
    });

    CandidateService.saveCandidate(_candidate);

    TopNotification.show(
      context,
      message:
          scoresChanged
              ? 'Changes audited and saved successfully'
              : 'Review saved successfully',
      icon: Icons.fact_check,
      color: AppTheme.success,
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    String? confirmMessage;
    Color confirmColor = AppTheme.primary;
    String actionLabel = 'Update';

    if (newStatus == 'hired') {
      confirmMessage =
          'Are you sure? This will trigger an automatic offer email to send to ${_candidate.email}.';
      confirmColor = AppTheme.success;
      actionLabel = 'Hire Candidate';
    } else if (newStatus == 'rejected') {
      confirmMessage =
          'Are you sure? This will send a polite rejection email to ${_candidate.email}.';
      confirmColor = AppTheme.error;
      actionLabel = 'Reject Candidate';
    }

    // Show confirmation if needed
    if (confirmMessage != null) {
      final confirmed = await _showConfirmDialog(
        title: '${actionLabel.split(" ")[0]} Candidate?',
        content: confirmMessage,
        confirmColor: confirmColor,
        confirmText: actionLabel,
      );
      if (confirmed != true) return;
    }

    final updatedCandidate = _candidate.copyWith(status: newStatus);
    await CandidateService.saveCandidate(updatedCandidate);

    setState(() {
      _candidate = updatedCandidate;
    });

    if (mounted) {
      String message = 'Candidate marked as $newStatus';
      if (newStatus == 'hired' || newStatus == 'rejected') {
        message = 'Status updated. Notification sent to ${_candidate.email}';
      }

      final color =
          newStatus == 'hired'
              ? AppTheme.success
              : (newStatus == 'rejected' ? AppTheme.error : AppTheme.primary);

      TopNotification.show(
        context,
        message: message,
        icon: Icons.check_circle,
        color: color,
      );
      Navigator.pop(context, true); // Go back to dashboard with refresh signal
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required Color confirmColor,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.surfaceDark, width: 1),
            ),
            title: Row(
              children: [
                Icon(Icons.info_outline, color: confirmColor),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            content: Text(
              content,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(confirmText),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteCandidate() async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete Candidate?',
      content:
          'This action cannot be undone and will remove all interview data.',
      confirmColor: AppTheme.error,
      confirmText: 'Delete',
    );

    if (confirmed == true) {
      await CandidateService.deleteCandidate(_candidate.id);
      if (mounted) {
        TopNotification.show(
          context,
          message: 'Candidate record deleted',
          icon: Icons.delete_outline,
          color: AppTheme.info,
        );
        Navigator.pop(context, true); // Return true to refresh list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _candidate.interviewResult;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text(
          'Interview Report',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primary),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Scores',
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: AppTheme.success),
              onPressed: _saveChanges,
              tooltip: 'Save Changes',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
            onPressed: _deleteCandidate,
            tooltip: 'Delete Candidate',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Verification Banner
                if (_candidate.status == 'reviewed')
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.success.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.verified, color: AppTheme.success, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Verified by Recruiter',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.cardDecoration,
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.primary.withOpacity(0.2),
                        child: Text(
                          _candidate.name[0],
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_candidate.name, style: AppTheme.heading2),
                            const SizedBox(height: 4),
                            Text(
                              _candidate.jobTitle,
                              style: AppTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                _buildInfoChip(Icons.email, _candidate.email),
                                if (_candidate.phone.isNotEmpty)
                                  _buildInfoChip(Icons.phone, _candidate.phone),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Score Badge
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getScoreColor(
                            _candidate.matchScore,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getScoreColor(_candidate.matchScore),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${_candidate.matchScore}%',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(_candidate.matchScore),
                              ),
                            ),
                            const Text(
                              'Match Score',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (result != null) ...[
                  const SizedBox(height: 24),

                  // Scores Breakdown
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Interview Scores',
                              style: AppTheme.heading3,
                            ),
                            if (_isEditing)
                              const Text(
                                'Adjust sliders to update',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ..._editedScores.keys.map(
                          (key) => _buildScoreBar(key, _editedScores[key] ?? 0),
                        ),

                        // Adjustment Reason Field (Edit Mode)
                        if (_isEditing) ...[
                          const SizedBox(height: 16),
                          const Divider(color: AppTheme.surfaceDark),
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Icon(
                                Icons.history_edu,
                                size: 16,
                                color: AppTheme.info,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Adjustment Reason',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.info,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _adjustmentReasonController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText:
                                  'Why are you adjusting the AI baseline?',
                              hintStyle: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: AppTheme.surfaceDark,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '* Required for any score changes to ensure auditing.',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],

                        // Audit Trail Note (View Mode)
                        if (!_isEditing &&
                            result.scoreAdjustmentReason != null &&
                            result.scoreAdjustmentReason!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(color: AppTheme.surfaceDark),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.info.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.info.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.history_edu,
                                      size: 14,
                                      color: AppTheme.info,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Score Audit Trail',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.info,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  result.scoreAdjustmentReason!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Modified by Recruiter',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recruiter Notes & AI Summary
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.info.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recruiter Notes
                        if (_isEditing ||
                            (_notesController.text.isNotEmpty)) ...[
                          const Text(
                            'Recruiter Notes',
                            style: AppTheme.heading3,
                          ),
                          const SizedBox(height: 12),
                          if (_isEditing)
                            TextField(
                              controller: _notesController,
                              style: const TextStyle(color: Colors.white),
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Add your observations...',
                                hintStyle: TextStyle(color: AppTheme.textMuted),
                                filled: true,
                                fillColor: AppTheme.surfaceDark,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _notesController.text,
                                style: AppTheme.bodyMedium,
                              ),
                            ),
                          const SizedBox(height: 24),
                          const Divider(color: AppTheme.surfaceDark),
                          const SizedBox(height: 24),
                        ],

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.info.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: AppTheme.info,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('AI Analysis', style: AppTheme.heading3),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(result.aiSummary, style: AppTheme.bodyLarge),
                        const SizedBox(height: 20),

                        // Recommendation Badge (Editable)
                        if (_isEditing)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _recommendation,
                              dropdownColor: AppTheme.cardDark,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                              items:
                                  [
                                    'highly_recommended',
                                    'recommended',
                                    'consider',
                                    'not_recommended',
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        _getRecommendationText(value),
                                        style: TextStyle(
                                          color: _getRecommendationColor(value),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (newValue) {
                                setState(() => _recommendation = newValue);
                              },
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getRecommendationColor(
                                result.recommendation,
                              ).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getRecommendationColor(
                                  result.recommendation,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getRecommendationIcon(result.recommendation),
                                  color: _getRecommendationColor(
                                    result.recommendation,
                                  ),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getRecommendationText(result.recommendation),
                                  style: TextStyle(
                                    color: _getRecommendationColor(
                                      result.recommendation,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Strengths & Areas for Improvement
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 600;
                      if (isNarrow) {
                        return Column(
                          children: [
                            _buildListCard(
                              'Strengths',
                              result.strengths,
                              AppTheme.success,
                              Icons.thumb_up,
                            ),
                            const SizedBox(height: 16),
                            _buildListCard(
                              'Areas for Improvement',
                              result.areasForImprovement,
                              AppTheme.warning,
                              Icons.trending_up,
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildListCard(
                              'Strengths',
                              result.strengths,
                              AppTheme.success,
                              Icons.thumb_up,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildListCard(
                              'Areas for Improvement',
                              result.areasForImprovement,
                              AppTheme.warning,
                              Icons.trending_up,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Interview Details
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Interview Details',
                          style: AppTheme.heading3,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 24,
                          runSpacing: 16,
                          children: [
                            _buildDetailItem(
                              Icons.language,
                              'Language',
                              result.language == 'am' ? 'Amharic' : 'English',
                            ),
                            _buildDetailItem(
                              Icons.timer,
                              'Duration',
                              '${result.durationMinutes} min',
                            ),
                            _buildDetailItem(
                              Icons.calendar_today,
                              'Date',
                              _formatDate(result.completedAt),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Transcript
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Interview Transcript',
                              style: AppTheme.heading3,
                            ),
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('Export'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...result.transcript.map((line) {
                          final isAI = line.startsWith('NEXA:');
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isAI
                                      ? AppTheme.primary.withOpacity(0.1)
                                      : AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isAI ? Icons.psychology : Icons.person,
                                  color:
                                      isAI
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: TextStyle(
                                      color:
                                          isAI
                                              ? AppTheme.primary
                                              : Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Action Buttons (Only visible if not editing)
                if (!_isEditing &&
                    _candidate.status != 'rejected' &&
                    _candidate.status != 'hired')
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width:
                            isMobile
                                ? double.infinity
                                : (constraints.maxWidth - 50) / 3,
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus('rejected'),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      if (_candidate.status != 'shortlisted')
                        SizedBox(
                          width:
                              isMobile
                                  ? double.infinity
                                  : (constraints.maxWidth - 50) / 3,
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStatus('shortlisted'),
                            icon: const Icon(Icons.star, color: Colors.white),
                            label: const Text(
                              'Shortlist',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.warning,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      SizedBox(
                        width:
                            isMobile
                                ? double.infinity
                                : (constraints.maxWidth - 50) / 3,
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus('hired'),
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Hire',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBar(String label, int score) {
    final originalResult = _candidate.interviewResult;
    // Defensive access: ensure we never crash even during hot reloads
    final Map<String, int> originalScores =
        originalResult?.originalMetricScores ?? {};
    final int? originalScore = originalScores[label];
    final bool hasChanged = originalScore != null && originalScore != score;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasChanged && !_isEditing)
                      Text(
                        'AI Baseline: $originalScore%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  if (hasChanged && !_isEditing)
                    const Icon(
                      Icons.history_edu,
                      size: 14,
                      color: AppTheme.info,
                    ),
                  if (hasChanged && !_isEditing) const SizedBox(width: 4),
                  Text(
                    '$score%',
                    style: TextStyle(
                      color: _getScoreColor(score),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_isEditing)
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _getScoreColor(score),
                thumbColor: Colors.white,
                overlayColor: _getScoreColor(score).withOpacity(0.2),
              ),
              child: Slider(
                value: score.toDouble(),
                min: 0,
                max: 100,
                divisions: 100,
                label: score.toString(),
                onChanged: (value) {
                  setState(() {
                    _editedScores[label] = value.round();
                  });
                },
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 100,
                backgroundColor: AppTheme.surfaceDark,
                valueColor: AlwaysStoppedAnimation(_getScoreColor(score)),
                minHeight: 8,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListCard(
    String title,
    List<String> items,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.heading3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item, style: AppTheme.bodyMedium)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return AppTheme.success;
    if (score >= 70) return AppTheme.warning;
    return AppTheme.error;
  }

  Color _getRecommendationColor(String rec) {
    switch (rec) {
      case 'highly_recommended':
        return AppTheme.success;
      case 'recommended':
        return AppTheme.info;
      case 'consider':
        return AppTheme.warning;
      default:
        return AppTheme.error;
    }
  }

  IconData _getRecommendationIcon(String rec) {
    switch (rec) {
      case 'highly_recommended':
        return Icons.verified;
      case 'recommended':
        return Icons.thumb_up;
      case 'consider':
        return Icons.help_outline;
      default:
        return Icons.cancel;
    }
  }

  String _getRecommendationText(String rec) {
    switch (rec) {
      case 'highly_recommended':
        return 'HIGHLY RECOMMENDED';
      case 'recommended':
        return 'RECOMMENDED';
      case 'consider':
        return 'CONSIDER';
      default:
        return 'NOT RECOMMENDED';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
