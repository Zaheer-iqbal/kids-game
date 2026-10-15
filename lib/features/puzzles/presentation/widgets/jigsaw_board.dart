import 'dart:math' as math;

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

/// The jigsaw board: a **square** picture the child rebuilds by dragging (or
/// tapping) pieces from the tray into their matching slots.
///
/// The board is square and split into the same [columns] x [rows] grid as the
/// composed picture, so every cell has exactly the same aspect ratio as its
/// slice. Pieces are drawn edge to edge (no gaps, no per-tile tint), which is
/// what lets the finished board read as one single picture.
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
        const SizedBox(height: AppTokens.space4),
        _buildTray(context, puzzle, animal),
      ],
    );
  }

  Widget _buildBoard(BuildContext context, AnimalPuzzle puzzle, Animal animal) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : maxWidth;
        // A square board keeps every cell the same shape as its source slice.
        final double side = math.min(maxWidth, maxHeight);

        Widget board = SizedBox(
          key: _boardKey,
          width: side,
          height: side,
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
            builder: (BuildContext context, _, __) =>
                _buildPieces(puzzle, animal, side),
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

  Widget _buildPieces(AnimalPuzzle puzzle, Animal animal, double side) {
    final double cellW = side / puzzle.columns;
    final double cellH = side / puzzle.rows;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
      child: Stack(
        children: <Widget>[
          // Faint silhouette of the whole animal: the target the child builds.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GuidePainter(animal.emoji),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          for (int slot = 0; slot < puzzle.pieceCount; slot++)
            Positioned(
              left: (slot % puzzle.columns) * cellW,
              top: (slot ~/ puzzle.columns) * cellH,
              width: cellW,
              height: cellH,
              child: _buildSlot(slot, animal, puzzle),
            ),
        ],
      ),
    );
  }

  Widget _buildSlot(int slot, Animal animal, AnimalPuzzle puzzle) {
    final bool filled = widget.state.slots[slot] != null;
    final bool hinted = widget.state.hintSlot == slot;

    Widget child;
    if (filled) {
      child = AnimalPicture(
        animal: animal,
        size: 0,
        columns: puzzle.columns,
        rows: puzzle.rows,
        tile: slot,
        rounded: false,
        seamless: true,
        showBackground: false,
      );
    } else {
      child = DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(
            color: AppColors.outlineSoft.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
      );
    }

    if (hinted && !filled) {
      child = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        builder: (BuildContext context, double value, Widget? inner) {
          return DecoratedBox(
            decoration: BoxDecoration(
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
        // Big enough to grab comfortably, but always at least three per row.
        final double piece = (constraints.maxWidth / (puzzle.columns + 1))
            .clamp(56.0, 112.0);
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

/// Paints the faint animal silhouette behind the board, using the exact same
/// fit and centring as the composed picture so it lines up with the pieces.
class _GuidePainter extends CustomPainter {
  const _GuidePainter(this.emoji);

  final String emoji;

  @override
  void paint(Canvas canvas, Size size) {
    AnimalImages.paintGlyphSilhouette(
      canvas,
      size,
      emoji,
      AppColors.silhouette.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(_GuidePainter oldDelegate) => oldDelegate.emoji != emoji;
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
      rounded: true,
      showBackground: false,
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
