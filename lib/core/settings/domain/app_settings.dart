import 'package:equatable/equatable.dart';

/// Parent-controlled switches for the mascot and the delight animations.
///
/// Pure data: the repository persists it, the cubit exposes it and the widgets
/// read it through the delight scope.
class AppSettings extends Equatable {
  const AppSettings({
    this.animationsEnabled = true,
    this.sparklesEnabled = true,
    this.mascotSpeechEnabled = true,
    this.soundEnabled = true,
    this.voiceEnabled = true,
  });

  /// Everything on: the default a fresh install starts with.
  static const AppSettings defaults = AppSettings();

  /// Master switch for motion (mascot breathing/jumping, card pops, confetti).
  final bool animationsEnabled;

  /// The random sparkle bursts on letter and number cards.
  final bool sparklesEnabled;

  /// The mascot reading its own lines out loud through the device voice.
  final bool mascotSpeechEnabled;

  /// Synthesized feedback sounds (pops, chimes, whooshes).
  final bool soundEnabled;

  /// Voice narration for letters, numbers, quiz questions and fun facts.
  final bool voiceEnabled;

  AppSettings copyWith({
    bool? animationsEnabled,
    bool? sparklesEnabled,
    bool? mascotSpeechEnabled,
    bool? soundEnabled,
    bool? voiceEnabled,
  }) {
    return AppSettings(
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      sparklesEnabled: sparklesEnabled ?? this.sparklesEnabled,
      mascotSpeechEnabled: mascotSpeechEnabled ?? this.mascotSpeechEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        animationsEnabled,
        sparklesEnabled,
        mascotSpeechEnabled,
        soundEnabled,
        voiceEnabled,
      ];
}
