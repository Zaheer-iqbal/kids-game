import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids/core/theme/app_colors.dart';
import 'package:kids/core/widgets/emoji_picture.dart';
import 'package:kids/features/alphabet/data/models/letter_model.dart';
import 'package:kids/features/numbers/presentation/widgets/count_objects.dart';

/// The letter list the app promises: one word and one emoji per letter.
const Map<String, (String, String)> expectedLetters = <String, (String, String)>{
  'A': ('Apple', '🍎'),
  'B': ('Ball', '⚽'),
  'C': ('Cat', '🐱'),
  'D': ('Dog', '🐶'),
  'E': ('Elephant', '🐘'),
  'F': ('Fish', '🐟'),
  'G': ('Goat', '🐐'),
  'H': ('Hat', '🎩'),
  'I': ('Ice Cream', '🍦'),
  'J': ('Juice', '🧃'),
  'K': ('Kite', '🪁'),
  'L': ('Lion', '🦁'),
  'M': ('Monkey', '🐵'),
  'N': ('Nest', '🪺'),
  'O': ('Orange', '🍊'),
  'P': ('Parrot', '🦜'),
  'Q': ('Queen', '👑'),
  'R': ('Rabbit', '🐰'),
  'S': ('Sun', '☀️'),
  'T': ('Tiger', '🐯'),
  'U': ('Umbrella', '☂️'),
  'V': ('Van', '🚐'),
  'W': ('Watch', '⌚'),
  'X': ('Xylophone', '🎼'),
  'Y': ('Yarn', '🧶'),
  'Z': ('Zebra', '🦓'),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('alphabet.json', () {
    late List<LetterModel> letters;

    setUpAll(() async {
      final String raw = await rootBundle.loadString('assets/data/alphabet.json');
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      letters = decoded
          .map((dynamic e) => LetterModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    test('covers A-Z exactly once, in order', () {
      expect(letters.length, 26);
      expect(
        letters.map((LetterModel l) => l.letter).toList(),
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''),
      );
    });

    test('every letter has the promised word and emoji', () {
      for (final LetterModel letter in letters) {
        final (String word, String emoji) = expectedLetters[letter.letter]!;
        expect(letter.word, word, reason: '${letter.letter} word');
        expect(letter.emoji, emoji, reason: '${letter.letter} emoji');
      }
    });

    test('no two letters share an emoji', () {
      final Set<String> emoji = letters.map((LetterModel l) => l.emoji).toSet();
      expect(emoji.length, 26);
    });

    test('every emoji is a real emoji, never a placeholder glyph', () {
      for (final LetterModel letter in letters) {
        expect(letter.emoji.runes.length, greaterThan(0));
        expect(
          letter.emoji.codeUnitAt(0),
          anyOf(greaterThan(0x2000), 0x2600),
          reason: '${letter.letter} should be an emoji',
        );
      }
    });
  });

  group('EmojiPicture', () {
    testWidgets('renders the emoji as text on a tinted tile', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: EmojiPicture(emoji: '🍎', color: Color(0xFFFFB199)),
            ),
          ),
        ),
      );

      expect(find.text('🍎'), findsOneWidget);
      expect(find.byType(FittedBox), findsWidgets);
    });

    testWidgets('tint: false paints only the glyph', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: EmojiPicture(emoji: '⭐', tint: false),
            ),
          ),
        ),
      );

      expect(find.text('⭐'), findsOneWidget);
      expect(find.byType(DecoratedBox), findsNothing);
    });
  });

  group('CountObjects', () {
    Future<void> pump(WidgetTester tester, int count) => tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CountObjects(count: count, emoji: '🍎', color: AppColors.gold),
            ),
          ),
        );

    testWidgets('draws one emoji per object', (WidgetTester tester) async {
      await pump(tester, 1);
      expect(find.text('🍎'), findsOneWidget);

      await pump(tester, 10);
      expect(find.text('🍎'), findsNWidgets(10));
    });

    testWidgets('lays bigger numbers out as ten-frames', (
      WidgetTester tester,
    ) async {
      await pump(tester, 23);

      expect(find.text('🍎'), findsNWidgets(23));
      // Three frames: 10 + 10 + 3, each scrollable rather than overflowing.
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stops at one hundred objects, scrollable', (
      WidgetTester tester,
    ) async {
      await pump(tester, 250);

      expect(find.text('🍎'), findsNWidgets(kMaxCountedObjects));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty count draws nothing', (WidgetTester tester) async {
      await pump(tester, 0);
      expect(find.text('🍎'), findsNothing);
    });
  });
}
