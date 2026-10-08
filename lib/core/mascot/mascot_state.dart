import 'package:equatable/equatable.dart';

import 'mascot_mood.dart';

/// What the mascot is doing right now: a mood, an optional speech-bubble line
/// and two counters the widget layer turns into animations.
class MascotState extends Equatable {
  const MascotState({
    this.mood = MascotMood.idle,
    this.message,
    this.token = 0,
    this.giggleToken = 0,
  });

  final MascotMood mood;

  /// Line for the speech bubble; `null` hides the bubble.
  final String? message;

  /// Increments on every mood change so the mascot restarts its one-shot
  /// reaction animation even when the same mood is repeated.
  final int token;

  /// Increments whenever the mascot itself is tapped, which triggers a
  /// giggle wiggle while the mood stays as it is.
  final int giggleToken;

  /// Sentinel so a nullable field can be explicitly cleared back to `null`.
  static const Object _unset = Object();

  bool get isReacting => mood.isReaction;

  MascotState copyWith({
    MascotMood? mood,
    Object? message = _unset,
    int? token,
    int? giggleToken,
  }) {
    return MascotState(
      mood: mood ?? this.mood,
      message: identical(message, _unset) ? this.message : message as String?,
      token: token ?? this.token,
      giggleToken: giggleToken ?? this.giggleToken,
    );
  }

  @override
  List<Object?> get props => <Object?>[mood, message, token, giggleToken];
}
