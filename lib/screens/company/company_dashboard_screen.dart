import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import '../../theme/app_theme.dart';
import '../../models/job_campaign.dart';
import '../../models/candidate.dart';
import '../../services/campaign_service.dart';
import 'create_campaign_screen.dart';
import 'candidate_detail_screen.dart';
import 'company_profile_screen.dart';
import '../../services/candidate_service.dart';
import '../../widgets/top_notification.dart';

/// Company Dashboard - View campaigns and candidates
class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  List<JobCampaign> _campaigns = [];
  List<Candidate> _candidates = [];
  String? _selectedCampaignId;
  String _filterStatus =
      'all'; // 'all', 'pending', 'shortlisted', 'hired', 'rejected'
  int _selectedNavIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    final campaigns = await CampaignService.getCampaigns();
    final candidates = await CandidateService.getCandidates();

    if (mounted) {
      setState(() {
        _campaigns = campaigns;
        _candidates = candidates;
        _isLoading = false;
      });
    }
  }

  List<Candidate> get _filteredCandidates {
    final list =
        _candidates.where((c) {
          final matchesCampaign =
              _selectedCampaignId == null ||
              c.campaignId == _selectedCampaignId;
          if (!matchesCampaign) return false;

          if (_filterStatus == 'all') return true;
          if (_filterStatus == 'pending') {
            return c.status == 'pending' ||
                c.status == 'pending_review' ||
                c.status == 'reviewed';
          }
          return c.status == _filterStatus;
        }).toList();

    // Sort by match score descending
    list.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return list;
  }

  Widget _buildFilterTab(String label, String status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.surfaceDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppTheme.cardDark,
            title: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HireAI Dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'TechCorp Africa',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CompanyProfileScreen(),
                    ),
                  );
                },
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    'HR',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          floatingActionButton:
              _selectedNavIndex == 2
                  ? FloatingActionButton.extended(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateCampaignScreen(),
                        ),
                      );
                      if (result != null) {
                        _loadCampaigns();
                      }
                    },
                    backgroundColor: AppTheme.primary,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      isMobile ? 'New' : 'New Campaign',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  : null,
          bottomNavigationBar: isMobile ? _buildBottomNav() : null,
          body:
              isMobile
                  ? _buildMainContent(isMobile)
                  : Row(
                    children: [
                      _buildSideNav(),
                      Expanded(child: _buildMainContent(isMobile)),
                    ],
                  ),
        );
      },
    );
  }

  Widget _buildSideNav() {
    final navItems = [
      {'icon': Icons.dashboard, 'label': 'Dashboard'},
      {'icon': Icons.people, 'label': 'Candidates'},
      {'icon': Icons.campaign, 'label': 'Campaigns'},
      {'icon': Icons.analytics, 'label': 'Analytics'},
    ];

    return Container(
      width: 80,
      color: AppTheme.cardDark,
      child: Column(
        children: [
          const SizedBox(height: 20),
          ...navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == _selectedNavIndex;

            return GestureDetector(
              onTap: () => setState(() => _selectedNavIndex = index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.transparent, // Ensure full tap area
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppTheme.primary.withOpacity(0.08)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TweenAnimationBuilder<Color?>(
                        duration: const Duration(milliseconds: 200),
                        tween: ColorTween(
                          begin:
                              isSelected
                                  ? AppTheme.textMuted
                                  : AppTheme.primary,
                          end:
                              isSelected
                                  ? AppTheme.primary
                                  : AppTheme.textMuted,
                        ),
                        builder: (context, color, child) {
                          return Icon(item['icon'] as IconData, color: color);
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color:
                            isSelected ? AppTheme.primary : AppTheme.textMuted,
                      ),
                      child: Text(item['label'] as String),
                    ),
                  ],
                ),
              ),
            );
          }),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Exit',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final navItems = [
      {'icon': Icons.dashboard, 'label': 'Dashboard'},
      {'icon': Icons.people, 'label': 'Candidates'},
      {'icon': Icons.campaign, 'label': 'Campaigns'},
      {'icon': Icons.analytics, 'label': 'Analytics'},
    ];

    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(
          top: BorderSide(color: AppTheme.primary.withOpacity(0.1), width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == _selectedNavIndex;

                return GestureDetector(
                  onTap: () => setState(() => _selectedNavIndex = index),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<Color?>(
                          duration: const Duration(milliseconds: 200),
                          tween: ColorTween(
                            begin:
                                isSelected
                                    ? AppTheme.textMuted
                                    : AppTheme.primary,
                            end:
                                isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textMuted,
                          ),
                          builder: (context, color, child) {
                            return Icon(
                              item['icon'] as IconData,
                              color: color,
                              size: 24,
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                            color:
                                isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textMuted,
                          ),
                          child: Text(item['label'] as String),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedNavIndex) {
      case 0:
        return _buildDashboardView(isMobile);
      case 1:
        return _buildCandidatesView(isMobile);
      case 2:
        return _buildCampaignsView(isMobile);
      case 3:
        return _buildAnalyticsView(isMobile);
      default:
        return _buildDashboardView(isMobile);
    }
  }

  Widget _buildDashboardView(bool isMobile) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
          FadeInDown(
            duration: const Duration(milliseconds: 400),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildKPICard(
                    'Active Campaigns',
                    '${_campaigns.where((c) => c.status == 'active').length}',
                    Icons.campaign,
                    AppTheme.info,
                  ),
                  const SizedBox(width: 16),
                  _buildKPICard(
                    'Total Interviews',
                    '${_candidates.length}',
                    Icons.mic,
                    AppTheme.success,
                  ),
                  const SizedBox(width: 16),
                  _buildKPICard(
                    'Avg. Score',
                    '${_calculateAvgScore()}%',
                    Icons.verified,
                    AppTheme.primary,
                  ),
                  const SizedBox(width: 16),
                  _buildKPICard(
                    'Shortlisted',
                    '${_candidates.where((c) => c.status == 'shortlisted').length}',
                    Icons.star,
                    AppTheme.warning,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Campaign Selector
          FadeInDown(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Campaigns', style: AppTheme.labelLarge),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _campaigns.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final campaign = _campaigns[index];
                      final isSelected = campaign.id == _selectedCampaignId;

                      return GestureDetector(
                        onTap:
                            () => setState(
                              () => _selectedCampaignId = campaign.id,
                            ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? AppTheme.primary
                                    : AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppTheme.primary
                                      : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    campaign.title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${campaign.candidatesInterviewed}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Join Code Row
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.vpn_key,
                                    size: 12,
                                    color:
                                        isSelected
                                            ? Colors.white70
                                            : AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    campaign.joinCode,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white70
                                              : AppTheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(text: campaign.joinCode),
                                      );
                                      TopNotification.show(
                                        context,
                                        message:
                                            'Code ${campaign.joinCode} copied!',
                                        icon: Icons.content_copy,
                                        color: AppTheme.success,
                                      );
                                    },
                                    child: Icon(
                                      Icons.copy,
                                      size: 14,
                                      color:
                                          isSelected
                                              ? Colors.white70
                                              : AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Candidates Leaderboard
          FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterTab('All', 'all'),
                      const SizedBox(width: 12),
                      _buildFilterTab('Pending', 'pending'),
                      const SizedBox(width: 12),
                      _buildFilterTab('Shortlisted', 'shortlisted'),
                      const SizedBox(width: 12),
                      _buildFilterTab('Hired', 'hired'),
                      const SizedBox(width: 12),
                      _buildFilterTab('Rejected', 'rejected'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Top Candidates (AI Ranked)',
                        style: AppTheme.heading2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Candidate Cards
                if (_filteredCandidates.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          size: 48,
                          color: AppTheme.textMuted.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No candidates found',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                else
                  ..._filteredCandidates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final candidate = entry.value;

                    return FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: Duration(milliseconds: 100 * index),
                      child: _buildCandidateCard(
                        candidate,
                        index + 1,
                        isMobile,
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(Candidate candidate, int rank, bool isMobile) {
    final result = candidate.interviewResult;
    final score = candidate.matchScore;
    final scoreColor =
        score >= 85
            ? AppTheme.success
            : (score >= 70 ? AppTheme.warning : AppTheme.error);

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CandidateDetailScreen(candidate: candidate),
          ),
        );
        _loadCampaigns(); // Reload to show updated status/scores
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                score >= 85
                    ? AppTheme.success.withOpacity(0.3)
                    : AppTheme.surfaceDark,
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Simple Avatar (no percentage overlay)
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.surfaceDark,
                  child: Text(
                    candidate.name[0],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              candidate.name,
                              style: AppTheme.heading3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Clean score badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scoreColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: scoreColor, width: 1),
                            ),
                            child: Text(
                              '$score%',
                              style: TextStyle(
                                color: scoreColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        candidate.jobTitle,
                        style: AppTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${candidate.email} • ${candidate.phone}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildStatusBadge(candidate.status),
                          if (result != null)
                            _buildLanguageBadge(result.language),
                        ],
                      ),
                    ],
                  ),
                ),

                if (!isMobile)
                  // Action Button
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) =>
                                  CandidateDetailScreen(candidate: candidate),
                        ),
                      );
                      _loadCampaigns();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'View Report',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            if (isMobile) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CandidateDetailScreen(candidate: candidate),
                      ),
                    );
                    _loadCampaigns();
                  },
                  icon: const Icon(
                    Icons.description,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'View Full Report',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],

            if (result != null) ...[
              const SizedBox(height: 16),
              const Divider(color: AppTheme.surfaceDark),
              const SizedBox(height: 12),

              // Metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _buildMetric('Technical', result.technicalScore),
                  ),
                  Expanded(
                    child: _buildMetric(
                      'Communication',
                      result.communicationScore,
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      'Problem Solving',
                      result.problemSolvingScore,
                    ),
                  ),
                  Expanded(
                    child: _buildMetric('Culture Fit', result.cultureFitScore),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // AI Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.success,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI: ${result.aiSummary}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, int score) {
    final color =
        score >= 85
            ? AppTheme.success
            : (score >= 70 ? AppTheme.warning : AppTheme.error);

    return Column(
      children: [
        Text(
          '$score',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'shortlisted':
        color = AppTheme.success;
        break;
      case 'interviewed':
        color = AppTheme.info;
        break;
      case 'hired':
        color = AppTheme.primary;
        break;
      default:
        color = AppTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildLanguageBadge(String language) {
    final isAmharic = language == 'am';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isAmharic ? 'አማርኛ' : 'EN',
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  int _calculateAvgScore() {
    if (_candidates.isEmpty) return 0;
    final total = _candidates.fold<int>(0, (sum, c) => sum + c.matchScore);
    return (total / _candidates.length).round();
  }

  Widget _buildCandidatesView(bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Candidates', style: AppTheme.heading2),
          const SizedBox(height: 24),
          // Status Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterTab('All', 'all'),
                const SizedBox(width: 12),
                _buildFilterTab('Pending', 'pending'),
                const SizedBox(width: 12),
                _buildFilterTab('Shortlisted', 'shortlisted'),
                const SizedBox(width: 12),
                _buildFilterTab('Hired', 'hired'),
                const SizedBox(width: 12),
                _buildFilterTab('Rejected', 'rejected'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_filteredCandidates.isEmpty)
            _buildEmptyState('No candidates found')
          else
            ..._filteredCandidates.asMap().entries.map((entry) {
              final index = entry.key;
              final candidate = entry.value;
              return FadeInUp(
                duration: const Duration(milliseconds: 300),
                delay: Duration(milliseconds: 50 * index),
                child: _buildCandidateCard(candidate, index + 1, isMobile),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCampaignsView(bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Campaigns', style: AppTheme.heading2),
          const SizedBox(height: 24),
          if (_campaigns.isEmpty)
            _buildEmptyState('No campaigns yet')
          else
            ..._campaigns.map(
              (campaign) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.cardDecoration,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.business_center,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(campaign.title, style: AppTheme.heading3),
                          const SizedBox(height: 4),
                          Text(
                            'Join Code: ${campaign.joinCode}',
                            style: const TextStyle(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${campaign.candidatesInterviewed} candidates',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView(bool isMobile) {
    if (_candidates.isEmpty) {
      return _buildEmptyState('No data for analytics yet');
    }

    final total = _candidates.length;
    final shortlisted =
        _candidates.where((c) => c.status == 'shortlisted').length;
    final hired = _candidates.where((c) => c.status == 'hired').length;
    final rejected = _candidates.where((c) => c.status == 'rejected').length;

    // Calculate pass rate (score >= 70)
    final outcomes = _candidates.where((c) => c.interviewResult != null);
    final passed = outcomes.where((c) => c.matchScore >= 70).length;
    final passRate =
        outcomes.isEmpty ? 0 : ((passed / outcomes.length) * 100).round();

    // Skill breakdown
    int techSum = 0, commSum = 0, probSum = 0, cultSum = 0;
    int count = 0;
    for (var c in outcomes) {
      if (c.interviewResult != null) {
        techSum += c.interviewResult!.technicalScore;
        commSum += c.interviewResult!.communicationScore;
        probSum += c.interviewResult!.problemSolvingScore;
        cultSum += c.interviewResult!.cultureFitScore;
        count++;
      }
    }
    final avgTech = count == 0 ? 0 : (techSum / count).round();
    final avgComm = count == 0 ? 0 : (commSum / count).round();
    final avgProb = count == 0 ? 0 : (probSum / count).round();
    final avgCult = count == 0 ? 0 : (cultSum / count).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recruitment Analytics', style: AppTheme.heading2),
          const SizedBox(height: 24),

          // Overview Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '$total',
                  Colors.white,
                  Icons.people,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Shortlisted',
                  '$shortlisted',
                  AppTheme.warning,
                  Icons.star,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Hired',
                  '$hired',
                  AppTheme.success,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Rejected',
                  '$rejected',
                  AppTheme.error,
                  Icons.cancel,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Text('Performance Metrics', style: AppTheme.heading3),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                _buildProgressBar(
                  'Pass Rate (>70%)',
                  passRate,
                  AppTheme.primary,
                ),
                const SizedBox(height: 20),
                const Divider(color: AppTheme.surfaceDark),
                const SizedBox(height: 20),
                _buildProgressBar('Technical Skills', avgTech, Colors.blue),
                const SizedBox(height: 16),
                _buildProgressBar('Communication', avgComm, Colors.green),
                const SizedBox(height: 16),
                _buildProgressBar('Problem Solving', avgProb, Colors.orange),
                const SizedBox(height: 16),
                _buildProgressBar('Culture Fit', avgCult, Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 20),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$value%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            size: 48,
            color: AppTheme.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
