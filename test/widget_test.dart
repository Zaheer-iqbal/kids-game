import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kids/core/theme/app_theme.dart';

void main() {
  testWidgets('app theme builds and renders text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Text('hello', key: Key('greeting'))),
      ),
    );
    expect(find.byKey(const Key('greeting')), findsOneWidget);
  });
}