import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/motion/app_motion.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/quiz_result.dart';

/// End-of-quiz screen: total score, a fun congratulatory message and a Play
/// Again button.
class QuizResultsPage extends StatelessWidget {
  const QuizResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final QuizResult? result = GoRouterState.of(context).extra as QuizResult?;

    if (result == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.sentiment_satisfied_alt_rounded,
                  size: 56,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  'No quiz result yet. Go play!',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.quizMenu),
                  child: const Text('Choose a Quiz'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final double ratio =
        result.totalQuestions == 0 ? 0 : result.score / result.totalQuestions;
    final String message;
    if (ratio >= 1) {
      message = "Perfect score! You're a superstar!";
    } else if (ratio >= 0.7) {
      message = 'Great job! You really know your stuff!';
    } else if (ratio >= 0.4) {
      message = 'Nice work! Keep practicing and you will shine!';
    } else {
      message = 'Good try! Every practice makes you smarter!';
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            // One controller fans the whole result in: trophy, score, message
            // and actions, one after another.
            child: MotionStagger(
              itemCount: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppMotion(
                    index: 0,
                    style: MotionPresets.rewardStar,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.gold,
                        size: 62,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AppMotion(
                    index: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Quiz complete!',
                          style: theme.textTheme.displaySmall
                              ?.copyWith(color: AppColors.ink),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You scored ${result.score} of ${result.totalQuestions}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (result.newHighScore) ...<Widget>[
                    const SizedBox(height: 14),
                    AppMotion(
                      index: 2,
                      style: MotionPresets.celebrateSoft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.star_rounded,
                              color: AppColors.gold,
                              size: 22,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'New best! ${result.bestScore}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  AppMotion(
                    index: 3,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 14,
                      runSpacing: 12,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: () => context.pushReplacement(
                            AppRoutes.quizRouteFor(result.type),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 26),
                          label: const Text('Play Again'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go(AppRoutes.quizMenu),
                          icon: const Icon(Icons.quiz_rounded, size: 26),
                          label: const Text('More Quizzes'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}