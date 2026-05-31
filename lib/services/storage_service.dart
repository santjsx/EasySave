import 'package:shared_preferences/shared_preferences.dart';

/// Service wrapper managing persistent key-value pairs using [SharedPreferences].
/// Strictly holds system state/wizard flags, completely avoiding contacts caching.
class StorageService {
  static const String _keyPermissionShown = 'permission_explanation_shown';
  static const String _keyLanguagePackPrompted = 'language_pack_prompted';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  /// Checks if the pre-permissions explanation page has ever been shown.
  bool isPermissionShown() {
    return _prefs.getBool(_keyPermissionShown) ?? false;
  }

  /// Sets permission interstitial show state as completed.
  Future<void> setPermissionShown(bool value) async {
    await _prefs.setBool(_keyPermissionShown, value);
  }

  /// Checks if the user was already prompted to download the Telugu Speech Pack.
  bool wasLanguagePackPrompted() {
    return _prefs.getBool(_keyLanguagePackPrompted) ?? false;
  }

  /// Sets state for Telugu voice pack prompted settings.
  Future<void> setLanguagePackPrompted(bool value) async {
    await _prefs.setBool(_keyLanguagePackPrompted, value);
  }

  /// Generic helper to wipe stored keys.
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
