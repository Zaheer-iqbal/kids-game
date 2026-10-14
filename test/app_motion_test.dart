import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids/core/motion/app_motion.dart';
import 'package:kids/core/settings/domain/app_settings.dart';
import 'package:kids/core/settings/domain/settings_repository.dart';
import 'package:kids/core/settings/presentation/settings_cubit.dart';
import 'package:kids/core/widgets/delight_settings.dart';

import 'support/frame_pump.dart';

/// Repository that just holds a value in memory; the only switch these tests
/// care about is "reduce motion".
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository([this._settings = AppSettings.defaults]);

  AppSettings _settings;

  @override
  AppSettings load() => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}

SettingsCubit _cubit({bool reduceMotion = false, bool animations = true}) {
  final SettingsCubit cubit = SettingsCubit(
    repository: _FakeSettingsRepository(
      AppSettings(reduceMotion: reduceMotion, animationsEnabled: animations),
    ),
  )..load();
  return cubit;
}

/// Wraps [child] in the same scope stack the real app uses, so [AppMotion] can
/// read the parent switches exactly as it does on a device.
Widget _scoped({required SettingsCubit cubit, required Widget child}) {
  return BlocProvider<SettingsCubit>.value(
    value: cubit,
    child: MaterialApp(
      home: DelightScope(
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

/// The opacity AppMotion (or its reduced-motion fallback) puts above [text].
double _opacityOver(WidgetTester tester, String text) {
  final Finder opacity = find
      .ancestor(of: find.text(text), matching: find.byType(Opacity))
      .first;
  return tester.widget<Opacity>(opacity).opacity;
}

void main() {
  group('MotionStyle vocabulary', () {
    test('only attention styles repeat forever', () {
      final Set<MotionStyle> repeating = MotionStyle.values
          .where((MotionStyle style) => style.repeats)
          .toSet();
      expect(repeating, <MotionStyle>{
        MotionStyle.pulse,
        MotionStyle.heartBeat,
      });
    });

    test('every style has a short, positive one-shot duration', () {
      for (final MotionStyle style in MotionStyle.values) {
        expect(style.duration.inMilliseconds, greaterThan(0));
        expect(
          style.duration.inMilliseconds,
          lessThanOrEqualTo(1600),
          reason: '$style should never feel slow',
        );
      }
    });
  });

  group('MotionPresets', () {
    test('each intent maps to the agreed style', () {
      expect(MotionPresets.entrance, MotionStyle.fadeInUp);
      expect(MotionPresets.rewardStar, MotionStyle.bounceIn);
      expect(MotionPresets.rewardStreak, MotionStyle.heartBeat);
      expect(MotionPresets.celebrate, MotionStyle.tada);
      expect(MotionPresets.celebrateSoft, MotionStyle.jello);
      expect(MotionPresets.gentleWrong, MotionStyle.headShake);
      expect(MotionPresets.attention, MotionStyle.pulse);
      expect(MotionPresets.locked, MotionStyle.wobble);
      expect(MotionPresets.dialogIn, MotionStyle.zoomIn);
      expect(MotionPresets.dialogOut, MotionStyle.zoomOut);
      expect(MotionPresets.eyes, MotionStyle.rubberBand);
    });
  });

  group('applyMotionTransform', () {
    const Widget child = SizedBox(width: 10, height: 10);

    test('fadeInUp starts invisible and below, ends fully shown', () {
      final Opacity start =
          applyMotionTransform(MotionStyle.fadeInUp, 0, child) as Opacity;
      expect(start.opacity, 0);
      final Transform startShift = start.child! as Transform;
      expect(startShift.transform.getTranslation().y, greaterThan(0));

      final Opacity end =
          applyMotionTransform(MotionStyle.fadeInUp, 1, child) as Opacity;
      expect(end.opacity, 1);
      final Transform endShift = end.child! as Transform;
      expect(endShift.transform.getTranslation().y, closeTo(0, 0.001));
    });

    test('bounceIn pops from tiny to full size', () {
      final Opacity start =
          applyMotionTransform(MotionStyle.bounceIn, 0, child) as Opacity;
      expect(start.opacity, 0);
      final Transform startScale = start.child! as Transform;
      expect(startScale.transform.entry(0, 0), closeTo(0.2, 0.001));

      final Opacity end =
          applyMotionTransform(MotionStyle.bounceIn, 1, child) as Opacity;
      expect(end.opacity, 1);
      final Transform endScale = end.child! as Transform;
      expect(endScale.transform.entry(0, 0), closeTo(1.0, 0.01));
    });

    test('zoomIn fades in from small; zoomOut settles from large', () {
      final Opacity zoomIn =
          applyMotionTransform(MotionStyle.zoomIn, 0, child) as Opacity;
      expect(zoomIn.opacity, 0);

      final Opacity zoomOutStart =
          applyMotionTransform(MotionStyle.zoomOut, 0, child) as Opacity;
      expect(zoomOutStart.opacity, 0);
      final Transform zoomOutScale = zoomOutStart.child! as Transform;
      expect(zoomOutScale.transform.entry(0, 0), greaterThan(1));

      final Opacity zoomOutEnd =
          applyMotionTransform(MotionStyle.zoomOut, 1, child) as Opacity;
      expect(zoomOutEnd.opacity, 1);
      final Transform settled = zoomOutEnd.child! as Transform;
      expect(settled.transform.entry(0, 0), closeTo(1.0, 0.001));
    });

    test('attention styles breathe without ever leaving ~1x', () {
      for (final MotionStyle style in <MotionStyle>[
        MotionStyle.pulse,
        MotionStyle.heartBeat,
      ]) {
        final Transform atRest =
            applyMotionTransform(style, 0, child) as Transform;
        expect(atRest.transform.entry(0, 0), closeTo(1.0, 0.01));

        final Transform atPeak =
            applyMotionTransform(style, 0.15, child) as Transform;
        expect(atPeak.transform.entry(0, 0), greaterThan(1.0));
        expect(
          atPeak.transform.entry(0, 0),
          lessThan(1.2),
          reason: '$style must stay gentle',
        );
      }
    });

    test('headShake and wobble start centered and move softly', () {
      final start = (applyMotionTransform(MotionStyle.headShake, 0, child)
              as Transform)
          .transform
          .getTranslation();
      expect(start.x, 0);
      expect(start.y, 0);

      final mid = (applyMotionTransform(MotionStyle.headShake, 0.125, child)
              as Transform)
          .transform
          .getTranslation();
      expect(mid.x, isNot(0));
      expect(mid.x.abs(), lessThanOrEqualTo(9));
    });

    test('rubberBand squashes and stretches around 1x', () {
      final Transform atRest =
          applyMotionTransform(MotionStyle.rubberBand, 0, child) as Transform;
      expect(atRest.transform.entry(0, 0), closeTo(1.0, 0.001));

      final Transform stretched =
          applyMotionTransform(MotionStyle.rubberBand, 0.25, child)
              as Transform;
      expect(stretched.transform.entry(0, 0), greaterThan(1.0));
    });

    test('tada and jello rotate, but stay gentle', () {
      for (final MotionStyle style in <MotionStyle>[
        MotionStyle.tada,
        MotionStyle.jello,
      ]) {
        final Transform mid =
            applyMotionTransform(style, 0.2, child) as Transform;
        final rotation = mid.transform.getRotation();
        final double angle =
            math.atan2(rotation.entry(1, 0), rotation.entry(0, 0));
        expect(angle, isNot(0), reason: '$style should actually move');
        expect(angle.abs(), lessThan(0.2), reason: '$style must stay subtle');
      }
    });
  });

  group('AppMotion widget', () {
    testWidgets('reveals its child and settles fully visible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppMotion(
                style: MotionStyle.fadeInUp,
                child: Text('hello'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('hello'), findsOneWidget);
      expect(_opacityOver(tester, 'hello'), 0);

      await settleFrames(tester, frames: 20);
      expect(_opacityOver(tester, 'hello'), 1);
    });

    testWidgets('a looping style keeps animating', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppMotion(
                style: MotionStyle.pulse,
                child: Text('flame'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // A repeating animation leaves a ticker running (the widget disposes its
      // own controller, so the tree teardown stops it cleanly).
      expect(tester.binding.transientCallbackCount, greaterThan(0));
    });

    testWidgets('a whole list shares one controller (no per-item tickers)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MotionStagger(
              itemCount: 6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 0; i < 6; i++)
                    AppMotion(index: i, child: Text('item$i')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      for (int i = 0; i < 6; i++) {
        expect(find.text('item$i'), findsOneWidget);
      }

      // The staggering finishes and every item is fully in place.
      await settleFrames(tester, frames: 40);
      for (int i = 0; i < 6; i++) {
        expect(_opacityOver(tester, 'item$i'), 1);
      }
    });
  });

  group('Reduce motion', () {
    testWidgets('pins one-shot styles to their finished state', (
      WidgetTester tester,
    ) async {
      final SettingsCubit cubit = _cubit(reduceMotion: true);
      addTearDown(cubit.close);
      final AnimationController controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_scoped(
        cubit: cubit,
        child: AppMotion(
          style: MotionStyle.fadeInUp,
          controller: controller,
          child: const Text('calm'),
        ),
      ));
      await tester.pump();

      expect(controller.value, 1, reason: 'content should simply be there');
      expect(controller.isAnimating, isFalse);
    });

    testWidgets('stops looping styles entirely', (
      WidgetTester tester,
    ) async {
      final SettingsCubit cubit = _cubit(reduceMotion: true);
      addTearDown(cubit.close);
      final AnimationController controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_scoped(
        cubit: cubit,
        child: AppMotion(
          style: MotionStyle.pulse,
          controller: controller,
          child: const Text('still'),
        ),
      ));
      await tester.pump();

      expect(controller.isAnimating, isFalse);
      expect(controller.value, 0);
    });

    testWidgets('the animations master switch also reduces motion', (
      WidgetTester tester,
    ) async {
      final SettingsCubit cubit = _cubit(animations: false);
      addTearDown(cubit.close);
      final AnimationController controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_scoped(
        cubit: cubit,
        child: AppMotion(
          style: MotionStyle.bounceIn,
          controller: controller,
          child: const Text('quiet'),
        ),
      ));
      await tester.pump();

      expect(controller.value, 1);
      expect(controller.isAnimating, isFalse);
    });

    test('the reduce motion switch persists', () async {
      final SettingsCubit cubit = _cubit();
      expect(cubit.state.reduceMotion, isFalse);

      cubit.setReduceMotion(true);
      expect(cubit.state.reduceMotion, isTrue);
      await pumpEventQueue();

      final SettingsCubit reloaded =
          SettingsCubit(repository: _FakeSettingsRepository(cubit.state.settings))
            ..load();
      expect(reloaded.state.reduceMotion, isTrue);

      await cubit.close();
      await reloaded.close();
    });
  });
}
