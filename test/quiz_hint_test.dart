import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids/core/di/injection_container.dart' as di;
import 'package:kids/features/quiz/domain/entities/quiz_option.dart';
import 'package:kids/features/quiz/presentation/bloc/quiz_bloc.dart';
import 'package:kids/features/quiz/presentation/bloc/quiz_state.dart';
import 'package:kids/features/quiz/presentation/pages/quiz_page.dart';
import 'package:kids/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/frame_pump.dart';

Future<void> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{'intro_seen': true});
  await di.sl.reset();
  await di.configureDependencies();

  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.runAsync(() async {
    await tester.pumpWidget(const AlphabetKidsApp());
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await rootBundle.loadString('assets/data/alphabet.json');
    await rootBundle.loadString('assets/data/numbers.json');
  });
  await settleFrames(tester, frames: 20);
  for (int i = 0; i < 20 && find.text('Play Quiz').evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await settleFrames(tester, frames: 20);
  }
}

Future<void> openAndSettle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 250)),
  );
  await settleFrames(tester);
}

QuizOption _option(String key) => QuizOption(
      key: key,
      displayText: key,
      hintText: key,
      emoji: '🍎',
      colorValue: 0,
      style: QuizOptionStyle.picture,
    );

void main() {
  group('QuizState.canHint guardrails', () {
    List<QuizOption> options(int n) =>
        List<QuizOption>.generate(n, (int i) => _option(String.fromCharCode(65 + i)));

    test('enabled on a ready four-option round', () {
      final QuizState state = QuizState(
        status: QuizStatus.ready,
        options: options(4),
        targetKey: 'A',
      );
      expect(state.canHint, isTrue);
    });

    test('never offered on an easy two-option round', () {
      final QuizState state = QuizState(
        status: QuizStatus.ready,
        options: options(2),
        targetKey: 'A',
      );
      expect(state.canHint, isFalse);
    });

    test('stops once two hints are spent', () {
      final QuizState state = QuizState(
        status: QuizStatus.ready,
        options: options(4),
        targetKey: 'A',
        hintsUsed: QuizState.maxHintsPerQuestion,
      );
      expect(state.canHint, isFalse);
    });

    test('not offered while the correct answer is being revealed', () {
      final QuizState state = QuizState(
        status: QuizStatus.ready,
        options: options(4),
        targetKey: 'A',
        revealCorrect: true,
      );
      expect(state.canHint, isFalse);
    });
  });

  group('Quiz hint owl', () {
    testWidgets(
      'gives exactly two hints, each hiding a wrong option; no hints left after',
      (WidgetTester tester) async {
        await pumpApp(tester);

        await tester.tap(find.text('Play Quiz'));
        await openAndSettle(tester);
        await tester.tap(find.text('Letter Sounds'));
        await openAndSettle(tester);

        final QuizBloc bloc =
            BlocProvider.of<QuizBloc>(tester.element(find.byType(QuizView)));
        expect(bloc.state.options.length, 4);
        final String target = bloc.state.targetKey!;

        final Finder owl = find.byKey(const ValueKey<String>('quiz-hint-owl'));
        expect(owl, findsOneWidget);

        // First hint: one wrong option goes.
        await tester.tap(owl);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(bloc.state.hintsUsed, 1);
        expect(bloc.state.hiddenKeys.length, 1);
        expect(bloc.state.hiddenKeys, isNot(contains(target)));
        expect(bloc.state.hintMessage, isNotNull);

        // Second hint.
        await tester.tap(owl);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(bloc.state.hintsUsed, 2);
        expect(bloc.state.hiddenKeys.length, 2);
        expect(bloc.state.hiddenKeys, isNot(contains(target)));

        // A hidden wrong option can no longer be tapped.
        final String hidden = bloc.state.hiddenKeys.first;
        await tester.tap(find.byKey(ValueKey<String>('option-$hidden')));
        await tester.pump();
        expect(bloc.state.wrongOption, isNull);
        expect(bloc.state.score, 0);

        // Third tap is a no-op and the owl tells the child there are no more.
        await tester.tap(owl);
        await tester.pump();
        expect(bloc.state.hintsUsed, 2);
        expect(find.text('No hints left!'), findsOneWidget);
      },
    );

    testWidgets('hints reset on the next question', (WidgetTester tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Play Quiz'));
      await openAndSettle(tester);
      await tester.tap(find.text('Letter Sounds'));
      await openAndSettle(tester);

      final QuizBloc bloc =
          BlocProvider.of<QuizBloc>(tester.element(find.byType(QuizView)));

      await tester.tap(find.byKey(const ValueKey<String>('quiz-hint-owl')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(bloc.state.hintsUsed, 1);

      // Answer correctly and let the quiz advance.
      await tester.tap(
        find.byKey(ValueKey<String>('option-${bloc.state.targetKey}')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await settleFrames(tester);
      await tester.pump(const Duration(milliseconds: 900));
      await settleFrames(tester);
      await tester.pump(const Duration(milliseconds: 800));
      await settleFrames(tester);

      expect(find.text('Question 2 of 10'), findsOneWidget);
      expect(bloc.state.hintsUsed, 0);
      expect(bloc.state.hiddenKeys, isEmpty);
    });
  });
}
