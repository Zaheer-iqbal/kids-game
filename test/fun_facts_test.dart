import 'package:flutter_test/flutter_test.dart';
import 'package:kids/core/services/fun_facts.dart';

void main() {
  group('FunFacts', () {
    test('every letter A–Z has real original content (no fallback)', () {
      for (int i = 0; i < 26; i++) {
        final String letter = String.fromCharCode(65 + i);
        final String fact = FunFacts.forLetter(letter);
        expect(
          fact,
          isNot(FunFacts.fallback),
          reason: 'letter $letter must have its own fact',
        );
        expect(fact.length, greaterThanOrEqualTo(15));
      }
    });

    test('at least 30 curated numbers have facts with real content', () {
      final List<int> curated = <int>[];
      for (int n = 1; n <= 100; n++) {
        if (FunFacts.forNumber(n) != null) curated.add(n);
      }
      expect(curated.length, greaterThanOrEqualTo(30));
      for (final int n in curated) {
        expect(
          FunFacts.forNumber(n)!.length,
          greaterThanOrEqualTo(15),
          reason: 'number $n fact should be a real sentence',
        );
      }
      // Core milestones are always present.
      expect(FunFacts.forNumber(1), isNotNull);
      expect(FunFacts.forNumber(20), isNotNull);
      expect(FunFacts.forNumber(100), isNotNull);
    });

    test('falls back politely for unknown numbers', () {
      expect(FunFacts.forNumber(73), isNull);
    });
  });
}