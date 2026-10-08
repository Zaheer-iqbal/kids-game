import 'package:flutter_test/flutter_test.dart';
import 'package:kids/features/alphabet/data/models/letter_model.dart';

void main() {
  group('LetterModel', () {
    test('parses emoji and hex color into an opaque ARGB int', () {
      final LetterModel m = LetterModel.fromJson(<String, dynamic>{
        'letter': 'A',
        'word': 'Apple',
        'emoji': '🍎',
        'color': '#FFB199',
      });
      expect(m.letter, 'A');
      expect(m.word, 'Apple');
      expect(m.emoji, '🍎');
      expect(m.colorValue, 0xFFFFB199);
    });

    test('falls back to a safe color when the hex is malformed', () {
      final LetterModel m = LetterModel.fromJson(<String, dynamic>{
        'letter': 'X',
        'word': 'Xylophone',
        'emoji': '🎼',
        'color': 'not-a-color',
      });
      expect(m.colorValue & 0xFFFFFF, 0xFF8A5B);
    });

    test('round-trips through toJson without losing opacity', () {
      final LetterModel m = LetterModel.fromJson(<String, dynamic>{
        'letter': 'Q',
        'word': 'Queen',
        'emoji': '👑',
        'color': '#E0C868',
      });
      final LetterModel back = LetterModel.fromJson(m.toJson());
      expect(back.emoji, m.emoji);
      expect(back.colorValue, m.colorValue);
    });
  });
}
