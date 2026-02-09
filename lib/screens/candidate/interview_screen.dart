import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../theme/app_theme.dart';
import '../../services/interview_ai_service.dart';
import '../../models/job_campaign.dart';
import '../../models/candidate.dart';
import '../../services/candidate_service.dart';
import '../../services/campaign_service.dart';
import '../../widgets/top_notification.dart';
import 'interview_results_screen.dart';

/// Interview Screen - The core AI interview experience
class InterviewScreen extends StatefulWidget {
  final String candidateName;
  final String email;
  final String phone;
  final JobCampaign campaign;

  const InterviewScreen({
    super.key,
    required this.candidateName,
    required this.email,
    required this.phone,
    required this.campaign,
  });

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen>
    with TickerProviderStateMixin {
  final InterviewAIService _aiService = InterviewAIService();
  final ScrollController _scrollController = ScrollController();

  bool _isConnecting = true;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _isTextMode = false;

  // Interview Context
  late String _jobTitle;
  late String _companyName;
  late String _currentLanguage;

  // Conversation
  final List<MessageBubble> _messages = [];
  String _transcript = '';
  final TextEditingController _textController = TextEditingController();

  // Animation Controllers
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _jobTitle = widget.campaign.title;
    _companyName = widget.campaign.companyName;
    _currentLanguage = widget.campaign.language;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initializeInterview();
  }

  Future<void> _initializeInterview() async {
    await InterviewAIService.initialize();

    if (mounted) {
      setState(() => _isConnecting = false);
      _startInterview();
    }
  }

  Future<void> _startInterview() async {
    setState(() => _isProcessing = true);

    final result = await _aiService.startInterview(
      jobTitle: _jobTitle,
      companyName: _companyName,
      candidateName: widget.candidateName,
      language: _currentLanguage,
      agentType: widget.campaign.agentType,
      customQuestions: widget.campaign.customQuestions,
      evaluationMetrics: widget.campaign.evaluationMetrics,
    );

    if (result['success']) {
      _addMessage(result['greeting'], isAI: true);
      setState(() {
        _isProcessing = false;
        _isSpeaking = true;
      });
      // Simulate speaking finish after delay if no event listener available
      // In real implementation, use onComplete listener from services
      Future.delayed(
        Duration(seconds: (result['greeting'].length / 10).round()),
        () {
          if (mounted) setState(() => _isSpeaking = false);
        },
      );
    }
  }

  void _addMessage(String text, {required bool isAI}) {
    setState(() {
      _messages.add(
        MessageBubble(text: text, isAI: isAI, timestamp: DateTime.now()),
      );
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startListening() async {
    // Haptic feedback
    // HapticFeedback.mediumImpact();

    setState(() {
      _isListening = true;
      _transcript = '';
    });

    await _aiService.startListening(
      onListeningStart: () {},
      onResult: (text) {
        setState(() => _transcript = text);
      },
      onListeningComplete: () {
        _stopListeningAndSend();
      },
      onError: (error) {
        setState(() => _isListening = false);
        TopNotification.show(
          context,
          message: 'Error: $error',
          icon: Icons.error_outline,
          color: AppTheme.error,
        );
      },
    );
  }

  Future<void> _stopListeningAndSend() async {
    await _aiService.stopListening();

    if (_transcript.isNotEmpty) {
      setState(() {
        _isListening = false;
        _isProcessing = true;
      });

      _addMessage(_transcript, isAI: false);

      // Get AI Response
      final result = await _aiService.sendCandidateResponse(_transcript);

      if (result['success']) {
        _addMessage(result['text'], isAI: true);
        setState(() {
          _isProcessing = false;
          _isSpeaking = true;
        });

        // Reset speaking state estimation
        Future.delayed(
          Duration(seconds: (result['text'].length / 10).round()),
          () {
            if (mounted) setState(() => _isSpeaking = false);
          },
        );
      }
    } else {
      setState(() => _isListening = false);
    }
  }

  @override
  void dispose() {
    InterviewAIService.stopAudio();
    InterviewAIService.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  /// Send text message from text input
  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() => _isProcessing = true);

    _addMessage(text, isAI: false);

    final result = await _aiService.sendCandidateResponse(text);

    if (result['success']) {
      _addMessage(result['text'], isAI: true);
      setState(() {
        _isProcessing = false;
        _isSpeaking = true;
      });

      Future.delayed(
        Duration(seconds: (result['text'].length / 10).round()),
        () {
          if (mounted) setState(() => _isSpeaking = false);
        },
      );
    } else {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SpinKitRipple(color: AppTheme.primary, size: 80),
              const SizedBox(height: 24),
              Text(
                'Connecting to NEXA AI...',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.error),
          onPressed: () => _showExitDialog(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Interview',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              '$_jobTitle • $_companyName',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _currentLanguage == 'am' ? Icons.translate : Icons.language,
                  size: 14,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _currentLanguage == 'am' ? 'አማርኛ' : 'English',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Robust check: If height is small (< 500) OR keyboard inset detected
          final isSmallHeight = constraints.maxHeight < 500;
          final isKeyboardOpen =
              MediaQuery.of(context).viewInsets.bottom > 0 || isSmallHeight;

          return Column(
            children: [
              // AI Avatar / Visualizer (Collapsible)
              if (!isKeyboardOpen)
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.cardDark, AppTheme.backgroundDark],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated background glow
                        if (_isSpeaking)
                          FadeTransition(
                            opacity: _pulseController,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary.withOpacity(0.1),
                              ),
                            ),
                          ),

                        // Central Avatar & Status
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100, // Reduced from 120
                              height: 100, // Reduced from 120
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withOpacity(0.3),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.hub_rounded,
                                size: 50, // Reduced from 60
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isSpeaking
                                  ? 'NEXA is speaking...'
                                  : (_isListening ? 'Listening...' : 'NEXA'),
                              style: TextStyle(
                                color:
                                    _isSpeaking
                                        ? AppTheme.primary
                                        : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_isSpeaking || _isListening) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min, // Hug the bars
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  7,
                                  (index) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: _buildVisualizerBar(index),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              // Transcript / Chat Preview (Expanded)
              Expanded(
                flex: isKeyboardOpen ? 1 : 4,
                child: Container(
                  width: double.infinity,
                  color: AppTheme.backgroundDark,
                  child: Column(
                    children: [
                      /* Optional: Chat Header if needed
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        child: Text(
                          'Transcript', 
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10)
                        ),
                      ),
                      */
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) => _messages[index],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Controls
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Important for resize
                  children: [
                    if (_transcript.isNotEmpty && _isListening)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SingleChildScrollView(
                          child: Text(
                            '"$_transcript"',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                    // Text Input Mode
                    if (_isTextMode)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Type your response...',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textMuted,
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.surfaceDark,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                ),
                                onSubmitted: (_) => _sendTextMessage(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed:
                                  _isProcessing ? null : _sendTextMessage,
                              icon: Icon(
                                Icons.send_rounded,
                                color:
                                    _isProcessing
                                        ? AppTheme.textMuted
                                        : AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (!isKeyboardOpen) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Mute Button
                          IconButton(
                            icon: Icon(
                              InterviewAIService.isMuted
                                  ? Icons.volume_off
                                  : Icons.volume_up,
                              color:
                                  InterviewAIService.isMuted
                                      ? AppTheme.error
                                      : AppTheme.textMuted,
                            ),
                            onPressed: () {
                              setState(() {
                                final newState = !InterviewAIService.isMuted;
                                InterviewAIService.setMuted(newState);
                                print(
                                  '🔊 [UI] Mute toggled to: $newState',
                                ); // Debug
                              });
                            },
                          ),
                          const SizedBox(width: 32),

                          // Main Mic Button
                          GestureDetector(
                            onTapDown: (_) => _startListening(),
                            onTapUp: (_) => _stopListeningAndSend(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    _isListening
                                        ? AppTheme.primary
                                        : AppTheme.surfaceDark,
                                boxShadow:
                                    _isListening
                                        ? [
                                          BoxShadow(
                                            color: AppTheme.primary.withOpacity(
                                              0.5,
                                            ),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ]
                                        : [],
                                border: Border.all(
                                  color:
                                      _isListening
                                          ? Colors.transparent
                                          : AppTheme.primary,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),

                          const SizedBox(width: 32),

                          // Keyboard Input Toggle
                          IconButton(
                            icon: Icon(
                              _isTextMode
                                  ? Icons.keyboard_hide
                                  : Icons.keyboard,
                              color:
                                  _isTextMode
                                      ? AppTheme.primary
                                      : AppTheme.textMuted,
                            ),
                            onPressed: () {
                              setState(() => _isTextMode = !_isTextMode);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isTextMode
                            ? 'Type your response above'
                            : (_isListening
                                ? 'Release to send'
                                : 'Hold to speak'),
                        style: TextStyle(
                          color: AppTheme.textMuted.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVisualizerBar(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 150 + index * 30),
      width: 3,
      height: _isSpeaking || _isListening ? 12 : 3, // Smaller equal bars
      decoration: BoxDecoration(
        color: _isListening ? AppTheme.primary : AppTheme.success,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            title: const Text(
              'End Interview?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Would you like to complete the interview and see your results?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Continue',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Exit',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _completeInterview();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                ),
                child: const Text(
                  'See Results',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _completeInterview() async {
    // Show analyzing loading state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.surfaceDark),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SpinKitCubeGrid(color: AppTheme.primary, size: 60),
                  const SizedBox(height: 24),
                  const Text(
                    'Submitting & Analyzing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'AI is evaluating your responses to generate insights...',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
    );

    try {
      // Get AI Analysis Result
      final result = await _aiService.endInterview();

      // Create and save candidate record
      final candidate = Candidate(
        name: widget.candidateName,
        email: widget.email,
        phone: widget.phone,
        campaignId: widget.campaign.id,
        jobTitle: widget.campaign.title,
        status: 'pending_review',
        interviewResult: result,
      );

      await CandidateService.saveCandidate(candidate);
      await CampaignService.incrementInterviewCount(widget.campaign.id);

      if (mounted) {
        Navigator.pop(context); // Pop loading dialog

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => InterviewResultsScreen(
                  candidateName: widget.candidateName,
                  jobTitle: _jobTitle,
                  result: result,
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        TopNotification.show(
          context,
          message: 'Error analyzing interview: $e',
          icon: Icons.error_outline,
          color: AppTheme.error,
        );
      }
    }
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isAI;
  final DateTime timestamp;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isAI,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            const CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.hub_rounded, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isAI ? AppTheme.surfaceDark : AppTheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isAI ? 4 : 16),
                  bottomRight: Radius.circular(isAI ? 16 : 4),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (!isAI) ...[
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 14, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
