import 'package:equatable/equatable.dart';

/// One letter or number presented in a lesson: what to show, say and colour.
class LessonGlyph extends Equatable {
  const LessonGlyph({
    required this.key,
    required this.word,
    required this.emoji,
    required this.colorValue,
  });

  /// The letter itself ("A") or the numeral ("7").
  final String key;

  /// The word it stands for ("Apple", "Seven").
  final String word;
  final String emoji;

  /// Opaque ARGB color shared with the grid cards.
  final int colorValue;

  String get label => '$key for $word';

  @override
  List<Object?> get props => <Object?>[key, word, emoji, colorValue];
}

/// The five kinds of play step in a lesson. The sequence always starts with
/// [MeetStep] and ends with a challenge step.
sealed class LessonStep extends Equatable {
  const LessonStep();

  /// Instruction shown at the top of the step.
  String get prompt;
}

/// "Meet A, B, C..." - every glyph of the level as tap-to-hear tiles.
class MeetStep extends LessonStep {
  const MeetStep({required this.glyphs});

  final List<LessonGlyph> glyphs;

  @override
  String get prompt => glyphs.length == 1
      ? 'Meet ${glyphs.first.key}!'
      : 'Meet ${glyphs.map((LessonGlyph g) => g.key).join(', ')}!';

  @override
  List<Object?> get props => <Object?>[glyphs];
}

/// Trace one glyph with a finger.
class TraceStep extends LessonStep {
  const TraceStep({required this.glyph});

  final LessonGlyph glyph;

  @override
  String get prompt => 'Trace the ${glyph.key}!';

  @override
  List<Object?> get props => <Object?>[glyph];
}

/// Hear a glyph, tap it among four choices.
class PickStep extends LessonStep {
  const PickStep({
    required this.target,
    required this.options,
    required this.prompt,
  });

  final LessonGlyph target;
  final List<LessonGlyph> options;

  @override
  final String prompt;

  @override
  List<Object?> get props => <Object?>[target, options, prompt];
}

/// Hear a sound, tap the picture it belongs to (letters).
class MatchStep extends LessonStep {
  const MatchStep({
    required this.target,
    required this.options,
    this.prompt = 'Tap the picture this sound says!',
  });

  final LessonGlyph target;
  final List<LessonGlyph> options;

  @override
  final String prompt;

  @override
  List<Object?> get props => <Object?>[target, options, prompt];
}

/// See a group of objects, tap how many there are (numbers).
class CountStep extends LessonStep {
  const CountStep({
    required this.target,
    required this.options,
    this.prompt = 'How many do you see?',
  });

  final LessonGlyph target;
  final List<LessonGlyph> options;

  @override
  final String prompt;

  @override
  List<Object?> get props => <Object?>[target, options, prompt];
}

/// A playable level of the adventure map.
class Lesson extends Equatable {
  const Lesson({
    required this.worldId,
    required this.level,
    required this.title,
    required this.glyphs,
    required this.steps,
  });

  /// Storage key of the world ("alphabet" / "numbers").
  final String worldId;
  final int level;
  final String title;

  /// Every glyph covered by the level (marked explored on completion).
  final List<LessonGlyph> glyphs;
  final List<LessonStep> steps;

  @override
  List<Object?> get props =>
      <Object?>[worldId, level, title, glyphs, steps];
}
