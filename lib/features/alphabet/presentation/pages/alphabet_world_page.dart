import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../pages/alphabet_home_page.dart';

/// The Alphabet Land explorer: a back affordance plus the A-Z grid.
class AlphabetWorldPage extends StatelessWidget {
  const AlphabetWorldPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
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
                ],
              ),
            ),
            const Expanded(child: AlphabetSection()),
          ],
        ),
      ),
    );
  }
}
