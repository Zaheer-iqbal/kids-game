import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/router/app_router.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/entrance.dart';
import '../../../../core/widgets/game_button.dart';
import '../../domain/adventure_world.dart';
import '../widgets/world_card.dart';

/// The scrollable adventure map: greeting, the big Play Quiz call to action
/// and the three worlds with their winding level paths.
class AdventureMapPage extends StatelessWidget {
  const AdventureMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProgressService progress = di.sl<ProgressService>();
    final ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space2,
        AppTokens.space4,
        170,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          StaggerEntrance(
            index: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Ready for an\nadventure?',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTokens.space3),
                Row(
                  children: <Widget>[
                    MapStatPill(
                      icon: Icons.star_rounded,
                      label: '${progress.totalStars} stars',
                    ),
                    const SizedBox(width: AppTokens.space2),
                    MapStatPill(
                      icon: Icons.local_fire_department_rounded,
                      label: '${progress.streakDays} day streak',
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space4),
                GameButton.large(
                  label: 'Play Quiz',
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFE11D48),
                  onPressed: () => context.push(AppRoutes.quizMenu),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space5),
          for (int i = 0; i < AdventureWorld.all.length; i++) ...<Widget>[
            StaggerEntrance(
              index: i + 1,
              child: _WorldSection(world: AdventureWorld.all[i]),
            ),
            if (i != AdventureWorld.all.length - 1)
              const SizedBox(height: AppTokens.space5),
          ],
        ],
      ),
    );
  }
}

class _WorldSection extends StatelessWidget {
  const _WorldSection({required this.world});

  final AdventureWorld world;

  @override
  Widget build(BuildContext context) {
    final ProgressService progress = di.sl<ProgressService>();
    final String storageKey = world.id.storageKey;

    final List<LevelState> levels = List<LevelState>.generate(
      world.levelCount,
      (int index) => LevelState(
        stars: progress.starsForLevel(storageKey, index),
        locked: !progress.isLevelUnlocked(storageKey, index),
      ),
    );

    return WorldCard(
      world: world,
      progressLabel: switch (world.id) {
        WorldId.alphabet =>
          '${progress.exploredCount} of 26 letters explored',
        WorldId.numbers =>
          '${progress.exploredNumberCount} of 100 numbers explored',
        WorldId.quiz => 'Best score ${progress.quizHighScore}',
      },
      levels: levels,
      onOpenWorld: () => switch (world.id) {
        WorldId.alphabet => context.push(AppRoutes.alphabet),
        WorldId.numbers => context.push(AppRoutes.numbers),
        WorldId.quiz => context.push(AppRoutes.quizMenu),
      },
      onLevelTap: (int level) {
        if (world.id == WorldId.quiz) {
          context.push(AppRoutes.quizRouteForIndex(level));
          return;
        }
        context.push(AppRoutes.lessonRoute(world.id.storageKey, level));
      },
    );
  }
}
