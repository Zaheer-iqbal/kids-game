import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids/core/di/injection_container.dart' as di;
import 'package:kids/core/mascot/mascot_cubit.dart';
import 'package:kids/core/mascot/mascot_mood.dart';
import 'package:kids/core/services/progress_service.dart';
import 'package:kids/core/settings/data/settings_repository_impl.dart';
import 'package:kids/core/tracing/trace_glyph.dart';
import 'package:kids/core/tracing/trace_model.dart';
import 'package:kids/core/widgets/emoji_picture.dart';
import 'package:kids/core/widgets/mascot_view.dart';
import 'package:kids/core/widgets/tracing_canvas.dart';
import 'package:kids/features/quiz/presentation/bloc/quiz_bloc.dart';
import 'package:kids/features/quiz/presentation/pages/quiz_page.dart';
import 'package:kids/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/frame_pump.dart';

/// Pump a fresh app with a clean (optionally pre-seeded) persistence store.
/// A tall surface guarantees the whole A–Z grid is built (no off-screen lazy
/// items). The intro is skipped by default; the real-async window lets the
/// splash handoff timer and engine-backed work (asset loading, glyph
/// rasterization) finish.
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

/// Simulates an app restart: fresh DI + fresh app instance on top of the same
/// persisted store.
Future<void> restartApp(WidgetTester tester) async {
  await di.sl.reset();
  await di.configureDependencies();
  await tester.runAsync(() async {
    await tester.pumpWidget(const SizedBox(key: Key('bootstrapped')));
    await tester.pumpWidget(const AlphabetKidsApp());
    await Future<void>.delayed(const Duration(milliseconds: 400));
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

/// Lets real (non-fake) async work finish, then settles the frame tree.
///
/// The frames stay in the fake-async zone: the celebration, retry prompt and
/// sheet animations of the alphabet flows only settle in fake time, so pumping
/// them from a real-async window leaves those timers unfinished.
Future<void> settleReal(WidgetTester tester,
    [Duration wait = const Duration(milliseconds: 250)]) async {
  await tester.runAsync(() => Future<void>.delayed(wait));
  await settleFrames(tester);
}

/// After triggering navigation or a sheet that kicks off engine IO (asset
/// loads, glyph rasterization) drive one frame so the work starts, then let
/// the real work finish before settling.
Future<void> openAndSettle(WidgetTester tester,
    [Duration wait = const Duration(milliseconds: 250)]) async {
  await tester.pump();
  await settleReal(tester, wait);
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

void main() {
  group('1. Alphabet home screen', () {
    testWidgets('loads directly (no auth) with the full A–Z grid', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      expect(find.text('Play Quiz'), findsOneWidget);
      expect(find.text('0 of 26 letters explored'), findsOneWidget);

      await openWorld(tester, 'Alphabet Land');

      for (int i = 0; i < 26; i++) {
        final String letter = String.fromCharCode(65 + i);
        expect(
          find.byKey(ValueKey<String>('letter-$letter')),
          findsOneWidget,
          reason: 'letter card $letter should be rendered',
        );
      }
    });

    testWidgets(
      'tapping a letter opens the detail sheet, stays TTS-safe, and marks it explored',
      (WidgetTester tester) async {
        await pumpApp(tester);

        await openWorld(tester, 'Alphabet Land');

        await tester.tap(find.byKey(const ValueKey<String>('letter-A')));
        await openAndSettle(tester);

        // Bottom overlay for the letter is shown.
        expect(find.text('A for Apple'), findsOneWidget);
        expect(find.text('Hear again'), findsOneWidget);
        expect(find.byType(TracingCanvas), findsOneWidget);

        // No missing-asset error sentinel should ever appear.
        expect(find.textContaining('Unable to load asset'), findsNothing);

        // Bug 4: "Hear again" replays reliably on every tap (repeated fast
        // taps must not crash or throw).
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.text('Hear again'));
          await tester.pump(const Duration(milliseconds: 120));
        }
        await settleFrames(tester);
        expect(find.text('A for Apple'), findsOneWidget);

        // Close the sheet.
        await tester.tap(find.byTooltip('Close'));
        await settleFrames(tester);

        // The letter is now explored: header count, star badge, persisted.
        expect(find.text('1 of 26 letters explored'), findsOneWidget);
        final Finder cardA = find.byKey(const ValueKey<String>('letter-A'));
        expect(
          find.descendant(
            of: cardA,
            matching: find.byIcon(Icons.star_rounded),
          ),
          findsOneWidget,
        );
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getStringList('explored_letters'), contains('A'));
      },
    );

    testWidgets('reopening app restores explored letters from storage', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, prefs: <String, Object>{
        'explored_letters': <String>['B', 'C'],
      });

      await openWorld(tester, 'Alphabet Land');

      expect(find.text('2 of 26 letters explored'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('letter-B')),
          matching: find.byIcon(Icons.star_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<String>('letter-C')),
          matching: find.byIcon(Icons.star_rounded),
        ),
        findsOneWidget,
      );
    });
  });

  group('2. Letter tracing', () {
    /// Waits until the glyph is rasterized, then drags a finger along the real
    /// target points the tracer expects, so the test never has to guess where
    /// the letter sits on screen.
    Future<List<Offset>> traceRealGlyph(
      WidgetTester tester,
      Finder canvas, {
      bool complete = true,
    }) async {
      await settleReal(tester, const Duration(milliseconds: 700));
      // The indeterminate spinner (the "still rasterizing" placeholder) must be
      // gone; the progress badge's own ring is a determinate indicator.
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is CircularProgressIndicator && w.value == null,
        ),
        findsNothing,
        reason: 'the glyph mask and guide must be ready',
      );

      final TracingCanvasState state = tester.state<TracingCanvasState>(canvas);
      final TraceModel model = state.model!;
      final Rect rect = tester.getRect(canvas);
      expect(model.totalTargets, greaterThanOrEqualTo(150));

      final List<Offset> all = model.glyph.targets
          .map((TraceTarget t) => rect.topLeft + t.point)
          .toList();
      // Skipping every 40th target leaves a partial trace that is clearly not
      // finished; taking every target walks the whole letter.
      final List<Offset> path = <Offset>[
        for (int i = 0; i < all.length; i++)
          if (complete || i % 40 == 0) all[i],
      ];

      final TestGesture stroke = await tester.startGesture(path.first);
      Offset previous = path.first;
      for (final Offset point in path.skip(1)) {
        // Interpolate so the stroke is continuous like a real finger.
        for (int step = 1; step <= 3; step++) {
          await stroke.moveTo(Offset.lerp(previous, point, step / 3)!);
          await tester.pump();
        }
        previous = point;
      }
      await stroke.up();
      await tester.pump();
      return path;
    }

    testWidgets(
      'renders the dotted guide and completes on a full correct trace with a celebration',
      (WidgetTester tester) async {
        await pumpApp(tester);

        await openWorld(tester, 'Alphabet Land');

        await tester.tap(find.byKey(const ValueKey<String>('letter-S')));
        await openAndSettle(tester, const Duration(milliseconds: 600));

        final Finder canvas = find.byType(TracingCanvas);
        expect(canvas, findsOneWidget);

        // Progress badge starts at 0%.
        expect(find.text('0%'), findsOneWidget);

        // A partial sweep of the letter must move the badge off 0% without
        // completing, proving strokes reach the tracer.
        await traceRealGlyph(tester, canvas, complete: false);
        expect(find.text('0%'), findsNothing,
            reason: 'tracing progress must leave 0% after strokes');
        expect(find.text('Great job!'), findsNothing);
        final String midPercent =
            (tester.widget<Text>(find.textContaining('%')).data!);
        final int midValue = int.parse(midPercent.replaceAll('%', '').trim());
        expect(midValue, greaterThan(0));

        // Continue over the whole letter: coverage and accuracy are met, so
        // the trace completes, confetti shows and Pip says "Great job!".
        await traceRealGlyph(tester, canvas, complete: true);
        expect(find.text('Great job!'), findsWidgets);

        // The star is only earned once the thresholds are met.
        expect(find.text('Traced!'), findsOneWidget);

        // Let the confetti run out and the overlay's 2s auto-dismiss fire so
        // the test ends cleanly.
        await settleReal(tester);
        await tester.pump(const Duration(milliseconds: 2200));
        await settleFrames(tester);
      },
    );

    testWidgets('a scribble away from the letter never completes the trace', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await openWorld(tester, 'Alphabet Land');
      await tester.tap(find.byKey(const ValueKey<String>('letter-S')));
      await openAndSettle(tester, const Duration(milliseconds: 600));
      final Finder canvas = find.byType(TracingCanvas);
      await settleReal(tester, const Duration(milliseconds: 700));

      final Rect rect = tester.getRect(canvas);
      // Scrub back and forth through the empty top strip of the canvas.
      final TestGesture scribble =
          await tester.startGesture(Offset(rect.left + 12, rect.top + 6));
      for (int row = 0; row < 12; row++) {
        for (double x = rect.left + 12; x < rect.right - 12; x += 10) {
          await scribble.moveTo(Offset(x, rect.top + 6 + row * 3));
          await tester.pump();
        }
      }
      await scribble.up();
      await tester.pump();
      await settleFrames(tester);

      expect(find.text('Great job!'), findsNothing);
      expect(find.text('Traced!'), findsNothing);
      expect(
        tester.state<TracingCanvasState>(canvas).model!.isComplete,
        isFalse,
        reason: 'a scribble outside the glyph must not complete the trace',
      );
    });

    testWidgets('Try again clears the progress and starts over', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await openWorld(tester, 'Alphabet Land');
      await tester.tap(find.byKey(const ValueKey<String>('letter-S')));
      await openAndSettle(tester, const Duration(milliseconds: 600));
      final Finder canvas = find.byType(TracingCanvas);
      await traceRealGlyph(tester, canvas, complete: false);

      await tester.tap(find.text('Try again'));
      await settleFrames(tester);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Traced!'), findsNothing);
    });
  });

  group('3. Quiz mode', () {
    testWidgets(
      'Letter Sounds mode: asks a question, correct tap scores + celebrates, wrong tap prompts retry',
      (WidgetTester tester) async {
        await pumpApp(tester);

        // Home -> Quiz menu -> Letter Sounds.
        await tester.tap(find.text('Play Quiz'));
        await openAndSettle(tester);
        expect(find.text('Choose a Quiz!'), findsOneWidget);
        await tester.tap(find.text('Letter Sounds'));
        await openAndSettle(tester);

        expect(find.text('Question 1 of 10'), findsOneWidget);
        expect(find.text('Tap the picture this sound says!'), findsOneWidget);

        final QuizBloc bloc =
            BlocProvider.of<QuizBloc>(tester.element(find.byType(QuizView)));
        final String target = bloc.state.targetKey!;
        final List<String> letters =
            bloc.state.options.map((option) => option.key).toList();
        expect(letters.length, 4);
        // Bug 2: every option must render its emoji picture.
        expect(find.byType(EmojiPicture), findsNWidgets(4));
        for (final String l in letters) {
          expect(
            find.descendant(
              of: find.byKey(ValueKey<String>('option-$l')),
              matching: find.byType(EmojiPicture),
            ),
            findsOneWidget,
          );
        }
        // Option pictures must be unique (no duplicate emoji leak through).
        final Set<String> emoji =
            bloc.state.options.map((option) => option.emoji).toSet();
        expect(emoji.length, 4, reason: 'all four options show distinct emoji');
        final String wrong = letters.firstWhere((String l) => l != target);

        // -- Wrong tap: gentle retry prompt, no score change.
        await tester.tap(find.byKey(ValueKey<String>('option-$wrong')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(bloc.state.score, 0);
        expect(bloc.state.wrongOption, wrong);
        expect(find.text('Oops! Give it another try!'), findsOneWidget);
        expect(find.text('Correct! +1'), findsNothing);

        // Let the shake animation finish.
        await tester.pump(const Duration(milliseconds: 400));

        // -- Correct tap: score up + celebration overlay.
        await tester.tap(find.byKey(ValueKey<String>('option-$target')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(bloc.state.score, 1);
        expect(bloc.state.revealCorrect, isTrue);
        expect(find.text('Correct! +1'), findsOneWidget);

        // The retry prompt must be gone once answered (AnimatedSwitcher has a
        // short exit transition, so settle past it).
        await settleFrames(tester);
        expect(find.text('Oops! Give it another try!'), findsNothing);

        // Auto-advance fires while confetti plays out (~1.3s); the overlay
        // auto-dismisses at 2s. Drive past both.
        await tester.pump(const Duration(milliseconds: 900));
        await settleFrames(tester);
        await tester.pump(const Duration(milliseconds: 800)); // dismiss overlay
        await settleFrames(tester);
        expect(find.text('Question 2 of 10'), findsOneWidget);

        // Score (and high score) persisted.
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('quiz_high_score'), 1);
        expect(di.sl<ProgressService>().quizHighScore, greaterThanOrEqualTo(1));
      },
    );
  });

  group('4. Progress persistence across restart', () {
    testWidgets(
      'explored letters and high score survive a simulated restart',
      (WidgetTester tester) async {
        await pumpApp(tester, prefs: <String, Object>{
          'explored_letters': <String>['A', 'D', 'G'],
          'quiz_high_score': 7,
        });
        expect(find.text('3 of 26 letters explored'), findsOneWidget);
        expect(di.sl<ProgressService>().quizHighScore, 7);

        // Restart the app on the same persisted store.
        await restartApp(tester);

        expect(find.text('3 of 26 letters explored'), findsOneWidget);
        expect(di.sl<ProgressService>().quizHighScore, 7);
        expect(find.text('Play Quiz'), findsOneWidget);
      },
    );

    testWidgets(
      'letters explored during the session persist when app restarts',
      (WidgetTester tester) async {
        await pumpApp(tester);

        await openWorld(tester, 'Alphabet Land');

        // Explore letters M and Z (Z only exists now because grid is fully
        // visible on the tall test surface).
        await tester.tap(find.byKey(const ValueKey<String>('letter-M')));
        await openAndSettle(tester);
        await tester.tap(find.byTooltip('Close'));
        await settleFrames(tester);

        await tester.tap(find.byKey(const ValueKey<String>('letter-Z')));
        await openAndSettle(tester);
        await tester.tap(find.byTooltip('Close'));
        await settleFrames(tester);

        expect(find.text('2 of 26 letters explored'), findsOneWidget);

        await restartApp(tester);

        await openWorld(tester, 'Alphabet Land');

        expect(find.text('2 of 26 letters explored'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('letter-Z')),
            matching: find.byIcon(Icons.star_rounded),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('5. Grown-up settings screen', () {
    /// The switches, in the order the screen lists them. "Reduce motion" is
    /// the one switch that starts off (motion fully on is the default).
    const List<String> switchTitles = <String>[
      'Mascot animations',
      'Sparkle surprises',
      'Mascot voice',
      'Sound effects',
      'Voice narration',
      'Reduce motion',
    ];

    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Grown-up settings'));
      await openAndSettle(tester);
    }

    testWidgets('opens from home, previews the mascot and goes back', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);

      await openSettings(tester);

      expect(find.text('Grown-up Settings'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(switchTitles.length));
      for (final String title in switchTitles) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.byType(MascotView), findsOneWidget,
          reason: 'a parent can see the mascot they are configuring');
      final List<Switch> toggles =
          tester.widgetList<Switch>(find.byType(Switch)).toList();
      for (final Switch toggle in toggles.take(switchTitles.length - 1)) {
        expect(toggle.value, isTrue, reason: 'everything starts switched on');
      }
      expect(
        toggles.last.value,
        isFalse,
        reason: 'reduce motion starts off so the app is lively by default',
      );

      // Tapping Pip on the preview screen makes him react right there.
      await tester.tap(find.byType(MascotView));
      await settleFrames(tester);
      expect(di.sl<MascotCubit>().state.mood, MascotMood.idle);
      expect(di.sl<MascotCubit>().state.message, isIn(mascotGiggles));

      await tester.tap(find.byTooltip('Back to home'));
      await openAndSettle(tester);
      expect(find.text('Grown-up Settings'), findsNothing);
      expect(find.text('Play Quiz'), findsOneWidget);
    });

    testWidgets('a switch is saved and honoured after a restart', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await openSettings(tester);

      await tester.tap(find.byType(Switch).at(1));
      await settleFrames(tester);
      expect(tester.widget<Switch>(find.byType(Switch).at(1)).value, isFalse);

      final SharedPreferences store = await SharedPreferences.getInstance();
      expect(store.getBool(SettingsRepositoryImpl.sparklesKey), isFalse);

      await restartApp(tester);
      await openSettings(tester);

      expect(
        tester.widget<Switch>(find.byType(Switch).at(1)).value,
        isFalse,
        reason: 'a parent should not have to set the same switch twice',
      );
      expect(find.text('A few twinkles now and then on a card.'), findsOneWidget);
    });

    testWidgets('the mascot voice switch silences Pip for good', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await openSettings(tester);

      await tester.tap(find.byType(Switch).at(2));
      await settleFrames(tester);
      expect(find.text('Pip is quiet right now.'), findsOneWidget);

      await restartApp(tester);
      await openSettings(tester);

      expect(tester.widget<Switch>(find.byType(Switch).at(2)).value, isFalse);
      expect(find.text('Pip is quiet right now.'), findsOneWidget);
    });

    testWidgets('turn everything back on restores the defaults', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, prefs: <String, Object>{
        SettingsRepositoryImpl.animationsKey: false,
        SettingsRepositoryImpl.sparklesKey: false,
        SettingsRepositoryImpl.speechKey: false,
        SettingsRepositoryImpl.soundKey: false,
        SettingsRepositoryImpl.voiceKey: false,
      });
      await openSettings(tester);

      for (final Switch toggle in tester.widgetList<Switch>(find.byType(Switch))) {
        expect(toggle.value, isFalse);
      }

      await tester.tap(find.text('Turn everything back on'));
      await settleFrames(tester);

      final List<Switch> toggles =
          tester.widgetList<Switch>(find.byType(Switch)).toList();
      // Every delight switch is on again...
      for (final Switch toggle in toggles.take(switchTitles.length - 1)) {
        expect(toggle.value, isTrue);
      }
      // ...and "reduce motion" returns to its default (off = full motion on).
      expect(toggles.last.value, isFalse);

      final SharedPreferences store = await SharedPreferences.getInstance();
      expect(store.getBool(SettingsRepositoryImpl.animationsKey), isTrue);
      expect(store.getBool(SettingsRepositoryImpl.sparklesKey), isTrue);
      expect(store.getBool(SettingsRepositoryImpl.speechKey), isTrue);
      expect(store.getBool(SettingsRepositoryImpl.soundKey), isTrue);
      expect(store.getBool(SettingsRepositoryImpl.voiceKey), isTrue);
      expect(store.getBool(SettingsRepositoryImpl.reduceMotionKey), isFalse);
    });

    testWidgets('the reduce motion switch turns motion off and stays off', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester);
      await openSettings(tester);

      // It is the last switch and starts off, so the app is lively by default.
      Finder reduceMotion = find.byType(Switch).last;
      expect(tester.widget<Switch>(reduceMotion).value, isFalse);

      await tester.tap(reduceMotion);
      await settleFrames(tester);
      expect(tester.widget<Switch>(find.byType(Switch).last).value, isTrue);

      final SharedPreferences store = await SharedPreferences.getInstance();
      expect(store.getBool(SettingsRepositoryImpl.reduceMotionKey), isTrue);

      // A parent should not have to set it again after a restart.
      await restartApp(tester);
      await openSettings(tester);
      reduceMotion = find.byType(Switch).last;
      expect(tester.widget<Switch>(reduceMotion).value, isTrue);
    });
  });
}