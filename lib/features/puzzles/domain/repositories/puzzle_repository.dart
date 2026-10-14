import '../entities/animal.dart';
import '../entities/animal_puzzle.dart';

/// Read-only access to the puzzle zoo.
abstract class PuzzleRepository {
  /// Exactly 100 animals, in map order.
  List<Animal> get animals;

  int get puzzleCount;

  Animal animalAt(int index);

  AnimalPuzzle puzzleAt(int index);

  /// The 2-4 silhouettes shown on a shadow-match level: the real animal plus
  /// friendly decoys. The answer is always included and the order is stable
  /// for a given [index].
  List<int> shadowOptions(int index);

  /// A shuffled-but-solvable sliding board: tile ids in reading order with a
  /// `null` gap at the empty slot. Built by walking back from the solved
  /// state, so it can always be finished.
  List<int?> slidingBoard(int index, {int shuffleMoves = 60});
}