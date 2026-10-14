import 'dart:math' as math;

import '../../domain/entities/animal.dart';
import '../../domain/entities/animal_puzzle.dart';
import '../../domain/repositories/puzzle_repository.dart';
import '../animal_data.dart' as data;

/// In-memory zoo. No network, no assets: every animal is a code-drawn emoji
/// sticker, so the app works offline and the tests are fully deterministic.
class PuzzleRepositoryImpl implements PuzzleRepository {
  const PuzzleRepositoryImpl();

  @override
  List<Animal> get animals => data.animals;

  @override
  int get puzzleCount => data.animals.length;

  @override
  Animal animalAt(int index) => animals[index.clamp(0, animals.length - 1)];

  @override
  AnimalPuzzle puzzleAt(int index) => AnimalPuzzle.forIndex(index);

  @override
  List<int> shadowOptions(int index) {
    final int count = index.isEven ? 3 : 4;
    final List<int> picks = <int>[index];
    for (final int offset in <int>[3, 11, 23, 37, 53]) {
      if (picks.length >= count) break;
      final int candidate = (index + offset) % animals.length;
      if (!picks.contains(candidate)) picks.add(candidate);
    }

    // Put the answer at a stable, non-obvious position for this level.
    final int answerPosition = index % picks.length;
    final List<int> ordered = <int>[];
    int decoy = 1;
    for (int slot = 0; slot < picks.length; slot++) {
      ordered.add(slot == answerPosition ? index : picks[decoy++]);
    }
    return ordered;
  }

  @override
  List<int?> slidingBoard(int index, {int shuffleMoves = 60}) {
    final AnimalPuzzle puzzle = puzzleAt(index);
    final int total = puzzle.pieceCount;
    final List<int?> board = List<int?>.generate(
      total,
      (int position) => position,
    );

    // A solvable shuffle: walk the gap around from the solved state, never
    // undoing the last move, so any reachable board can be unwound again.
    final math.Random random = math.Random(index * 977 + 31);
    int gap = puzzle.slidingGapIndex;
    board[gap] = null;
    int? previousGap;
    for (int step = 0; step < shuffleMoves; step++) {
      final List<int> neighbours = _neighbours(gap, puzzle.columns, puzzle.rows)
          .where((int next) => next != previousGap)
          .toList();
      if (neighbours.isEmpty) continue;
      final int next = neighbours[random.nextInt(neighbours.length)];
      board[gap] = board[next];
      board[next] = null;
      previousGap = gap;
      gap = next;
    }

    if (_isSolved(board, puzzle)) {
      // Extremely unlikely, but never hand the child an already-finished board.
      final List<int> neighbours = _neighbours(gap, puzzle.columns, puzzle.rows);
      final int next = neighbours.first;
      board[gap] = board[next];
      board[next] = null;
    }
    return board;
  }

  static bool _isSolved(List<int?> board, AnimalPuzzle puzzle) {
    for (int position = 0; position < board.length; position++) {
      if (position == puzzle.slidingGapIndex) {
        if (board[position] != null) return false;
      } else if (board[position] != position) {
        return false;
      }
    }
    return true;
  }

  /// Positions directly above/below/left/right of [position] on the board.
  static List<int> _neighbours(int position, int columns, int rows) {
    final int row = position ~/ columns;
    final int col = position % columns;
    final List<int> result = <int>[];
    if (row > 0) result.add(position - columns);
    if (row < rows - 1) result.add(position + columns);
    if (col > 0) result.add(position - 1);
    if (col < columns - 1) result.add(position + 1);
    return result;
  }
}