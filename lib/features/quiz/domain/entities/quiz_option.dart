import 'package:equatable/equatable.dart';

import '../../../alphabet/domain/entities/letter_item.dart';
import '../../../numbers/domain/entities/number_entity.dart';

/// How an option is drawn on its card: as a code-drawn picture (letters) or as
/// a big numeral (numbers).
enum QuizOptionStyle { picture, numeral }

/// One answer choice in any quiz mode. Works for both letters and numbers.
class QuizOption extends Equatable {
  const QuizOption({
    required this.key,
    required this.displayText,
    required this.hintText,
    required this.emoji,
    required this.colorValue,
    required this.style,
  });

  factory QuizOption.fromLetter(LetterItem letter) => QuizOption(
        key: letter.letter,
        displayText: letter.letter,
        hintText: letter.word,
        emoji: letter.emoji,
        colorValue: letter.colorValue,
        style: QuizOptionStyle.picture,
      );

  factory QuizOption.fromNumber(NumberEntity number) => QuizOption(
        key: '${number.number}',
        displayText: '${number.number}',
        hintText: number.word,
        emoji: number.emoji,
        colorValue: number.colorValue,
        style: QuizOptionStyle.numeral,
      );

  /// Unique answer key: the letter itself (e.g. "B") or the numeral ("7").
  final String key;

  /// Big text shown on the card (letter or numeral).
  final String displayText;

  /// Small helper text (the word, e.g. "Ball" / "Forty Two").
  final String hintText;

  /// Picture for the card, stored as an emoji character.
  final String emoji;

  final int colorValue;
  final QuizOptionStyle style;

  @override
  List<Object?> get props =>
      <Object?>[key, displayText, hintText, emoji, colorValue, style];
}