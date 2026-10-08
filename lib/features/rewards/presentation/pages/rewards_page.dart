import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/progress_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../core/widgets/star_badge.dart';
import '../../../quiz/domain/entities/quiz_type.dart';

/// Rewards tab: everything the child has collected - stars, streak, letter
/// badges, number badges and quiz best scores.
class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProgressService progress = di.sl<ProgressService>();
    final ThemeData theme = Theme.of(context);

    final int letters = progress.exploredCount;
    final int numbers = progress.exploredNumberCount;
    final int stars = progress.totalStars;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space2,
        AppTokens.space4,
        170,
      ),
      children: <Widget>[
        Text(
          'My Rewards',
          style: theme.textTheme.displaySmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppTokens.space4),
        StaggerEntrance(
          index: 0,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.space5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTokens.radiusXL),
              boxShadow: AppTokens.softShadow(),
            ),
            child: Row(
              children: <Widget>[
                ProgressRing(
                  progress: stars / 60,
                  size: 88,
                  color: AppColors.accentCoral,
                  child: Text(
                    '$stars',
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Stars collected',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppTokens.space2),
                      Wrap(
                        spacing: AppTokens.space2,
                        runSpacing: AppTokens.space2,
                        children: <Widget>[
                          StarBadge(count: stars),
                          StreakBadge(days: progress.streakDays),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space5),
        StaggerEntrance(
          index: 1,
          child: _BadgeCard(
            title: 'Letter badges',
            caption: '$letters of 26 letters explored',
            glyphs: List<String>.generate(
              26,
              (int i) => String.fromCharCode(65 + i),
            ),
              earned: progress.exploredLetters,
            color: AppColors.accentCoral,
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        StaggerEntrance(
          index: 2,
          child: _BadgeCard(
            title: 'Number badges',
            caption: '$numbers of 100 numbers explored',
            glyphs: List<String>.generate(100, (int i) => '${i + 1}'),
            earned: progress.exploredNumbers,
            color: AppColors.accentMint,
            dense: true,
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        StaggerEntrance(
          index: 3,
          child: Container(
            padding: const EdgeInsets.all(AppTokens.space4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
              boxShadow: AppTokens.softShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Quiz best scores', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppTokens.space3),
                for (final QuizType type in QuizType.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.space2),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            quizTitleFor(type),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        _ScorePill(score: progress.bestScoreFor(type.name)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Display names for the quiz modes (shared with the menu and arena).
String quizTitleFor(QuizType type) => switch (type) {
      QuizType.letterSounds => 'Letter Sounds',
      QuizType.numberMatch => 'Number Match',
      QuizType.funFacts => 'Fun Facts Trivia',
      QuizType.oddOneOut => 'Odd One Out',
    };

/// White pill with a trophy and a best score.
class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.emoji_events_rounded,
              size: 16, color: AppColors.gold),
          const SizedBox(width: 5),
          Text(
            '$score / 10',
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.title,
    required this.caption,
    required this.glyphs,
    required this.earned,
    required this.color,
    this.dense = false,
  });

  final String title;
  final String caption;
  final List<String> glyphs;
  final Set<String> earned;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTokens.space4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        boxShadow: AppTokens.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          Wrap(
            spacing: dense ? 8 : 10,
            runSpacing: dense ? 8 : 10,
            children: glyphs.map((String glyph) {
              final bool has = earned.contains(glyph);
              return Container(
                width: dense ? 44 : 52,
                height: dense ? 44 : 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: has
                      ? color.withValues(alpha: 0.18)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: has ? color : const Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
                child: Text(
                  glyph,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: dense ? 16 : 20,
                    fontWeight: FontWeight.w700,
                    color: has ? color : const Color(0xFF94A3B8),
                    height: 1,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
