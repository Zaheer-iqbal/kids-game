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
    this.reduceMotion = false,
    this.speechRate = defaultSpeechRate,
    this.voiceName,
    this.themeColorIndex = 0,
  });

  /// Speaking speed used by the device voice when narrating. Deliberately
  /// slower than the platform default so young listeners keep up.
  static const double defaultSpeechRate = 0.45;

  /// Lowest and highest speaking speeds the parent slider offers.
  static const double minSpeechRate = 0.25;
  static const double maxSpeechRate = 0.75;

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

  /// Parent switch: keep only simple fades, never move or scale a surface.
  /// Off by default; the system reduced-motion flag is honoured regardless.
  final bool reduceMotion;

  /// Speaking speed for narration, in the engine's 0.0–1.0 range.
  final double speechRate;

  /// The voice the parent picked from the device list, or `null` to let the
  /// app choose the best English voice automatically.
  final String? voiceName;

  /// Global background theme index (0 = Sunny Garden, 1 = Starry Sky,
  /// 2 = Candy Land, 3 = Cozy Nest, 4 = Ocean Breeze, 5 = Lavender Dream).
  final int themeColorIndex;

  AppSettings copyWith({
    bool? animationsEnabled,
    bool? sparklesEnabled,
    bool? mascotSpeechEnabled,
    bool? soundEnabled,
    bool? voiceEnabled,
    bool? reduceMotion,
    double? speechRate,
    String? voiceName,
    bool clearVoiceName = false,
    int? themeColorIndex,
  }) {
    return AppSettings(
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      sparklesEnabled: sparklesEnabled ?? this.sparklesEnabled,
      mascotSpeechEnabled: mascotSpeechEnabled ?? this.mascotSpeechEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      speechRate: speechRate ?? this.speechRate,
      voiceName: clearVoiceName ? null : (voiceName ?? this.voiceName),
      themeColorIndex: themeColorIndex ?? this.themeColorIndex,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        animationsEnabled,
        sparklesEnabled,
        mascotSpeechEnabled,
        soundEnabled,
        voiceEnabled,
        reduceMotion,
        speechRate,
        voiceName,
        themeColorIndex,
      ];
}
