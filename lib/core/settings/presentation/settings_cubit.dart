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

  void toggleAnimations() => setAnimationsEnabled(!state.animationsEnabled);

  void toggleSparkles() => setSparklesEnabled(!state.sparklesEnabled);

  void toggleMascotSpeech() =>
      setMascotSpeechEnabled(!state.mascotSpeechEnabled);

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
