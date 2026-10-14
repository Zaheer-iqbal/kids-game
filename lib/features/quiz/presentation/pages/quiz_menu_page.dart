import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../domain/entities/quiz_type.dart';

/// Picks which quiz to play from four playful mode cards.
///
/// [QuizMenuPage] is the standalone route (with a back affordance);
/// [QuizMenuView] is the bare content reused by the home shell's Play tab.
class QuizMenuPage extends StatelessWidget {
  const QuizMenuPage({super.key});

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
                    tooltip: 'Back to home',
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const Expanded(child: QuizMenuView()),
          ],
        ),
      ),
    );
  }
}

class QuizMenuView extends StatelessWidget {
  const QuizMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Choose a Quiz!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick your favorite game to play.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            // Column count and cell height are derived from the space the
            // screen actually has (and the live text scale) so a big
            // accessibility font grows the cards instead of overflowing them.
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int columns = Responsive.columnsFor(
                  constraints,
                  targetWidth: 150,
                  spacing: 16,
                  min: 1,
                  max: 4,
                );
                final double cellWidth =
                    (constraints.maxWidth - (columns - 1) * 16) / columns;
                final double scale = MediaQuery.textScalerOf(context).scale(1);
                final double minHeight = 230 * scale;
                final double extent =
                    cellWidth > minHeight ? cellWidth : minHeight;
                return GridView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: _modes.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: extent,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final _QuizMode mode = _modes[index];
                    return _MenuCard(
                      mode: mode,
                      onTap: () =>
                          context.push(AppRoutes.quizRouteFor(mode.type)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static final List<_QuizMode> _modes = <_QuizMode>[
    _QuizMode(
      type: QuizType.letterSounds,
      title: 'Letter Sounds',
      caption: 'Hear a letter sound, tap its picture.',
      icon: Icons.volume_up_rounded,
      color: AppColors.quiz,
    ),
    _QuizMode(
      type: QuizType.numberMatch,
      title: 'Number Match',
      caption: 'Hear a number, tap the numeral.',
      icon: Icons.pin_rounded,
      color: const Color(0xFF5FA8E6),
    ),
    _QuizMode(
      type: QuizType.funFacts,
      title: 'Fun Facts Trivia',
      caption: 'Guess who the fun fact is about!',
      icon: Icons.lightbulb_rounded,
      color: const Color(0xFF92D177),
    ),
    _QuizMode(
      type: QuizType.oddOneOut,
      title: 'Odd One Out',
      caption: 'Find the one that does not belong.',
      icon: Icons.compare_rounded,
      color: const Color(0xFFB993F0),
    ),
  ];
}

class _QuizMode {
  const _QuizMode({
    required this.type,
    required this.title,
    required this.caption,
    required this.icon,
    required this.color,
  });

  final QuizType type;
  final String title;
  final String caption;
  final IconData icon;
  final Color color;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.mode, required this.onTap});

  final _QuizMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xDDEFDFCF), width: 2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: mode.color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(mode.icon, color: mode.color, size: 30),
              ),
              const Spacer(),
              Text(
                mode.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mode.caption,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}