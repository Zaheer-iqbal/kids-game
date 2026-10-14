import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kids/core/di/injection_container.dart' as di;
import 'package:kids/core/services/progress_service.dart';
import 'package:kids/features/quiz/domain/entities/quiz_option.dart';
import 'package:kids/features/quiz/presentation/bloc/quiz_bloc.dart';
import 'package:kids/features/quiz/presentation/pages/quiz_page.dart';
import 'package:kids/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/frame_pump.dart';

Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'intro_seen': true,
    ...prefs,
  });
  await di.sl.reset();
  await di.configureDependencies();

  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.runAsync(() async {
    await tester.pumpWidget(const AlphabetKidsApp());
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Warm the engine-backed asset cache so explorer loads resolve reliably
    // even when a world is opened in a later test of the same file.
    await rootBundle.loadString('assets/data/alphabet.json');
    await rootBundle.loadString('assets/data/numbers.json');
  });
  await settleFrames(tester, frames: 20);
  for (int i = 0;
      i < 20 && find.text('Play Quiz').evaluate().isEmpty;
      i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await settleFrames(tester, frames: 20);
  }
}

/// From the adventure map, opens a world's explorer by tapping its banner and
/// waits until its grid is actually on screen (the explorer loads letters /
/// numbers through real-async asset IO, which needs real time to finish).
Future<void> openWorld(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pump();
  final bool isAlphabet = title == 'Alphabet Land';
  for (int i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await settleFrames(tester);
    final bool ready = isAlphabet
        ? find.byKey(const ValueKey<String>('letter-A')).evaluate().isNotEmpty
        : find.byKey(const ValueKey<String>('number-1')).evaluate().isNotEmpty;
    if (ready) return;
  }
  tester.takeException();
}

/// Lazy work in real async zones (rootBundle loads, glyph rasterization) needs
/// engine turns injected between fake-frame pumps, so here the frames run inside
/// the real-async window too. The number detail sheet rasterizes a large set of
/// images while it is being pumped, which never completes otherwise.
Future<void> settleReal(WidgetTester tester,
    [Duration wait = const Duration(milliseconds: 250)]) async {
  await tester.runAsync(() => Future<void>.delayed(wait));
  await tester.runAsync(() => settleFrames(tester));
}

Future<void> openAndSettle(WidgetTester tester,
    [Duration wait = const Duration(milliseconds: 250)]) async {
  await tester.pump();
  await settleReal(tester, wait);
}

/// Home -> Quiz menu -> the [modeLabel] card -> the quiz itself.
Future<void> startQuizMode(WidgetTester tester, String modeLabel) async {
  await tester.tap(find.text('Play Quiz'));
  await openAndSettle(tester);
  await tester.tap(find.text(modeLabel));
  await openAndSettle(tester);
}

/// Answers the current round correctly and lets the celebration + auto-advance
/// finish so the next question is on screen.
Future<void> answerCorrectAndAdvance(WidgetTester tester) async {
  final QuizBloc bloc =
      BlocProvider.of<QuizBloc>(tester.element(find.byType(QuizView)));
  await tester.tap(find.byKey(ValueKey<String>('option-${bloc.state.targetKey}')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(bloc.state.score, 1);
  expect(bloc.state.revealCorrect, isTrue);
  expect(find.text('Correct! +1'), findsOneWidget);

  await settleFrames(tester);
  await tester.pump(const Duration(milliseconds: 900));
  await settleFrames(tester);
  await tester.pump(const Duration(milliseconds: 800)); // dismiss overlay
  await settleFrames(tester);
}

void main() {
  group('Numbers module', () {
    testWidgets('Numbers tab loads the 1–100 grid with progress', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await openWorld(tester, 'Number World');

      expect(find.text('0 of 100 numbers explored'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('number-1')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('number-2')), findsOneWidget);
      expect(find.text('123 Count'), findsOneWidget);
    });

    testWidgets(
      'tapping a number opens its sheet, stays TTS-safe, and marks it explored',
      (WidgetTester tester) async {
        await pumpApp(tester);

        await openWorld(tester, 'Number World');
        await tester.tap(find.byKey(const ValueKey<String>('number-1')));
        await openAndSettle(tester);

        expect(find.text('1 – One'), findsOneWidget);
        expect(find.text('Hear again'), findsOneWidget);
        expect(find.text('Fun fact!'), findsOneWidget);
        expect(find.text('Hear fun fact'), findsOneWidget);

        // Replay sound reliably on every tap (TTS-safe).
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.text('Hear again'));
          await tester.pump(const Duration(milliseconds: 120));
        }
        await settleFrames(tester);

        await tester.tap(find.byTooltip('Close'));
        await settleFrames(tester);

        expect(find.text('1 of 100 numbers explored'), findsOneWidget);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getStringList('explored_numbers'), contains('1'));
      },
    );

    testWidgets('number detail sheet shows real, original fun fact content', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await openWorld(tester, 'Number World');
      await tester.tap(find.byKey(const ValueKey<String>('number-5')));
      await openAndSettle(tester);

      expect(find.textContaining('five fingers'), findsOneWidget);
    });
  });

  group('Fun facts on letters', () {
    testWidgets('letter sheet shows the fun fact bubble with hear button', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await openWorld(tester, 'Alphabet Land');

      await tester.tap(find.byKey(const ValueKey<String>('letter-A')));
      await openAndSettle(tester);

      expect(find.text('Fun fact!'), findsOneWidget);
      expect(find.text('Hear fun fact'), findsOneWidget);
      expect(find.textContaining('Ants'), findsOneWidget);
    });
  });

  group('Standalone numbers route', () {
    testWidgets('/numbers renders the numbers screen directly', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      final BuildContext ctx = tester.element(find.byType(Scaffold).first);
      GoRouter.of(ctx).go('/numbers');
      await openAndSettle(tester);

      expect(find.text('123 Count'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('number-10')), findsOneWidget);
    });
  });

  group('Extra quiz modes', () {
    testWidgets('Number Match hears a number and picks the numeral', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await startQuizMode(tester, 'Number Match');

      expect(find.text('Question 1 of 10'), findsOneWidget);
      expect(find.text('Tap the number you hear!'), findsOneWidget);

      final QuizBloc bloc =
          BlocProvider.of<QuizBloc>(tester.element(find.byType(QuizView)));
      expect(bloc.state.options.length, 4);
      expect(
        bloc.state.options.every(
          (QuizOption o) => o.style == QuizOptionStyle.numeral,
        ),
        isTrue,
        reason: 'Number Match options must be drawn as numerals',
      );

      await answerCorrectAndAdvance(tester);
      expect(find.text('Question 2 of 10'), findsOneWidget);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt('quiz_best_scores.numberMatch'),
        1,
        reason: 'per-mode best also recorded',
      );
    });

    testWidgets('Fun Facts Trivia reads a fact and asks who it is about', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await startQuizMode(tester, 'Fun Facts Trivia');

      expect(find.text('Question 1 of 10'), findsOneWidget);
      expect(find.text('Who am I? Listen to my fun fact!'), findsOneWidget);

      final QuizBloc bloc =
          BlocProvider.of<QuizBloc>(tester.element(find.byType(QuizView)));
      expect(bloc.state.options.length, 4);
      expect(bloc.state.spokenPrompt, isNotNull);
      expect(bloc.state.spokenPrompt!.isNotEmpty, isTrue);

      await answerCorrectAndAdvance(tester);
      expect(find.text('Question 2 of 10'), findsOneWidget);
    });

    testWidgets('Odd One Out asks which picture does not belong', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await startQuizMode(tester, 'Odd One Out');

      expect(find.text('Question 1 of 10'), findsOneWidget);
      expect(find.text("Which one doesn't belong?"), findsOneWidget);

      final QuizBloc bloc =
          BlocProvider.of<QuizBloc>(tester.element(find.byType(QuizView)));
      expect(bloc.state.options.length, 4);
      expect(bloc.state.targetKey, isNotNull);

      await answerCorrectAndAdvance(tester);
      expect(find.text('Question 2 of 10'), findsOneWidget);
    });
  });

  group('Numbers persistence across restart', () {
    testWidgets('explored numbers survive a simulated restart', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, prefs: <String, Object>{
        'explored_numbers': <String>['7', '12'],
      });

      await openWorld(tester, 'Number World');
      expect(find.text('2 of 100 numbers explored'), findsOneWidget);
      expect(find.text('123 Count'), findsOneWidget);

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('explored_numbers'), contains('7'));
      expect(di.sl<ProgressService>().exploredNumberCount, 2);
    });
  });
}