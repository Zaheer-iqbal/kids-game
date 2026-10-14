import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/entities/animal.dart';
import '../../domain/entities/animal_puzzle.dart';
import '../bloc/puzzle_bloc.dart';
import '../bloc/puzzle_event.dart';
import '../bloc/puzzle_state.dart';
import 'animal_picture.dart';

/// The sliding board: tap the tile next to the empty space to slide it into
/// place and rebuild the animal.
class SlidingBoard extends StatelessWidget {
  const SlidingBoard({super.key, required this.state});

  final PuzzleState state;

  @override
  Widget build(BuildContext context) {
    final AnimalPuzzle? puzzle = state.puzzle;
    final Animal? animal = state.animal;
    if (puzzle == null || animal == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight * 0.8
            : constraints.maxWidth;
        final double byWidth = constraints.maxWidth;
        final double byHeight = maxHeight * puzzle.columns / puzzle.rows;
        final double boardWidth = byWidth < byHeight ? byWidth : byHeight;
        final double cell = boardWidth / puzzle.columns;
        final Size boardSize =
            Size(cell * puzzle.columns, cell * puzzle.rows);

        return Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
              border: Border.all(color: AppColors.outlineSoft, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space2),
              child: SizedBox(
                width: boardSize.width,
                height: boardSize.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    if (state.showGuide)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.28,
                            child: AnimalPicture(
                              animal: animal,
                              size: boardSize.width,
                              rounded: true,
                            ),
                          ),
                        ),
                      ),
                    for (int position = 0;
                        position < state.board.length;
                        position++)
                      _buildTile(context, puzzle, animal, position, cell),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTile(
    BuildContext context,
    AnimalPuzzle puzzle,
    Animal animal,
    int position,
    double cell,
  ) {
    final int? tileId = state.board[position];
    if (tileId == null) return const SizedBox.shrink();

    final int row = position ~/ puzzle.columns;
    final int col = position % puzzle.columns;
    final bool correct = tileId == position;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      left: col * cell,
      top: row * cell,
      width: cell,
      height: cell,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Semantics(
          label: 'Tile ${tileId + 1}',
          button: true,
          child: GestureDetector(
            onTap: () => context.read<PuzzleBloc>().add(
                  SlidingTileTapped(position),
                ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall * 0.6),
                border: correct
                    ? Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 2)
                    : null,
              ),
              child: AnimalPicture(
                animal: animal,
                size: cell,
                columns: puzzle.columns,
                rows: puzzle.rows,
                tile: tileId,
                background: AnimalImages.pastels[tileId % AnimalImages.pastels.length],
              ),
            ),
          ),
        ),
      ),
    );
  }
}