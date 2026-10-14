import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids/core/di/injection_container.dart' as di;
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
  });
  await settleFrames(tester, frames: 20);
  for (int i = 0; i < 20 && find.text('Play Quiz').evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await settleFrames(tester, frames: 20);
  }
}

Future<void> settleReal(WidgetTester tester,
    [Duration wait = const Duration(milliseconds: 250)]) async {
  await tester.runAsync(() => Future<void>.delayed(wait));
  await settleFrames(tester);
}

void main() {
  testWidgets('home shows the Animal Puzzles card with its counter', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Animal Puzzles'), findsOneWidget);
    expect(find.text('0 of 100 animals solved'), findsOneWidget);
  });

  testWidgets('opening Animal Puzzles shows the map, then a puzzle plays', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Animal Puzzles'));
    await tester.pump();
    await settleReal(tester, const Duration(milliseconds: 400));

    expect(find.text('Animal Puzzles'), findsOneWidget);
    expect(find.text('0 of 100 animals'), findsOneWidget);
    expect(find.text('Lion'), findsOneWidget);

    // First animal (a jigsaw) opens and shows its instruction and actions.
    await tester.tap(find.text('Lion'));
    await tester.pump();
    await settleReal(tester, const Duration(milliseconds: 400));

    expect(find.text('Drag each piece into its shadow'), findsOneWidget);
    expect(find.text('Hint'), findsOneWidget);
    expect(find.text('Build the animal'), findsNothing);
  });
}
