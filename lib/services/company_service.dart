import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/company_profile.dart';

class CompanyService {
  static const String _storageKey = 'company_profile';
  static CompanyProfile? _cache;

  /// Initialize and load profile from storage
  static Future<void> _init() async {
    if (_cache != null) return;

    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_storageKey);

    if (jsonStr != null) {
      try {
        _cache = CompanyProfile.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        print('❌ [CompanyService] Load error: $e');
        _cache = CompanyProfile.defaultProfile();
      }
    } else {
      _cache = CompanyProfile.defaultProfile();
      await _saveToDisk();
    }
  }

  /// Save current cache to persistent storage
  static Future<void> _saveToDisk() async {
    if (_cache == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = jsonEncode(_cache!.toJson());
    await prefs.setString(_storageKey, jsonStr);
  }

  /// Get company profile
  static Future<CompanyProfile> getProfile() async {
    await _init();
    return _cache!;
  }

  /// Update company profile
  static Future<void> saveProfile(CompanyProfile profile) async {
    _cache = profile;
    await _saveToDisk();
  }
}
