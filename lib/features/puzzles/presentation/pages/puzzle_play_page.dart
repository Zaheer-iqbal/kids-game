import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/router/app_router.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/celebration_overlay.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/illustrated_background.dart';
import '../../../../core/widgets/star_badge.dart';
import '../../../../core/widgets/top_bar.dart';
import '../../domain/entities/animal.dart';
import '../../domain/entities/animal_puzzle.dart';
import '../../domain/repositories/puzzle_repository.dart';
import '../bloc/puzzle_bloc.dart';
import '../bloc/puzzle_event.dart';
import '../bloc/puzzle_state.dart';
import '../widgets/jigsaw_board.dart';
import '../widgets/shadow_match_board.dart';
import '../widgets/sliding_board.dart';

/// Plays one animal puzzle. The layout adapts to the puzzle type and to any
/// window size, and always scrolls rather than overflowing.
class PuzzlePlayPage extends StatelessWidget {
  const PuzzlePlayPage({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PuzzleBloc>(
      create: (BuildContext context) => PuzzleBloc(
        repository: di.sl<PuzzleRepository>(),
        progress: di.sl<ProgressService>(),
      )..add(PuzzleStarted(index)),
      child: _PuzzleView(index: index),
    );
  }
}

class _PuzzleView extends StatefulWidget {
  const _PuzzleView({required this.index});

  final int index;

  @override
  State<_PuzzleView> createState() => _PuzzleViewState();
}

class _PuzzleViewState extends State<_PuzzleView> {
  bool _celebrated = false;

  @override
  Widget build(BuildContext context) {
    final ProgressService progress = di.sl<ProgressService>();

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: IllustratedBackground()),
          SafeArea(
            child: BlocConsumer<PuzzleBloc, PuzzleState>(
              listenWhen: (PuzzleState a, PuzzleState b) =>
                  a.status != b.status || a.bonusStar != b.bonusStar,
              listener: _onStateChanged,
              builder: (BuildContext context, PuzzleState state) {
                return Column(
                  children: <Widget>[
                    AppTopBar(
                      title: state.animal == null
                          ? 'Puzzle'
                          : '${state.animal!.name}  ${state.animal!.emoji}',
                      stars: progress.totalStars,
                      streak: progress.streakDays,
                      showSettings: false,
                    ),
                    Expanded(
                      child: state.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildBody(context, state),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onStateChanged(BuildContext context, PuzzleState state) {
    if (state.status == PuzzleStatus.solved && state.bonusStar && _celebrated) {
      // The hint-free bonus arrives just after the win; cheer again, lightly.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⭐ Bonus star! Three in a row!')),
      );
      return;
    }

    if (state.status != PuzzleStatus.solved || _celebrated) return;
    _celebrated = true;

    final AudioService audio = di.sl<AudioService>();
    final Animal? animal = state.animal;
    audio.playFanfare();
    if (animal != null) {
      audio.speakText(animal.celebrationLine);
    }
    final String message = state.usedHint
        ? 'Nice one! ${animal?.sound ?? ''}'
        : 'Perfect! No hints!';

    showCelebrationOverlay(context, message: message);
  }

  Widget _buildBody(BuildContext context, PuzzleState state) {
    final double width = MediaQuery.sizeOf(context).width;
    final double height = MediaQuery.sizeOf(context).height;
    final bool wide = width > 700;

    return SingleChildScrollView(
      padding: AppTokens.screenPadding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: AppTokens.space2),
              if (state.puzzle != null)
                _DifficultyChip(puzzle: state.puzzle!),
              const SizedBox(height: AppTokens.space3),
              Text(
                _instruction(state.puzzle),
                textAlign: TextAlign.center,
                style: AppTheme.glyphStyle(wide ? 24 : 20, color: AppColors.ink),
              ),
              const SizedBox(height: AppTokens.space3),
              _ProgressBar(progress: state.progress),
              const SizedBox(height: AppTokens.space5),
              SizedBox(
                height: (height * 0.5).clamp(220, 520),
                child: _board(state),
              ),
              const SizedBox(height: AppTokens.space5),
              _actions(context, state),
              const SizedBox(height: AppTokens.space5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _board(PuzzleState state) {
    final AnimalPuzzle? puzzle = state.puzzle;
    if (puzzle == null) return const SizedBox.shrink();
    switch (puzzle.type) {
      case AnimalPuzzleType.jigsaw:
        return JigsawBoard(state: state);
      case AnimalPuzzleType.sliding:
        return SlidingBoard(state: state);
      case AnimalPuzzleType.shadowMatch:
        return ShadowMatchBoard(state: state);
    }
  }

  Widget _actions(BuildContext context, PuzzleState state) {
    final PuzzleBloc bloc = context.read<PuzzleBloc>();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppTokens.space3,
      runSpacing: AppTokens.space3,
      children: <Widget>[
        if (!state.isSolved) ...<Widget>[
          GameButton(
            label: 'Hint',
            icon: Icons.lightbulb_rounded,
            color: AppColors.accentPurple,
            onPressed: () => bloc.add(const HintRequested()),
          ),
          GameButton(
            label: 'Start over',
            onPressed: () => bloc.add(const PuzzleReset()),
            icon: Icons.refresh_rounded,
            color: AppColors.accentSky,
            filled: false,
          ),
        ] else ...<Widget>[
          if (state.bestStars > 0)
            RatingStars(earned: state.starsAwarded, size: 28, animate: true),
          const SizedBox(width: AppTokens.space2),
          if (state.puzzle != null &&
              state.puzzle!.index < 99 &&
              di.sl<ProgressService>().isPuzzleUnlocked(state.puzzle!.index + 1))
            GameButton.large(
              label: 'Next animal',
              icon: Icons.arrow_forward_rounded,
              color: AppColors.accentMint,
              onPressed: () => context.pushReplacement(
                AppRoutes.puzzleRoute(state.puzzle!.index + 1),
              ),
            )
          else
            GameButton.large(
              label: 'Back to puzzles',
              icon: Icons.grid_view_rounded,
              color: AppColors.primary,
              onPressed: () => context.go(AppRoutes.puzzles),
            ),
        ],
      ],
    );
  }

  String _instruction(AnimalPuzzle? puzzle) {
    if (puzzle == null) return 'Build the animal';
    switch (puzzle.type) {
      case AnimalPuzzleType.jigsaw:
        return 'Drag each piece into its shadow';
      case AnimalPuzzleType.sliding:
        return 'Slide the tiles to fix the picture';
      case AnimalPuzzleType.shadowMatch:
        return 'Which shadow matches?';
    }
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.puzzle});

  final AnimalPuzzle puzzle;

  @override
  Widget build(BuildContext context) {
    final PuzzleDifficulty difficulty = puzzle.difficulty;
    final Color accent;
    switch (difficulty) {
      case PuzzleDifficulty.easy:
        accent = AppColors.accentMint;
      case PuzzleDifficulty.medium:
        accent = AppColors.goldInk;
      case PuzzleDifficulty.hard:
        accent = AppColors.accentCoral;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space1 + 2,
        ),
        child: Text(
          '${difficulty.label}  •  ${puzzle.pieceCount} pieces',
          style: AppTheme.glyphStyle(15, color: accent),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        child: LinearProgressIndicator(
          value: progress.clamp(0, 1),
          minHeight: 14,
          backgroundColor: AppColors.surfaceSoft,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentMint),
        ),
      ),
    );
  }
}