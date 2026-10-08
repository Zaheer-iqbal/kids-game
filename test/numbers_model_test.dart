import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids/features/numbers/data/models/number_model.dart';

void main() {
  group('NumberModel', () {
    test('parses emoji and hex color into an opaque ARGB int', () {
      final NumberModel m = NumberModel.fromJson(<String, dynamic>{
        'number': 42,
        'word': 'Forty Two',
        'emoji': '🚀',
        'color': '#FFB199',
      });
      expect(m.number, 42);
      expect(m.word, 'Forty Two');
      expect(m.emoji, '🚀');
      expect(m.colorValue, 0xFFFFB199);
      expect(m.label, '42 – Forty Two');
    });

    test('falls back to a safe color when the hex is malformed', () {
      final NumberModel m = NumberModel.fromJson(<String, dynamic>{
        'number': 7,
        'word': 'Seven',
        'emoji': '⭐',
        'color': 'not-a-color',
      });
      expect(m.colorValue, 0xFF7FC8C9);
    });

    test('round-trips through toJson without losing opacity', () {
      final NumberModel m = NumberModel.fromJson(<String, dynamic>{
        'number': 100,
        'word': 'One Hundred',
        'emoji': '🎡',
        'color': '#AFB2D6',
      });
      final NumberModel back = NumberModel.fromJson(m.toJson());
      expect(back.number, m.number);
      expect(back.emoji, m.emoji);
      expect(back.colorValue, m.colorValue);
    });

    test('assets/data/numbers.json holds exactly 100 unique entries', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final String raw =
          await rootBundle.loadString('assets/data/numbers.json');
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      expect(decoded.length, 100);
      final Set<int> numbers = decoded
          .map(
            (dynamic item) =>
                (NumberModel.fromJson(item as Map<String, dynamic>)).number,
          )
          .toSet();
      expect(numbers.length, 100);
      final NumberModel first = NumberModel.fromJson(
        decoded.first as Map<String, dynamic>,
      );
      expect(first.word, 'One');
      expect(first.colorValue & 0xFFFFFF, 0xFFB199);
    });

    test('every number has its own emoji, so no two cards look alike', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final String raw =
          await rootBundle.loadString('assets/data/numbers.json');
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final List<NumberModel> models = decoded
          .map(
            (dynamic item) =>
                NumberModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
      final Set<String> emoji = models.map((NumberModel m) => m.emoji).toSet();
      expect(emoji.length, 100);
      for (final NumberModel m in models) {
        expect(m.emoji.trim(), isNotEmpty, reason: 'number ${m.number}');
        // An emoji is never plain ASCII text.
        expect(m.emoji.codeUnitAt(0), greaterThan(0x2000));
      }
    });
  });
}
