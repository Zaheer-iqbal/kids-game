import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/router/app_router.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/illustrated_background.dart';
import '../../../../core/widgets/star_badge.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../domain/repositories/puzzle_repository.dart';
import '../bloc/puzzle_catalog_cubit.dart';
import '../widgets/animal_picture.dart';

/// The zoo map: 100 animal puzzles that unlock one by one, each showing the
/// stars earned and the puzzle type.
class PuzzleMapPage extends StatelessWidget {
  const PuzzleMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PuzzleCatalogCubit>(
      create: (BuildContext context) => PuzzleCatalogCubit(
        repository: di.sl<PuzzleRepository>(),
        progress: di.sl<ProgressService>(),
      )..refresh(),
      child: const _PuzzleMapView(),
    );
  }
}

class _PuzzleMapView extends StatelessWidget {
  const _PuzzleMapView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: IllustratedBackground()),
          SafeArea(
            child: Column(
              children: <Widget>[
                const AppTopBar(
                  title: 'Animal Puzzles',
                  showHome: true,
                  showSettings: false,
                ),
                Expanded(
                  child: BlocBuilder<PuzzleCatalogCubit, PuzzleCatalogState>(
                    builder: (BuildContext context, PuzzleCatalogState state) {
                      return Column(
                        children: <Widget>[
                          _Header(state: state),
                          Expanded(child: _grid(context, state)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(BuildContext context, PuzzleCatalogState state) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth > 900
            ? 6
            : constraints.maxWidth > 640
                ? 5
                : constraints.maxWidth > 430
                    ? 4
                    : 3;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space2,
            AppTokens.space4,
            AppTokens.space6,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppTokens.space3,
            crossAxisSpacing: AppTokens.space3,
            childAspectRatio: 0.82,
          ),
          itemCount: state.entries.length,
          itemBuilder: (BuildContext context, int index) {
            final PuzzleCatalogEntry entry = state.entries[index];
            return _AnimalTile(entry: entry);
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final PuzzleCatalogState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space2,
        AppTokens.space4,
        AppTokens.space3,
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppTokens.space3,
        runSpacing: AppTokens.space2,
        children: <Widget>[
          Text(
            '${state.solvedCount} of ${state.entries.length} animals',
            style: AppTheme.glyphStyle(18, color: AppColors.ink),
          ),
          StarBadge(count: state.totalStars),
          GameButton.small(
            label: 'Resume #${di.sl<ProgressService>().lastPlayedPuzzleIndex + 1}',
            icon: Icons.play_arrow_rounded,
            color: AppColors.accentMint,
            onPressed: () => context.push(
              AppRoutes.puzzleRoute(
                di.sl<ProgressService>().lastPlayedPuzzleIndex,
              ),
            ),
          ),
          GameButton.small(
            label: 'My Animals',
            icon: Icons.pets_rounded,
            color: AppColors.accentPurple,
            onPressed: () => context.push(AppRoutes.myAnimals),
          ),
        ],
      ),
    );
  }
}

class _AnimalTile extends StatelessWidget {
  const _AnimalTile({required this.entry});

  final PuzzleCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: entry.unlocked ? '${entry.animal.name} puzzle' : 'Locked puzzle',
      button: entry.unlocked,
      child: GestureDetector(
        onTap: entry.unlocked
            ? () => context.push(AppRoutes.puzzleRoute(entry.animal.id))
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: entry.solved ? AppColors.pastelMint : AppColors.surface,
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
            border: Border.all(
              color: entry.solved
                  ? AppColors.success.withValues(alpha: 0.5)
                  : AppColors.outlineSoft,
              width: 2,
            ),
            boxShadow: AppTokens.softShadow(blur: 10, dy: 4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: entry.unlocked
                      ? AnimalPicture(animal: entry.animal, size: 62)
                      : const _LockedBadge(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  entry.unlocked ? entry.animal.name : 'Level ${entry.puzzle.levelNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: entry.unlocked ? AppColors.ink : AppColors.inkMuted,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (entry.unlocked)
                RatingStars(earned: entry.stars, size: 16)
              else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedBadge extends StatelessWidget {
  const _LockedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.locked,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 26),
    );
  }
}