import 'package:equatable/equatable.dart';

/// A single number (1–100) with everything needed to render and speak it,
/// with zero dependency on external assets.
class NumberEntity extends Equatable {
  const NumberEntity({
    required this.number,
    required this.word,
    required this.emoji,
    required this.colorValue,
  });

  final int number;

  /// The number written in words, e.g. "Forty Two".
  final String word;

  /// The picture used when counting this number, stored as an emoji character
  /// so no image files are needed. Rendered with a plain `Text` widget.
  final String emoji;

  /// Opaque ARGB color, e.g. `0xFFFFB199`.
  final int colorValue;

  String get label => '$number – $word';

  @override
  List<Object?> get props => <Object?>[number, word, emoji, colorValue];
}