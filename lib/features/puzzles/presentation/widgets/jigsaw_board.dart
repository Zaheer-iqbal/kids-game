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

/// The jigsaw board: a grid of animal-shaped shadows the child fills by
/// dragging (or tapping) colourful picture pieces from the tray below.
class JigsawBoard extends StatefulWidget {
  const JigsawBoard({super.key, required this.state});

  final PuzzleState state;

  @override
  State<JigsawBoard> createState() => _JigsawBoardState();
}

class _JigsawBoardState extends State<JigsawBoard> {
  final GlobalKey _boardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final AnimalPuzzle? puzzle = widget.state.puzzle;
    final Animal? animal = widget.state.animal;
    if (puzzle == null || animal == null) return const SizedBox.shrink();

    return Column(
      children: <Widget>[
        Expanded(child: _buildBoard(context, puzzle, animal)),
        const SizedBox(height: AppTokens.space5),
        _buildTray(context, puzzle, animal),
      ],
    );
  }

  Widget _buildBoard(BuildContext context, AnimalPuzzle puzzle, Animal animal) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight * 0.68
            : maxWidth;
        final double byWidth = maxWidth;
        final double byHeight = maxHeight * puzzle.columns / puzzle.rows;
        final double boardWidth = byWidth < byHeight ? byWidth : byHeight;
        final double boardHeight = boardWidth * puzzle.rows / puzzle.columns;

        Widget board = SizedBox(
          key: _boardKey,
          width: boardWidth,
          height: boardHeight,
          child: DragTarget<int>(
            onWillAcceptWithDetails: (DragTargetDetails<int> details) => true,
            onAcceptWithDetails: (DragTargetDetails<int> details) {
              final RenderBox? box =
                  _boardKey.currentContext?.findRenderObject() as RenderBox?;
              if (box == null) return;
              final Offset local = box.globalToLocal(details.offset);
              final Offset cellCentre = Offset(
                local.dx + box.size.width / puzzle.columns / 2,
                local.dy + box.size.height / puzzle.rows / 2,
              );
              context.read<PuzzleBloc>().add(
                    JigsawPieceDropped(
                      pieceId: details.data,
                      localDrop: cellCentre,
                      boardSize: box.size,
                    ),
                  );
            },
            builder: (BuildContext context, _, __) => _buildGrid(puzzle, animal),
          ),
        );

        board = DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            border: Border.all(color: AppColors.outlineSoft, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space2),
            child: board,
          ),
        );
        return Center(child: board);
      },
    );
  }

  Widget _buildGrid(AnimalPuzzle puzzle, Animal animal) {
    return Column(
      children: List<Widget>.generate(puzzle.rows, (int row) {
        return Expanded(
          child: Row(
            children: List<Widget>.generate(puzzle.columns, (int col) {
              final int slot = row * puzzle.columns + col;
              return Expanded(child: _buildSlot(slot, animal));
            }),
          ),
        );
      }),
    );
  }

  Widget _buildSlot(int slot, Animal animal) {
    final bool filled = widget.state.slots[slot] != null;
    final bool hinted = widget.state.hintSlot == slot;

    Widget child = filled
        ? AnimalPicture(
            animal: animal,
            size: 64,
            columns: widget.state.puzzle!.columns,
            rows: widget.state.puzzle!.rows,
            tile: slot,
            background: AnimalImages.pastels[slot % AnimalImages.pastels.length],
            rounded: true,
          )
        : AnimalPicture(
            animal: animal,
            size: 64,
            columns: widget.state.puzzle!.columns,
            rows: widget.state.puzzle!.rows,
            tile: slot,
            silhouette: true,
            rounded: true,
          );

    child = Padding(
      padding: const EdgeInsets.all(3),
      child: child,
    );

    if (hinted && !filled) {
      child = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        builder: (BuildContext context, double value, Widget? inner) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35 + 0.45 * value),
                width: 3,
              ),
            ),
            child: inner,
          );
        },
        child: child,
      );
    }
    return child;
  }

  Widget _buildTray(BuildContext context, AnimalPuzzle puzzle, Animal animal) {
    final List<int> tray = widget.state.tray;
    if (tray.isEmpty) {
      return const SizedBox(height: AppTokens.minTapTarget);
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double piece = (constraints.maxWidth / (puzzle.columns + 1))
            .clamp(48.0, 96.0);
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: AppTokens.space2,
          runSpacing: AppTokens.space2,
          children: <Widget>[
            for (final int pieceId in tray)
              _TrayPiece(
                animal: animal,
                puzzle: puzzle,
                pieceId: pieceId,
                size: piece,
              ),
          ],
        );
      },
    );
  }
}

class _TrayPiece extends StatelessWidget {
  const _TrayPiece({
    required this.animal,
    required this.puzzle,
    required this.pieceId,
    required this.size,
  });

  final Animal animal;
  final AnimalPuzzle puzzle;
  final int pieceId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Widget piece = AnimalPicture(
      animal: animal,
      size: size,
      columns: puzzle.columns,
      rows: puzzle.rows,
      tile: pieceId,
      background: AnimalImages.pastels[pieceId % AnimalImages.pastels.length],
    );

    return Draggable<int>(
      data: pieceId,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.08,
          child: SizedBox(width: size, height: size, child: piece),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: piece),
      onDragStarted: () =>
          context.read<PuzzleBloc>().add(JigsawPiecePicked(pieceId)),
      child: Semantics(
        label: 'Puzzle piece ${pieceId + 1}',
        button: true,
        child: GestureDetector(
          onTap: () =>
              context.read<PuzzleBloc>().add(JigsawPieceAutoPlaced(pieceId)),
          child: piece,
        ),
      ),
    );
  }
}