import 'package:equatable/equatable.dart';

import '../domain/app_settings.dart';

/// State of the parent settings screen: one switch per delight feature.
class SettingsState extends Equatable {
  const SettingsState({
    this.animationsEnabled = true,
    this.sparklesEnabled = true,
    this.mascotSpeechEnabled = true,
    this.soundEnabled = true,
    this.voiceEnabled = true,
    this.isLoaded = false,
  });

  /// Builds the state from the persisted entity.
  factory SettingsState.fromSettings(
    AppSettings settings, {
    bool isLoaded = true,
  }) {
    return SettingsState(
      animationsEnabled: settings.animationsEnabled,
      sparklesEnabled: settings.sparklesEnabled,
      mascotSpeechEnabled: settings.mascotSpeechEnabled,
      soundEnabled: settings.soundEnabled,
      voiceEnabled: settings.voiceEnabled,
      isLoaded: isLoaded,
    );
  }

  final bool animationsEnabled;
  final bool sparklesEnabled;
  final bool mascotSpeechEnabled;

  /// Synthesized feedback sounds (pops, chimes, whooshes).
  final bool soundEnabled;

  /// Voice narration for letters, numbers, questions and facts.
  final bool voiceEnabled;

  /// True once the stored values have been read at least once.
  final bool isLoaded;

  AppSettings get settings => AppSettings(
        animationsEnabled: animationsEnabled,
        sparklesEnabled: sparklesEnabled,
        mascotSpeechEnabled: mascotSpeechEnabled,
        soundEnabled: soundEnabled,
        voiceEnabled: voiceEnabled,
      );

  SettingsState copyWith({
    bool? animationsEnabled,
    bool? sparklesEnabled,
    bool? mascotSpeechEnabled,
    bool? soundEnabled,
    bool? voiceEnabled,
    bool? isLoaded,
  }) {
    return SettingsState(
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      sparklesEnabled: sparklesEnabled ?? this.sparklesEnabled,
      mascotSpeechEnabled: mascotSpeechEnabled ?? this.mascotSpeechEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        animationsEnabled,
        sparklesEnabled,
        mascotSpeechEnabled,
        soundEnabled,
        voiceEnabled,
        isLoaded,
      ];
}
