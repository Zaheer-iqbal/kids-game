import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';
import 'settings_state.dart';

/// Parent-facing switches for the mascot and the delight animations.
///
/// Every setter emits first (instant UI) and then persists, so a slow disk can
/// never make a switch feel laggy, and a failed write cannot break the screen.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required SettingsRepository repository})
      : _repository = repository,
        super(const SettingsState());

  final SettingsRepository _repository;

  /// Reads the stored values. Called once during dependency configuration so
  /// the first frame already uses the saved settings.
  void load() {
    emit(SettingsState.fromSettings(_repository.load()));
  }

  void setAnimationsEnabled(bool value) =>
      _save(state.copyWith(animationsEnabled: value));

  void setSparklesEnabled(bool value) =>
      _save(state.copyWith(sparklesEnabled: value));

  void setMascotSpeechEnabled(bool value) =>
      _save(state.copyWith(mascotSpeechEnabled: value));

  void setSoundEnabled(bool value) => _save(state.copyWith(soundEnabled: value));

  void setVoiceEnabled(bool value) => _save(state.copyWith(voiceEnabled: value));

  void setReduceMotion(bool value) => _save(state.copyWith(reduceMotion: value));

  void setSpeechRate(double value) => _save(state.copyWith(speechRate: value));

  /// Changes the global background theme colour across all screens.
  void setThemeColor(int index) => _save(state.copyWith(themeColorIndex: index));

  /// Chooses a specific device voice, or `null` to go back to the app picking
  /// the best English voice for the device.
  void setVoiceName(String? value) => _save(
        value == null
            ? state.copyWith(clearVoiceName: true)
            : state.copyWith(voiceName: value),
      );

  void toggleAnimations() => setAnimationsEnabled(!state.animationsEnabled);

  void toggleSparkles() => setSparklesEnabled(!state.sparklesEnabled);

  void toggleMascotSpeech() =>
      setMascotSpeechEnabled(!state.mascotSpeechEnabled);

  void toggleReduceMotion() => setReduceMotion(!state.reduceMotion);

  /// Puts every switch back to on.
  void resetToDefaults() => _save(SettingsState.fromSettings(AppSettings.defaults));

  void _save(SettingsState next) {
    emit(next);
    // Emitted first so a switch feels instant; the write is best effort. Without
    // the catch an unavailable store would surface as an unhandled async error
    // and take the screen down with it.
    unawaited(_repository.save(next.settings).catchError(
      (Object error) => debugPrint('Could not save the delight settings: $error'),
    ));
  }
}
