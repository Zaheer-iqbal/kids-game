import 'package:equatable/equatable.dart';

/// A single letter of the alphabet with everything needed to render and speak
/// it, with zero dependency on external assets.
class LetterItem extends Equatable {
  const LetterItem({
    required this.letter,
    required this.word,
    required this.emoji,
    required this.colorValue,
  });

  final String letter;
  final String word;

  /// The picture shown next to the letter, stored as an emoji character so no
  /// image files are needed. Rendered with a plain `Text` widget.
  final String emoji;

  /// Opaque ARGB color, e.g. `0xFFFFB199`.
  final int colorValue;

  String get label => '$letter for $word';

  @override
  List<Object?> get props => <Object?>[letter, word, emoji, colorValue];
}