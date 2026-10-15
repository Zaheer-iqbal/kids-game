import 'package:flutter/foundation.dart';

/// The three playful ways an animal puzzle can be built.
enum AnimalPuzzleType {
  /// Drag picture pieces into their shadow slots on the board.
  jigsaw,

  /// Slide tiles into the empty space to rebuild the animal (always solvable).
  sliding,

  /// Match the animal to its silhouette among friendly decoys.
  shadowMatch,
}

/// How demanding a puzzle is, derived straight from its piece count so the
/// ladder is always consistent with the board the child actually sees.
enum PuzzleDifficulty {
  /// 4 pieces (2x2) - a first taste.
  easy,

  /// 6 pieces (2x3) or 9 pieces (3x3).
  medium,

  /// 12 pieces (3x4) - a proper challenge.
  hard,
}

extension PuzzleDifficultyLabel on PuzzleDifficulty {
  String get label {
    switch (this) {
      case PuzzleDifficulty.easy:
        return 'Easy';
      case PuzzleDifficulty.medium:
        return 'Medium';
      case PuzzleDifficulty.hard:
        return 'Hard';
    }
  }
}

/// A single animal puzzle with its rule set baked in.
///
/// The mapping from level index to type and grid size is deterministic, so the
/// map, the level list and the tests all agree without any stored state.
@immutable
class AnimalPuzzle {
  const AnimalPuzzle({
    required this.index,
    required this.type,
    required this.columns,
    required this.rows,
  });

  /// 0-based position on the puzzles map.
  final int index;
  final AnimalPuzzleType type;

  /// Boards are [columns] wide and [rows] tall.
  final int columns;
  final int rows;

  /// 1-based level number shown to the child.
  int get levelNumber => index + 1;

  /// Total movable tiles (not counting the sliding puzzle's empty gap).
  int get pieceCount => columns * rows;

  bool get isJigsaw => type == AnimalPuzzleType.jigsaw;
  bool get isSliding => type == AnimalPuzzleType.sliding;
  bool get isShadowMatch => type == AnimalPuzzleType.shadowMatch;

  /// Difficulty tier implied by the piece count: 4 / (6 or 9) / 12.
  PuzzleDifficulty get difficulty {
    if (pieceCount <= 4) return PuzzleDifficulty.easy;
    if (pieceCount <= 9) return PuzzleDifficulty.medium;
    return PuzzleDifficulty.hard;
  }

  /// Sliding puzzles hide one tile, so they need a gap.
  int get slidingGapIndex => pieceCount - 1;

  /// Deterministic level -> puzzle rule table.
  ///
  /// Shadow-match levels are every 7th puzzle and sliding levels every 5th;
  /// where the two patterns overlap (35, 70) the shadow-match rule wins.
  /// Everything else is a jigsaw, getting slowly bigger with the level.
  factory AnimalPuzzle.forIndex(int index) {
    final int ordinal = index + 1;
    if (ordinal % 7 == 0) {
      return AnimalPuzzle(
        index: index,
        type: AnimalPuzzleType.shadowMatch,
        columns: 3,
        rows: 2,
      );
    }
    if (ordinal % 5 == 0) {
      return AnimalPuzzle(
        index: index,
        type: AnimalPuzzleType.sliding,
        columns: 3,
        rows: 3,
      );
    }

    if (ordinal <= 30) {
      return AnimalPuzzle(
        index: index,
        type: AnimalPuzzleType.jigsaw,
        columns: 2,
        rows: 2,
      );
    }
    if (ordinal <= 60) {
      return AnimalPuzzle(
        index: index,
        type: AnimalPuzzleType.jigsaw,
        columns: 2,
        rows: 3,
      );
    }
    if (ordinal <= 85) {
      return AnimalPuzzle(
        index: index,
        type: AnimalPuzzleType.jigsaw,
        columns: 3,
        rows: 3,
      );
    }
    return AnimalPuzzle(
      index: index,
      type: AnimalPuzzleType.jigsaw,
      columns: 3,
      rows: 4,
    );
  }
}