import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids/core/widgets/parental_gate.dart';

void main() {
  bool? result;

  Future<void> pumpGate(WidgetTester tester) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showParentalGate(context);
                },
                child: const Text('Open settings'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('opens a grown-ups dialog that can be dismissed', (
    WidgetTester tester,
  ) async {
    await pumpGate(tester);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    expect(find.text('For grown-ups'), findsOneWidget);
    expect(find.text('Hold to continue'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('For grown-ups'), findsNothing);
    expect(result, isFalse);
  });

  testWidgets('a short press does not open the gate', (WidgetTester tester) async {
    await pumpGate(tester);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    final TestGesture press =
        await tester.startGesture(tester.getCenter(find.text('Hold to continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await press.up();
    await tester.pumpAndSettle();

    expect(find.text('For grown-ups'), findsOneWidget, reason: 'still gated');
    expect(result, isNull, reason: 'the dialog has not returned yet');
  });

  testWidgets('holding for the full time opens the gate', (
    WidgetTester tester,
  ) async {
    await pumpGate(tester);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    final TestGesture press =
        await tester.startGesture(tester.getCenter(find.text('Hold to continue')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));
    await press.up();
    await tester.pumpAndSettle();

    expect(find.text('For grown-ups'), findsNothing);
    expect(result, isTrue);
  });
}
