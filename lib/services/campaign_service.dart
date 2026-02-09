import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_campaign.dart';

class CampaignService {
  static const String _storageKey = 'job_campaigns_demo_final';
  static List<JobCampaign>? _cache;

  /// Initialize and load campaigns from storage
  static Future<void> _init() async {
    if (_cache != null) return;

    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_storageKey);

    if (jsonStr != null) {
      try {
        final List<dynamic> list = jsonDecode(jsonStr);
        _cache = list.map((item) => JobCampaign.fromJson(item)).toList();
        print(
          '📂 [CampaignService] Loaded ${_cache!.length} campaigns from storage',
        );
      } catch (e) {
        print('❌ [CampaignService] Load error: $e');
        _cache = JobCampaign.getMockCampaigns();
      }
    } else {
      // First run: use mock data
      _cache = JobCampaign.getMockCampaigns();
      await _saveToDisk();
    }
  }

  /// Save current cache to persistent storage
  static Future<void> _saveToDisk() async {
    if (_cache == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = jsonEncode(_cache!.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
    print('💾 [CampaignService] Saved ${_cache!.length} campaigns to storage');
  }

  /// Get campaign by join code
  static Future<JobCampaign?> getCampaignByCode(String code) async {
    await _init();

    // Simulate network delay for realistic feel
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      return _cache!.firstWhere(
        (c) => c.joinCode.toUpperCase() == code.toUpperCase().trim(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Create a new campaign
  static Future<bool> createCampaign(JobCampaign campaign) async {
    await _init();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    _cache!.add(campaign);
    await _saveToDisk();

    print(
      '✅ [CampaignService] Created: ${campaign.title} (${campaign.joinCode})',
    );
    return true;
  }

  /// Get all campaigns
  static Future<List<JobCampaign>> getCampaigns() async {
    await _init();
    await Future.delayed(const Duration(milliseconds: 300));
    return _cache!;
  }

  /// Update an existing campaign
  static Future<void> saveCampaign(JobCampaign campaign) async {
    await _init();
    final index = _cache!.indexWhere((c) => c.id == campaign.id);
    if (index >= 0) {
      _cache![index] = campaign;
    } else {
      _cache!.add(campaign);
    }
    await _saveToDisk();
  }

  /// Increment interview count for a campaign
  static Future<void> incrementInterviewCount(String campaignId) async {
    await _init();
    final index = _cache!.indexWhere((c) => c.id == campaignId);
    if (index >= 0) {
      final campaign = _cache![index];
      _cache![index] = campaign.copyWith(
        candidatesInterviewed: campaign.candidatesInterviewed + 1,
      );
      await _saveToDisk();
      print(
        '📈 [CampaignService] Incremented count for ${campaign.title} to ${_cache![index].candidatesInterviewed}',
      );
    }
  }

  /// Delete a campaign
  static Future<void> deleteCampaign(String id) async {
    await _init();
    _cache!.removeWhere((c) => c.id == id);
    await _saveToDisk();
  }
}
