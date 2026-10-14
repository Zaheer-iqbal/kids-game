import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids/core/services/progress_service.dart';
import 'package:kids/features/puzzles/data/repositories/puzzle_repository_impl.dart';
import 'package:kids/features/puzzles/domain/entities/animal_puzzle.dart';
import 'package:kids/features/puzzles/presentation/bloc/puzzle_bloc.dart';
import 'package:kids/features/puzzles/presentation/bloc/puzzle_event.dart';
import 'package:kids/features/puzzles/presentation/bloc/puzzle_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

const PuzzleRepositoryImpl zoo = PuzzleRepositoryImpl();

AnimalPuzzle puzzleAt(int index) => AnimalPuzzle.forIndex(index);

Future<void> _tick([int times = 3]) async {
  for (int i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<ProgressService> _progress({DateTime? today}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final DateTime day = today ?? DateTime(2024, 1, 1);
  return ProgressService(prefs, now: () => day);
}

void main() {
  group('Animal zoo data', () {
    test('exactly 100 animals with sequential ids', () {
      expect(zoo.puzzleCount, 100);
      expect(zoo.animals.length, 100);
      for (int i = 0; i < zoo.animals.length; i++) {
        expect(zoo.animals[i].id, i);
      }
    });

    test('every animal has a name, emoji, sound and fact', () {
      for (final animal in zoo.animals) {
        expect(animal.name.trim(), isNotEmpty, reason: 'animal ${animal.id}');
        expect(animal.emoji.trim(), isNotEmpty, reason: animal.name);
        expect(animal.sound.trim(), isNotEmpty, reason: animal.name);
        expect(animal.fact.trim(), isNotEmpty, reason: animal.name);
        expect(animal.celebrationLine, '${animal.name}! ${animal.sound}');
      }
    });

    test('names and emoji stickers are all distinct', () {
      final Set<String> names = <String>{};
      final Set<String> emoji = <String>{};
      for (final animal in zoo.animals) {
        expect(names.add(animal.name), isTrue, reason: 'dup ${animal.name}');
        expect(emoji.add(animal.emoji), isTrue, reason: 'dup ${animal.emoji}');
      }
      expect(names.length, 100);
      expect(emoji.length, 100);
    });
  });

  group('Puzzle rules', () {
    test('every 7th level is a 3x2 shadow match', () {
      for (int i = 0; i < 100; i++) {
        if ((i + 1) % 7 != 0) continue;
        final puzzle = puzzleAt(i);
        expect(puzzle.type, AnimalPuzzleType.shadowMatch, reason: 'level ${i + 1}');
        expect(puzzle.columns, 3);
        expect(puzzle.rows, 2);
      }
    });

    test('every 5th (non-7th) level is a 3x3 sliding puzzle', () {
      for (int i = 0; i < 100; i++) {
        final int ordinal = i + 1;
        if (ordinal % 5 != 0 || ordinal % 7 == 0) continue;
        final puzzle = puzzleAt(i);
        expect(puzzle.type, AnimalPuzzleType.sliding, reason: 'level $ordinal');
        expect(puzzle.columns, 3);
        expect(puzzle.rows, 3);
      }
    });

    test('jigsaw grids grow in steps and piece counts match', () {
      expect(puzzleAt(0).columns, 2);
      expect(puzzleAt(0).rows, 2);
      expect(puzzleAt(30).columns, 2); // level 31
      expect(puzzleAt(30).rows, 3);
      expect(puzzleAt(60).columns, 3); // level 61
      expect(puzzleAt(60).rows, 3);
      expect(puzzleAt(85).columns, 3); // level 86
      expect(puzzleAt(85).rows, 4);
      for (int i = 0; i < 100; i++) {
        final puzzle = puzzleAt(i);
        expect(puzzle.pieceCount, puzzle.columns * puzzle.rows);
        expect(puzzle.levelNumber, i + 1);
      }
    });
  });

  group('Sliding boards', () {
    test('are permutations with one gap and never pre-solved', () {
      for (final int index in <int>[4, 9, 14, 19, 24, 29]) {
        final List<int?> board = zoo.slidingBoard(index);
        final List<int> tiles = board.whereType<int>().toList();
        expect(board.length, 9);
        expect(board.where((int? v) => v == null).length, 1, reason: '$index');
        expect(tiles.length, 8);
        expect(tiles.toSet().length, 8);
        expect(tiles.every((int t) => t >= 0 && t < 9), isTrue);
        expect(PuzzleBloc.isSolvedBoard(board, puzzleAt(index)), isFalse);
      }
    });

    test('every shuffle is solvable (even inversion parity)', () {
      for (int i = 0; i < 100; i++) {
        if (!puzzleAt(i).isSliding) continue;
        final List<int?> board = zoo.slidingBoard(i);
        final List<int> flat = board.whereType<int>().toList();
        int inversions = 0;
        for (int a = 0; a < flat.length; a++) {
          for (int b = a + 1; b < flat.length; b++) {
            if (flat[a] > flat[b]) inversions++;
          }
        }
        expect(inversions.isEven, isTrue, reason: 'board $i solvable');
      }
    });

    test('a shuffle is stable for a level', () {
      expect(zoo.slidingBoard(4), zoo.slidingBoard(4));
    });
  });

  group('Board helpers', () {
    test('slotForDrop maps a point to a cell and rejects outside', () {
      const Size size = Size(300, 200);
      expect(PuzzleBloc.slotForDrop(const Offset(10, 10), size, 3, 2), 0);
      expect(PuzzleBloc.slotForDrop(const Offset(290, 10), size, 3, 2), 2);
      expect(PuzzleBloc.slotForDrop(const Offset(10, 190), size, 3, 2), 3);
      expect(PuzzleBloc.slotForDrop(const Offset(-1, 10), size, 3, 2), isNull);
      expect(PuzzleBloc.slotForDrop(const Offset(10, 400), size, 3, 2), isNull);
      expect(
        PuzzleBloc.slotForDrop(const Offset(10, 10), Size.zero, 3, 2),
        isNull,
      );
    });

    test('isNeighbour accepts only edge-adjacent cells', () {
      expect(PuzzleBloc.isNeighbour(1, 0, 3, 3), isTrue);
      expect(PuzzleBloc.isNeighbour(3, 0, 3, 3), isTrue);
      expect(PuzzleBloc.isNeighbour(4, 0, 3, 3), isFalse);
      expect(PuzzleBloc.isNeighbour(8, 0, 3, 3), isFalse);
    });

    test('isSolvedBoard recognizes a finished board', () {
      final AnimalPuzzle puzzle = puzzleAt(4);
      expect(
        PuzzleBloc.isSolvedBoard(<int?>[0, 1, 2, 3, 4, 5, 6, 7, null], puzzle),
        isTrue,
      );
      expect(
        PuzzleBloc.isSolvedBoard(<int?>[0, 1, 2, 3, 4, 5, 6, null, 7], puzzle),
        isFalse,
      );
    });
  });

  group('PuzzleBloc', () {
    test('a jigsaw solves; a hint costs one star; stars persist', () async {
      final ProgressService progress = await _progress();
      final PuzzleBloc bloc =
          PuzzleBloc(repository: const PuzzleRepositoryImpl(), progress: progress);

      bloc.add(const PuzzleStarted(0));
      await _tick();
      expect(bloc.state.status, PuzzleStatus.playing);
      expect(bloc.state.puzzle!.isJigsaw, isTrue);
      expect(bloc.state.tray.length, 4);

      bloc.add(const HintRequested());
      await _tick();
      expect(bloc.state.hintsUsed, 1);
      expect(bloc.state.hintSlot, 0);

      for (int id = 0; id < 4; id++) {
        bloc.add(JigsawPieceAutoPlaced(id));
      }
      await _tick(6);

      expect(bloc.state.isSolved, isTrue);
      expect(bloc.state.starsAwarded, 2);
      expect(progress.puzzleStars(0), 2);
      await bloc.close();
    });

    test('a mis-dropped piece is a mistake, not progress', () async {
      final ProgressService progress = await _progress();
      final PuzzleBloc bloc =
          PuzzleBloc(repository: const PuzzleRepositoryImpl(), progress: progress);
      bloc.add(const PuzzleStarted(0));
      await _tick();

      bloc.add(
        const JigsawPieceDropped(
          pieceId: 1,
          localDrop: Offset(5, 5),
          boardSize: Size(200, 200),
        ),
      );
      await _tick();
      expect(bloc.state.mistakes, 1);
      expect(bloc.state.slots[0], isNull);
      expect(bloc.state.isSolved, isFalse);
      await bloc.close();
    });

    test('a shadow match solves on the right silhouette', () async {
      final ProgressService progress = await _progress();
      final PuzzleBloc bloc =
          PuzzleBloc(repository: const PuzzleRepositoryImpl(), progress: progress);
      bloc.add(const PuzzleStarted(6));
      await _tick();
      expect(bloc.state.puzzle!.isShadowMatch, isTrue);
      expect(bloc.state.options, contains(6));
      expect(bloc.state.options.toSet().length, bloc.state.options.length);

      final int wrong = bloc.state.options.firstWhere((int id) => id != 6);
      bloc.add(ShadowOptionSelected(wrong));
      await _tick();
      expect(bloc.state.mistakes, 1);
      expect(bloc.state.isSolved, isFalse);

      bloc.add(const ShadowOptionSelected(6));
      await _tick(4);
      expect(bloc.state.isSolved, isTrue);
      expect(bloc.state.starsAwarded, 3);
      expect(progress.puzzleStars(6), 3);
      await bloc.close();
    });

    test('a sliding tap moves only into the gap', () async {
      final ProgressService progress = await _progress();
      final PuzzleBloc bloc =
          PuzzleBloc(repository: const PuzzleRepositoryImpl(), progress: progress);
      bloc.add(const PuzzleStarted(4)); // level 5 -> sliding
      await _tick();
      expect(bloc.state.puzzle!.isSliding, isTrue);

      final AnimalPuzzle puzzle = bloc.state.puzzle!;
      final int gap = bloc.state.board.indexOf(null);
      final int neighbour = List<int>.generate(puzzle.pieceCount, (int i) => i)
          .firstWhere((int i) =>
              PuzzleBloc.isNeighbour(i, gap, puzzle.columns, puzzle.rows));
      final int far = List<int>.generate(puzzle.pieceCount, (int i) => i)
          .firstWhere((int i) =>
              !PuzzleBloc.isNeighbour(i, gap, puzzle.columns, puzzle.rows));

      final int farTile = bloc.state.board[far]!;
      bloc.add(SlidingTileTapped(far));
      await _tick();
      expect(bloc.state.mistakes, 1);
      expect(bloc.state.board[far], farTile);

      final int neighbourTile = bloc.state.board[neighbour]!;
      bloc.add(SlidingTileTapped(neighbour));
      await _tick();
      expect(bloc.state.board[gap], neighbourTile);
      expect(bloc.state.board[neighbour], isNull);
      expect(bloc.state.moves, 1);
      await bloc.close();
    });
  });

  group('Puzzle progress', () {
    test('solving unlocks the next puzzle', () async {
      final ProgressService progress = await _progress();
      expect(progress.isPuzzleUnlocked(0), isTrue);
      expect(progress.isPuzzleUnlocked(1), isFalse);

      await progress.recordPuzzleSolved(0, 3, usedHint: false);
      expect(progress.isPuzzleUnlocked(1), isTrue);
      expect(progress.solvedPuzzleCount, 1);
      expect(progress.isAnimalUnlocked(0), isTrue);
      expect(progress.totalStars, 3);
    });

    test('three hint-free wins award a bonus star', () async {
      final ProgressService progress = await _progress();
      expect(await progress.recordPuzzleSolved(0, 3, usedHint: false), isFalse);
      expect(await progress.recordPuzzleSolved(1, 3, usedHint: false), isFalse);
      expect(await progress.recordPuzzleSolved(2, 3, usedHint: false), isTrue);
      expect(progress.puzzleBonusStars, 1);
      expect(progress.hintlessPuzzleStreak, 0);

      await progress.recordPuzzleSolved(3, 2, usedHint: true);
      expect(progress.hintlessPuzzleStreak, 0);
      expect(progress.puzzleStars(3), 2);
    });
  });
}
