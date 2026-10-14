import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kids/core/di/injection_container.dart' as di;
import 'package:kids/core/router/app_router.dart';
import 'package:kids/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/frame_pump.dart';

/// A single (window size, text scale) configuration to sweep.
class _Config {
  const _Config(this.label, this.size, this.scale);

  final String label;
  final Size size;
  final double scale;
}

/// The matrix the app must survive: the smallest phone, common phones, tall
/// phones, a small tablet, a large tablet, a landscape phone and a desktop
/// window - paired with realistic text scales including the 1.6x ceiling.
const List<_Config> _matrix = <_Config>[
  _Config('320x568 @1.0', Size(320, 568), 1.0),
  _Config('320x568 @1.3', Size(320, 568), 1.3),
  _Config('320x568 @1.6', Size(320, 568), 1.6),
  _Config('360x640 @1.6', Size(360, 640), 1.6),
  _Config('390x844 @1.3', Size(390, 844), 1.3),
  _Config('412x915 @1.6', Size(412, 915), 1.6),
  _Config('600x960 @1.0', Size(600, 960), 1.0),
  _Config('600x960 @1.6', Size(600, 960), 1.6),
  _Config('820x1180 @1.3', Size(820, 1180), 1.3),
  _Config('844x390 @1.0', Size(844, 390), 1.0),
  _Config('844x390 @1.6', Size(844, 390), 1.6),
  _Config('1280x800 @1.0', Size(1280, 800), 1.0),
  _Config('1280x800 @1.6', Size(1280, 800), 1.6),
];

/// Captures "overflowed by" render errors instead of letting them fail the
/// test immediately, so one run reports every offending screen. Any other
/// error is forwarded to the framework untouched.
class _OverflowCollector {
  final List<String> overflows = <String>[];
  FlutterExceptionHandler? _previous;
  String screen = 'boot';

  void start() {
    _previous = FlutterError.onError;
    FlutterError.onError = _onError;
  }

  void stop() {
    FlutterError.onError = _previous;
  }

  void _onError(FlutterErrorDetails details) {
    final String text = details.exceptionAsString();
    if (text.contains('overflowed')) {
      String info = '';
      try {
        info = details.informationCollector
                ?.call()
                .map((DiagnosticsNode n) => n.toString())
                .join(' | ') ??
            '';
      } catch (_) {
        info = '<info unavailable>';
      }
      overflows.add('[$screen] $text  <<$info>>');
    } else {
      _previous?.call(details);
    }
  }
}

Future<Future<void> Function(String route, {String? as})> _boot(
  WidgetTester tester,
  _Config config,
  _OverflowCollector collector,
) async {
  SharedPreferences.setMockInitialValues(<String, Object>{'intro_seen': true});
  await di.sl.reset();
  await di.configureDependencies();

  tester.view.physicalSize = config.size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = config.scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.runAsync(() async {
    await tester.pumpWidget(const AlphabetKidsApp());
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await rootBundle.loadString('assets/data/alphabet.json');
    await rootBundle.loadString('assets/data/numbers.json');
  });
  await settleFrames(tester, frames: 20);

  final GoRouter router = di.sl<AppRouter>().router;

  Future<void> go(String route, {String? as}) async {
    collector.screen = as ?? route;
    router.go(route);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await settleFrames(tester, frames: 12);
  }

  return go;
}

Future<void> _tapSheet(WidgetTester tester, Key cardKey) async {
  final Finder card = find.byKey(cardKey);
  if (card.evaluate().isNotEmpty) {
    await tester.tap(card.first, warnIfMissed: false);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await settleFrames(tester, frames: 12);
    await tester.tapAt(const Offset(4, 4));
    await settleFrames(tester, frames: 8);
  }
}

Future<void> _runSweep(WidgetTester tester, _Config config) async {
  final _OverflowCollector collector = _OverflowCollector()..start();
  final Future<void> Function(String, {String? as}) go =
      await _boot(tester, config, collector);

  await go(AppRoutes.splash, as: 'splash');
  await go(AppRoutes.intro, as: 'intro');
  await go(AppRoutes.home, as: 'home');
  await go(AppRoutes.quizMenu, as: 'quiz-menu');
  await go(AppRoutes.settings, as: 'settings');
  await go(AppRoutes.quizLetters, as: 'quiz-letter-sounds');
  await go(AppRoutes.quizNumbers, as: 'quiz-number-match');
  await go(AppRoutes.quizFunFacts, as: 'quiz-fun-facts');
  await go(AppRoutes.quizOddOneOut, as: 'quiz-odd-one-out');
  await go(AppRoutes.quizResults, as: 'quiz-results');
  await go(AppRoutes.lessonRoute('alphabet', 0), as: 'lesson-alphabet-0');
  await go(AppRoutes.lessonRoute('numbers', 0), as: 'lesson-numbers-0');
  await go(AppRoutes.alphabet, as: 'alphabet-explorer');
  await _tapSheet(tester, const ValueKey<String>('letter-A'));
  await go(AppRoutes.numbers, as: 'numbers-explorer');
  await _tapSheet(tester, const ValueKey<String>('number-1'));

  await go(AppRoutes.puzzles, as: 'puzzle-map');
  await go(AppRoutes.puzzleRoute(0), as: 'puzzle-jigsaw');
  await go(AppRoutes.puzzleRoute(4), as: 'puzzle-sliding');
  await go(AppRoutes.puzzleRoute(6), as: 'puzzle-shadow');
  await go(AppRoutes.myAnimals, as: 'my-animals');

  collector.stop();
  expect(
    collector.overflows,
    isEmpty,
    reason: '${config.label}: overflow(s) found:\n'
        '${collector.overflows.join('\n---\n')}',
  );
}

void main() {
  for (final _Config config in _matrix) {
    testWidgets('no overflow at ${config.label}', (WidgetTester tester) async {
      await _runSweep(tester, config);
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}
