import 'app_settings.dart';

/// Local-only storage for [AppSettings] — no account, no backend.
abstract interface class SettingsRepository {
  /// Reads the stored settings, falling back to [AppSettings.defaults].
  AppSettings load();

  /// Persists [settings] so they survive a restart.
  Future<void> save(AppSettings settings);
}
