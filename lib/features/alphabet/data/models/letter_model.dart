import '../../domain/entities/letter_item.dart';

class LetterModel extends LetterItem {
  const LetterModel({
    required super.letter,
    required super.word,
    required super.emoji,
    required super.colorValue,
  });

  factory LetterModel.fromJson(Map<String, dynamic> json) {
    final String hex = json['color'] as String? ?? '#FF8A5B';
    final int colorValue =
        int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0xFFFF8A5B;
    return LetterModel(
      letter: json['letter'] as String,
      word: json['word'] as String,
      emoji: json['emoji'] as String? ?? '⭐',
      colorValue: 0xFF000000 | colorValue,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'letter': letter,
        'word': word,
        'emoji': emoji,
        'color': '#${(colorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
      };
}