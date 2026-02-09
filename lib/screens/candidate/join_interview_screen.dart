import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/campaign_service.dart';
import '../../widgets/top_notification.dart';
import 'interview_screen.dart';

/// Join Interview Screen - Candidate entry point
class JoinInterviewScreen extends StatefulWidget {
  const JoinInterviewScreen({super.key});

  @override
  State<JoinInterviewScreen> createState() => _JoinInterviewScreenState();
}

class _JoinInterviewScreenState extends State<JoinInterviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('Join Interview', style: AppTheme.heading1),
              const SizedBox(height: 8),
              const Text(
                'Enter the campaign code to start your\nAI-powered interview',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.cardDecoration,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _codeController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'CODE',
                          hintStyle: TextStyle(
                            color: AppTheme.textMuted.withOpacity(0.3),
                            letterSpacing: 4,
                          ),
                          fillColor: AppTheme.backgroundDark,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                          ),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator:
                            (value) =>
                                value?.length != 6
                                    ? 'Enter 6-digit code'
                                    : null,
                      ),
                      const SizedBox(height: 24),
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
                            (value) =>
                                value?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
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
                            (value) =>
                                value?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
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
                            (value) =>
                                value?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isJoining ? null : _joinInterview,
                          child:
                              _isJoining
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text('Start Interview'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Tips
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    size: 16,
                    color: AppTheme.warning,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tip: Find a quiet place for best audio quality',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _joinInterview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isJoining = true);

    try {
      // Fetch campaign details
      final campaign = await CampaignService.getCampaignByCode(
        _codeController.text,
      );

      if (mounted) {
        setState(() => _isJoining = false);

        if (campaign != null) {
          // Navigate to interview with campaign data
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => InterviewScreen(
                    candidateName: _nameController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                    campaign: campaign,
                  ),
            ),
          );
        } else {
          TopNotification.show(
            context,
            message: 'Invalid campaign code',
            icon: Icons.error_outline,
            color: AppTheme.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isJoining = false);
        TopNotification.show(
          context,
          message: 'Error: $e',
          icon: Icons.error_outline,
          color: AppTheme.error,
        );
      }
    }
  }
}
