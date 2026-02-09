import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/candidate.dart';

class CandidateService {
  static const String _storageKey = 'candidates_demo_v1_final';
  static List<Candidate>? _cache;

  /// Initialize and load candidates from storage
  static Future<void> _init() async {
    if (_cache != null) return;

    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_storageKey);

    if (jsonStr != null) {
      try {
        final List<dynamic> list = jsonDecode(jsonStr);
        _cache = list.map((item) => Candidate.fromJson(item)).toList();
        print(
          '📂 [CandidateService] Loaded ${_cache!.length} candidates from storage',
        );
      } catch (e) {
        print('❌ [CandidateService] Load error: $e');
        _cache = InterviewResult.getMockCandidatesWithResults();
      }
    } else {
      // First run: use mock data
      _cache = InterviewResult.getMockCandidatesWithResults();
      await _saveToDisk();
    }
  }

  /// Save current cache to persistent storage
  static Future<void> _saveToDisk() async {
    if (_cache == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = jsonEncode(_cache!.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, jsonStr);
    print(
      '💾 [CandidateService] Saved ${_cache!.length} candidates to storage',
    );
  }

  /// Get all candidates
  static Future<List<Candidate>> getCandidates() async {
    await _init();
    return _cache ?? [];
  }

  /// Get candidates for a specific campaign
  static Future<List<Candidate>> getCandidatesByCampaignId(
    String campaignId,
  ) async {
    await _init();
    return _cache!.where((c) => c.campaignId == campaignId).toList();
  }

  /// Add or update a candidate
  static Future<void> saveCandidate(Candidate candidate) async {
    await _init();

    final index = _cache!.indexWhere((c) => c.id == candidate.id);
    if (index >= 0) {
      _cache![index] = candidate;
    } else {
      _cache!.insert(0, candidate);
    }

    await _saveToDisk();
  }

  /// Delete a candidate
  static Future<void> deleteCandidate(String id) async {
    await _init();
    _cache!.removeWhere((c) => c.id == id);
    await _saveToDisk();
  }
}
