import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import 'branding_model.dart';

/// Persists [BrandingConfig] so event mode survives a restart between talk rehearsal and stage.
class BrandingRepository {
  static const String _preferencesKey = 'branding_config';

  Future<BrandingConfig> load() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getString(_preferencesKey);
    if (stored == null) return const BrandingConfig();
    try {
      return BrandingConfig.fromJson(jsonDecode(stored) as Map<String, dynamic>);
    } on FormatException catch (error) {
      developer.log('⚠️ [Branding] Ignoring unreadable saved branding: $error', name: 'VoiceBridge.Branding');
      return const BrandingConfig();
    }
  }

  Future<void> save(BrandingConfig config) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferencesKey, jsonEncode(config.toJson()));
  }
}
