import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

/// Persists the parent settings in `SharedPreferences`.
///
/// Reads are synchronous because the store is already open by the time
/// dependencies are configured, which keeps the very first frame free of
/// "settings not loaded yet" flicker.
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const String animationsKey = 'settings_animations_enabled';
  static const String sparklesKey = 'settings_sparkles_enabled';
  static const String speechKey = 'settings_mascot_speech_enabled';
  static const String soundKey = 'settings_sound_enabled';
  static const String voiceKey = 'settings_voice_enabled';

  @override
  AppSettings load() {
    return AppSettings(
      animationsEnabled: _prefs.getBool(animationsKey) ?? true,
      sparklesEnabled: _prefs.getBool(sparklesKey) ?? true,
      mascotSpeechEnabled: _prefs.getBool(speechKey) ?? true,
      soundEnabled: _prefs.getBool(soundKey) ?? true,
      voiceEnabled: _prefs.getBool(voiceKey) ?? true,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _prefs.setBool(animationsKey, settings.animationsEnabled);
    await _prefs.setBool(sparklesKey, settings.sparklesEnabled);
    await _prefs.setBool(speechKey, settings.mascotSpeechEnabled);
    await _prefs.setBool(soundKey, settings.soundEnabled);
    await _prefs.setBool(voiceKey, settings.voiceEnabled);
  }
}
