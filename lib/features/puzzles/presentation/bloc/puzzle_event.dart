import 'dart:ui' show Offset, Size;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
abstract class PuzzleEvent extends Equatable {
  const PuzzleEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Opens (or re-opens) a puzzle and lays out its board.
class PuzzleStarted extends PuzzleEvent {
  const PuzzleStarted(this.index);

  final int index;

  @override
  List<Object?> get props => <Object?>[index];
}

/// A jigsaw piece was released; the drop is measured against the board.
class JigsawPieceDropped extends PuzzleEvent {
  const JigsawPieceDropped({
    required this.pieceId,
    required this.localDrop,
    required this.boardSize,
  });

  final int pieceId;
  final Offset localDrop;
  final Size boardSize;

  @override
  List<Object?> get props => <Object?>[pieceId, localDrop, boardSize];
}

/// Picks a jigsaw piece up out of the tray (used to animate it forward).
class JigsawPiecePicked extends PuzzleEvent {
  const JigsawPiecePicked(this.pieceId);

  final int pieceId;

  @override
  List<Object?> get props => <Object?>[pieceId];
}

/// Taps a tray piece to drop it into its own slot. A gentle, accessible
/// alternative to dragging that works the same for every child.
class JigsawPieceAutoPlaced extends PuzzleEvent {
  const JigsawPieceAutoPlaced(this.pieceId);

  final int pieceId;

  @override
  List<Object?> get props => <Object?>[pieceId];
}

/// Taps a sliding tile; it only moves if it touches the empty gap.
class SlidingTileTapped extends PuzzleEvent {
  const SlidingTileTapped(this.position);

  final int position;

  @override
  List<Object?> get props => <Object?>[position];
}

/// Picks a silhouette on a shadow-match level.
class ShadowOptionSelected extends PuzzleEvent {
  const ShadowOptionSelected(this.animalId);

  final int animalId;

  @override
  List<Object?> get props => <Object?>[animalId];
}

/// Spends a hint (highlights a piece / reveals the guide picture).
class HintRequested extends PuzzleEvent {
  const HintRequested();

  @override
  List<Object?> get props => <Object?>[];
}

/// Puts the board back to the start of the same challenge.
class PuzzleReset extends PuzzleEvent {
  const PuzzleReset();

  @override
  List<Object?> get props => <Object?>[];
}