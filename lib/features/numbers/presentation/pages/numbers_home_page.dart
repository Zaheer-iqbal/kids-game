import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../sections/numbers_content.dart';

/// Standalone numbers screen reachable at `/numbers` (also reachable as a tab
/// on the home screen). Wrap it in a scaffold with a back affordance.
class NumbersHomePage extends StatelessWidget {
  const NumbersHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 30),
                    tooltip: 'Back',
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(child: NumbersSection()),
          ],
        ),
      ),
    );
  }
}