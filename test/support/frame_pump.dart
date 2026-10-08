import 'package:flutter_test/flutter_test.dart';

/// Pumps a fixed budget of frames instead of waiting for the tree to go quiet.
///
/// Pip the mascot breathes and blinks forever by design, so
/// [WidgetTester.pumpAndSettle] can never settle while he is on screen and
/// would time out. A fixed frame budget still flushes layout, implicit
/// transitions and timers — it simply refuses to wait for a perpetual
/// animation to finish.
Future<void> settleFrames(
  WidgetTester tester, {
  int frames = 12,
  Duration step = const Duration(milliseconds: 40),
}) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}
