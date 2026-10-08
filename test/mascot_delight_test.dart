import 'dart:math';
import 'dart:ui' show Canvas, PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids/core/mascot/mascot_cubit.dart';
import 'package:kids/core/mascot/mascot_mood.dart';
import 'package:kids/core/mascot/mascot_state.dart';
import 'package:kids/core/services/audio_service.dart';
import 'package:kids/core/settings/data/settings_repository_impl.dart';
import 'package:kids/core/settings/presentation/settings_cubit.dart';
import 'package:kids/core/widgets/delight_settings.dart';
import 'package:kids/core/widgets/mascot_painter.dart';
import 'package:kids/core/widgets/mascot_view.dart';
import 'package:kids/core/widgets/mascot_widget.dart';
import 'package:kids/core/widgets/sparkle_burst.dart';
import 'package:kids/core/widgets/sparkle_paint.dart';
import 'package:kids/core/widgets/tap_delight.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the platform TTS so these tests stay silent and fast.
class _SilentAudioService extends AudioService {
  @override
  Future<void> speakText(String text) async {}
}

typedef _Harness = ({MascotCubit mascot, SettingsCubit settings});

Future<_Harness> _buildCobits({
  Map<String, Object> prefs = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    SettingsRepositoryImpl.speechKey: false,
    ...prefs,
  });
  final SharedPreferences store = await SharedPreferences.getInstance();
  final SettingsCubit settings =
      SettingsCubit(repository: SettingsRepositoryImpl(store))..load();
  final MascotCubit mascot = MascotCubit(
    audioService: _SilentAudioService(),
    settingsCubit: settings,
    random: Random(4),
  );
  return (mascot: mascot, settings: settings);
}

Widget _app({required _Harness harness, required Widget child}) {
  return MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<MascotCubit>.value(value: harness.mascot),
      BlocProvider<SettingsCubit>.value(value: harness.settings),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: DelightScope(child: child),
        ),
      ),
    ),
  );
}

/// Largest uniform scale currently applied by a [TapDelight].
double _maxScale(WidgetTester tester) {
  double max = 0;
  for (final Element element in find.byType(Transform).evaluate()) {
    final Matrix4 matrix = (element.widget as Transform).transform;
    final bool uniform = matrix.entry(0, 1) == 0 &&
        matrix.entry(1, 0) == 0 &&
        matrix.entry(0, 3) == 0 &&
        matrix.entry(1, 3) == 0;
    if (uniform && matrix.entry(0, 0) > max) max = matrix.entry(0, 0);
  }
  return max;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MascotWidget drawing', () {
    testWidgets('every mood paints without an error', (
      WidgetTester tester,
    ) async {
      for (final MascotMood mood in MascotMood.values) {
        final PictureRecorder recorder = PictureRecorder();
        final Canvas canvas = Canvas(recorder);
        final AnimationController controller = AnimationController(
          vsync: tester,
          duration: const Duration(milliseconds: 100),
        )..value = 0.4;

        MascotPainter(
          animation: controller,
          mood: mood,
          reacting: mood.isReaction,
          giggling: false,
          palette: MascotPalette.owl,
        ).paint(canvas, const Size(200, 200));

        controller.dispose();
      }
    });

    testWidgets('the reacting and giggling poses also paint', (
      WidgetTester tester,
    ) async {
      for (final MascotMood mood in MascotMood.values) {
        for (final bool reacting in <bool>[true, false]) {
          for (final bool giggling in <bool>[true, false]) {
            final AnimationController controller = AnimationController(
              vsync: tester,
              duration: const Duration(milliseconds: 100),
            )..value = 0.75;
            MascotPainter(
              animation: controller,
              mood: mood,
              reacting: reacting,
              giggling: giggling,
            ).paint(Canvas(PictureRecorder()), const Size(140, 140));
            controller.dispose();
          }
        }
      }
    });

    testWidgets('the sparkle helpers draw on any canvas', (
      WidgetTester tester,
    ) async {
      final Canvas canvas = Canvas(PictureRecorder());
      final Paint paint = Paint()..color = const Color(0xFFFFC93C);

      paintSparkle(canvas, const Offset(20, 20), 10, paint);
      paintDot(canvas, const Offset(30, 30), 4, paint);

      expect(tester.takeException(), isNull);
    });
  });

  group('MascotView', () {
    testWidgets('starts as a calm, silent owl', (WidgetTester tester) async {
      final _Harness harness = await _buildCobits();
      await tester.pumpWidget(_app(harness: harness, child: const MascotView()));

      expect(find.byType(MascotWidget), findsOneWidget);
      expect(find.byType(Semantics), findsWidgets);
      expect(harness.mascot.state, const MascotState());
      expect(find.textContaining('Tap'), findsNothing);

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpWidget(const SizedBox.shrink());
      await harness.mascot.close();
      await harness.settings.close();
    });

    testWidgets('a reaction shows the line, plays, then settles back to idle',
        (WidgetTester tester) async {
      final _Harness harness = await _buildCobits();
      await tester.pumpWidget(_app(harness: harness, child: const MascotView()));

      harness.mascot.happy();
      await tester.pump();
      final String line = harness.mascot.state.message!;

      expect(find.text(line), findsOneWidget);
      expect(harness.mascot.state.isReacting, isTrue);

      // Still reacting halfway through, then the animation drives it home.
      await tester.pump(const Duration(milliseconds: 900));
      expect(harness.mascot.state.mood, MascotMood.happy);

      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump();
      expect(harness.mascot.state.mood, MascotMood.idle);
      expect(find.text(line), findsNothing);

      // The breathing loop must not keep re-settling over and over.
      await tester.pump(const Duration(seconds: 6));
      expect(harness.mascot.state.mood, MascotMood.idle);
      expect(harness.mascot.state.message, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await harness.mascot.close();
      await harness.settings.close();
    });

    testWidgets('a second identical reaction replays instead of freezing',
        (WidgetTester tester) async {
      final _Harness harness = await _buildCobits();
      await tester.pumpWidget(_app(harness: harness, child: const MascotView()));

      harness.mascot.happy();
      await tester.pump();
      expect(find.text(harness.mascot.state.message!), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      expect(harness.mascot.state.mood, MascotMood.idle);

      // Same mood, new token: the bubble comes back.
      harness.mascot.happy();
      await tester.pump();
      expect(find.text(harness.mascot.state.message!), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      expect(harness.mascot.state.mood, MascotMood.idle);

      await tester.pumpWidget(const SizedBox.shrink());
      await harness.mascot.close();
      await harness.settings.close();
    });

    testWidgets('tapping the owl makes it giggle without changing the mood',
        (WidgetTester tester) async {
      final _Harness harness = await _buildCobits();
      await tester.pumpWidget(_app(harness: harness, child: const MascotView()));

      harness.mascot.happy();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();

      await tester.tap(find.byType(MascotWidget));
      await tester.pump();

      expect(harness.mascot.state.mood, MascotMood.idle);
      expect(harness.mascot.state.message, isIn(mascotGiggles));
      expect(find.text(harness.mascot.state.message!), findsOneWidget);

      // The giggle is short, so it settles quickly too.
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump();
      expect(harness.mascot.state.message, isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await harness.mascot.close();
      await harness.settings.close();
    });

    testWidgets('the decorative celebration owl never speaks and never settles',
        (WidgetTester tester) async {
      final _Harness harness = await _buildCobits();
      await tester.pumpWidget(_app(
        harness: harness,
        child: const MascotWidget(mood: MascotMood.excited, size: 200),
      ));

      await tester.pump(const Duration(milliseconds: 2500));
      expect(tester.takeException(), isNull);
      expect(harness.mascot.state.mood, MascotMood.idle,
          reason: 'a bare widget has no cubit to settle');

      await tester.pumpWidget(const SizedBox.shrink());
      await harness.mascot.close();
      await harness.settings.close();
    });

    testWidgets('with animations off the owl holds a still pose and the bubble '
        'still clears', (WidgetTester tester) async {
      final _Harness harness = await _buildCobits(
        prefs: <String, Object>{SettingsRepositoryImpl.animationsKey: false},
      );
      await tester.pumpWidget(_app(harness: harness, child: const MascotView()));

      harness.mascot.excited();
      await tester.pump();

      final String line = harness.mascot.state.message!;
      expect(find.text(line), findsOneWidget,
          reason: 'the reaction still shows, it just does not move');

      // No controller runs, so the fallback timer has to clear the bubble.
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      expect(harness.mascot.state.mood, MascotMood.idle);
      expect(find.text(line), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await harness.mascot.close();
      await harness.settings.close();
    });
  });

  group('TapDelight', () {
    Widget card({required void Function() onTap, double sparkleChance = 0}) {
      return SizedBox(
        width: 120,
        height: 120,
        child: TapDelight(
          onTap: onTap,
          sparkleChance: sparkleChance,
          random: Random(1),
          child: const ColoredBox(color: Color(0xFF8F95F0)),
        ),
      );
    }

    testWidgets('a tap pops the card and it springs back to rest',
        (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(_app(
        harness: await _buildCobits(),
        child: card(onTap: () => taps++),
      ));

      expect(_maxScale(tester), 1.0);

      await tester.tap(find.byType(TapDelight));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(_maxScale(tester), greaterThan(1.0),
          reason: 'the card must be pressed in');

      await tester.pump(const Duration(milliseconds: 500));
      expect(_maxScale(tester), 1.0);
      expect(taps, 1, reason: 'the tap always reaches the card');

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a lucky tap sparkles, and again on the next lucky tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(
        harness: await _buildCobits(),
        child: card(onTap: () {}, sparkleChance: 1),
      ));

      expect(find.byType(SparkleBurst), findsNothing);

      await tester.tap(find.byType(TapDelight));
      await tester.pump();
      expect(find.byType(SparkleBurst), findsOneWidget);
      final SparkleBurst first =
          tester.widget<SparkleBurst>(find.byType(SparkleBurst));
      expect(first.seed, greaterThan(0));
      expect(tester.takeException(), isNull,
          reason: 'the burst must paint without an error');

      // Tapping the same card again replays the burst with a fresh layout.
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.tap(find.byType(TapDelight));
      await tester.pump();
      final SparkleBurst second =
          tester.widget<SparkleBurst>(find.byType(SparkleBurst));
      expect(second.seed, first.seed + 1);

      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('an unlucky tap never sparkles', (WidgetTester tester) async {
      await tester.pumpWidget(_app(
        harness: await _buildCobits(),
        child: card(onTap: () {}, sparkleChance: 0),
      ));

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(TapDelight));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
      }

      expect(find.byType(SparkleBurst), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a parent who turned sparkles off gets no burst',
        (WidgetTester tester) async {
      final _Harness harness = await _buildCobits();
      await tester.pumpWidget(_app(
        harness: harness,
        child: card(onTap: () {}, sparkleChance: 1),
      ));

      harness.settings.setSparklesEnabled(false);
      await tester.pump();

      await tester.tap(find.byType(TapDelight));
      await tester.pump();
      expect(find.byType(SparkleBurst), findsNothing);
      expect(_maxScale(tester), greaterThanOrEqualTo(1.0));

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('with animations off the card neither pops nor sparkles',
        (WidgetTester tester) async {
      int taps = 0;
      final _Harness harness = await _buildCobits(
        prefs: <String, Object>{SettingsRepositoryImpl.animationsKey: false},
      );
      await tester.pumpWidget(_app(
        harness: harness,
        child: card(onTap: () => taps++, sparkleChance: 1),
      ));

      await tester.tap(find.byType(TapDelight));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(taps, 1, reason: 'the card still has to work');
      expect(find.byType(SparkleBurst), findsNothing);
      expect(_maxScale(tester), 1.0);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
