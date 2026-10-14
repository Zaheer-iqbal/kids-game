import 'package:flutter/foundation.dart';

/// One animal in the puzzle zoo: a distinct emoji sticker, its English name,
/// the sound it makes (spoken after solving) and a one-line fun fact.
@immutable
class Animal {
  const Animal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.sound,
    required this.fact,
  });

  /// Stable 0-based id; also the puzzle's level index.
  final int id;
  final String name;
  final String emoji;

  /// The sound word spoken with the name, e.g. `Roar!`.
  final String sound;
  final String fact;

  /// The line TTS reads on a win: `Lion! Roar!`
  String get celebrationLine => '$name! $sound';

  @override
  bool operator ==(Object other) => other is Animal && other.id == id;

  @override
  int get hashCode => id.hashCode;
}