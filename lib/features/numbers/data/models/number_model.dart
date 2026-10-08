import '../../domain/entities/number_entity.dart';

class NumberModel extends NumberEntity {
  const NumberModel({
    required super.number,
    required super.word,
    required super.emoji,
    required super.colorValue,
  });

  factory NumberModel.fromJson(Map<String, dynamic> json) {
    final String hex = json['color'] as String? ?? '#7FC8C9';
    final int colorValue =
        int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0xFF7FC8C9;
    return NumberModel(
      number: json['number'] as int,
      word: json['word'] as String,
      emoji: json['emoji'] as String? ?? '⭐',
      colorValue: 0xFF000000 | colorValue,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'number': number,
        'word': word,
        'emoji': emoji,
        'color': '#${(colorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
      };
}