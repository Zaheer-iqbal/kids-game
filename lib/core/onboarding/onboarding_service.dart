import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the child (or parent) has already seen the three-screen
/// first-launch intro. Purely local: no account, no network.
class OnboardingService {
  OnboardingService(this._prefs);

  final SharedPreferences _prefs;

  static const String introSeenKey = 'intro_seen';

  bool get hasSeenIntro => _prefs.getBool(introSeenKey) ?? false;

  Future<void> markIntroSeen() => _prefs.setBool(introSeenKey, true);

  /// Test seam: lets a test start on the intro without clearing the store.
  static Map<String, Object> unseen() => <String, Object>{introSeenKey: false};
}
