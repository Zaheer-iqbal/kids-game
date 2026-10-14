import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/progress_service.dart';
import '../../domain/entities/animal.dart';
import '../../domain/entities/animal_puzzle.dart';
import '../../domain/repositories/puzzle_repository.dart';
import 'puzzle_event.dart';
import 'puzzle_state.dart';

/// Drives one animal puzzle: builds the board for its type, applies the
/// child's touches and celebrates when the picture is complete.
///
/// The board maths is deliberately pure and forgiving (drop anywhere near the
/// right shadow and it snaps) and the sliding shuffle is always solvable.
class PuzzleBloc extends Bloc<PuzzleEvent, PuzzleState> {
  PuzzleBloc({
    required PuzzleRepository repository,
    required ProgressService progress,
  })  : _repository = repository,
        _progress = progress,
        super(const PuzzleState()) {
    on<PuzzleStarted>(_onStarted);
    on<JigsawPiecePicked>(_onPicked);
    on<JigsawPieceAutoPlaced>(_onAutoPlaced);
    on<JigsawPieceDropped>(_onPieceDropped);
    on<SlidingTileTapped>(_onTileTapped);
    on<ShadowOptionSelected>(_onShadowSelected);
    on<HintRequested>(_onHint);
    on<PuzzleReset>(_onReset);
    on<_BonusStarEarned>(_onBonusStar);
  }

  final PuzzleRepository _repository;
  final ProgressService _progress;

  static const int _hintPenaltyCap = 2;

  // ------------------------------------------------------------- lifecycle

  Future<void> _onStarted(PuzzleStarted event, Emitter<PuzzleState> emit) async {
    final int index = event.index.clamp(0, _repository.puzzleCount - 1);
    final AnimalPuzzle puzzle = _repository.puzzleAt(index);
    final Animal animal = _repository.animalAt(index);
    final int best = _progress.puzzleStars(index);

    emit(
      PuzzleState(
        status: PuzzleStatus.playing,
        puzzle: puzzle,
        animal: animal,
        bestStars: best,
        tries: 1,
        tray: _buildTray(puzzle, index),
        slots: List<int?>.filled(puzzle.pieceCount, null),
        board: _repository.slidingBoard(index),
        initialBoard: _repository.slidingBoard(index),
        options: _repository.shadowOptions(index),
      ),
    );
  }

  /// Jigsaw pieces start shuffled in the tray; a stable seed keeps a given
  /// level's layout identical each time it is opened.
  List<int> _buildTray(AnimalPuzzle puzzle, int index) {
    if (!puzzle.isJigsaw) return const <int>[];
    final List<int> pieces = List<int>.generate(puzzle.pieceCount, (int id) => id);
    pieces.shuffle(math.Random(index * 31 + 7));
    return pieces;
  }

  // ---------------------------------------------------------------- jigsaw

  void _onPicked(JigsawPiecePicked event, Emitter<PuzzleState> emit) {
    // No state change: picking up is purely a visual affordance.
  }

  void _onAutoPlaced(JigsawPieceAutoPlaced event, Emitter<PuzzleState> emit) {
    final AnimalPuzzle? puzzle = state.puzzle;
    if (puzzle == null || !puzzle.isJigsaw || state.isSolved) return;
    _placePiece(event.pieceId, emit);
  }

  /// Places a piece into its own slot when free; otherwise shakes gently.
  void _placePiece(int pieceId, Emitter<PuzzleState> emit) {
    if (pieceId < 0 || pieceId >= state.slots.length) return;
    if (state.slots[pieceId] != null) {
      emit(state.copyWith(wrongToken: state.wrongToken + 1));
      return;
    }
    final List<int?> slots = List<int?>.of(state.slots)..[pieceId] = pieceId;
    final List<int> tray = List<int>.of(state.tray)..remove(pieceId);
    emit(
      state.copyWith(
        slots: slots,
        tray: tray,
        moves: state.moves + 1,
        clearHintSlot: state.hintSlot == pieceId,
      ),
    );
    if (tray.isEmpty) _finish(emit);
  }

  void _onPieceDropped(
    JigsawPieceDropped event,
    Emitter<PuzzleState> emit,
  ) {
    final AnimalPuzzle? puzzle = state.puzzle;
    if (puzzle == null || !puzzle.isJigsaw || state.isSolved) return;

    final int? slot = slotForDrop(
      event.localDrop,
      event.boardSize,
      puzzle.columns,
      puzzle.rows,
    );

    final bool fits = slot != null &&
        slot == event.pieceId &&
        state.slots[slot] == null;

    if (!fits) {
      emit(
        state.copyWith(
          wrongToken: state.wrongToken + 1,
          mistakes: state.mistakes + 1,
        ),
      );
      return;
    }

    final List<int?> slots = List<int?>.of(state.slots);
    slots[slot] = event.pieceId;
    final List<int> tray = List<int>.of(state.tray)
      ..remove(event.pieceId);

    final bool complete = tray.isEmpty &&
        slots.every((int? value) => value != null);

    emit(
      state.copyWith(
        slots: slots,
        tray: tray,
        moves: state.moves + 1,
        clearHintSlot: state.hintSlot == slot,
      ),
    );
    if (complete) {
      _finish(emit);
    }
  }

  /// Which slot (if any) a drop position lands on. Returns `null` when the
  /// drop is outside the board, so the piece simply floats back to the tray.
  static int? slotForDrop(
    Offset localDrop,
    Size boardSize,
    int columns,
    int rows,
  ) {
    if (boardSize.width <= 0 || boardSize.height <= 0) return null;
    if (localDrop.dx < 0 ||
        localDrop.dy < 0 ||
        localDrop.dx >= boardSize.width ||
        localDrop.dy >= boardSize.height) {
      return null;
    }
    final int col =
        (localDrop.dx / (boardSize.width / columns)).floor().clamp(0, columns - 1);
    final int row =
        (localDrop.dy / (boardSize.height / rows)).floor().clamp(0, rows - 1);
    return row * columns + col;
  }

  // --------------------------------------------------------------- sliding

  void _onTileTapped(SlidingTileTapped event, Emitter<PuzzleState> emit) {
    final AnimalPuzzle? puzzle = state.puzzle;
    if (puzzle == null || !puzzle.isSliding || state.isSolved) return;

    final int gap = state.board.indexOf(null);
    if (gap < 0) return;
    if (!isNeighbour(event.position, gap, puzzle.columns, puzzle.rows)) {
      emit(
        state.copyWith(
          wrongToken: state.wrongToken + 1,
          mistakes: state.mistakes + 1,
        ),
      );
      return;
    }

    final List<int?> board = List<int?>.of(state.board);
    board[gap] = board[event.position];
    board[event.position] = null;

    emit(state.copyWith(board: board, moves: state.moves + 1));
    if (isSolvedBoard(board, puzzle)) {
      _finish(emit);
    }
  }

  /// True when [position] shares an edge with the empty gap.
  static bool isNeighbour(int position, int gap, int columns, int rows) {
    final int row = position ~/ columns;
    final int col = position % columns;
    final int gapRow = gap ~/ columns;
    final int gapCol = gap % columns;
    return (row == gapRow && (col - gapCol).abs() == 1) ||
        (col == gapCol && (row - gapRow).abs() == 1);
  }

  static bool isSolvedBoard(List<int?> board, AnimalPuzzle puzzle) {
    for (int position = 0; position < board.length; position++) {
      if (position == puzzle.slidingGapIndex) {
        if (board[position] != null) return false;
      } else if (board[position] != position) {
        return false;
      }
    }
    return true;
  }

  // ---------------------------------------------------------- shadow match

  void _onShadowSelected(
    ShadowOptionSelected event,
    Emitter<PuzzleState> emit,
  ) {
    final Animal? animal = state.animal;
    final AnimalPuzzle? puzzle = state.puzzle;
    if (animal == null || puzzle == null || !puzzle.isShadowMatch || state.isSolved) {
      return;
    }

    if (event.animalId != animal.id) {
      emit(
        state.copyWith(
          wrongToken: state.wrongToken + 1,
          mistakes: state.mistakes + 1,
        ),
      );
      return;
    }
    emit(state.copyWith(moves: state.moves + 1, clearHintSlot: true));
    _finish(emit);
  }

  // ----------------------------------------------------------------- hints

  void _onHint(HintRequested event, Emitter<PuzzleState> emit) {
    final AnimalPuzzle? puzzle = state.puzzle;
    if (puzzle == null || state.isSolved) return;

    final int hints = state.hintsUsed + 1;
    switch (puzzle.type) {
      case AnimalPuzzleType.jigsaw:
        final int next = state.slots.indexWhere((int? value) => value == null);
        emit(
          state.copyWith(
            hintsUsed: hints,
            usedHint: true,
            hintSlot: next < 0 ? null : next,
          ),
        );
      case AnimalPuzzleType.sliding:
        emit(state.copyWith(hintsUsed: hints, usedHint: true, showGuide: true));
      case AnimalPuzzleType.shadowMatch:
        final int answer = state.options.indexOf(state.animal?.id ?? -1);
        emit(
          state.copyWith(
            hintsUsed: hints,
            usedHint: true,
            hintSlot: answer < 0 ? null : answer,
          ),
        );
    }
  }

  // ----------------------------------------------------------------- reset

  void _onReset(PuzzleReset event, Emitter<PuzzleState> emit) {
    final AnimalPuzzle? puzzle = state.puzzle;
    if (puzzle == null) return;
    emit(
      state.copyWith(
        status: PuzzleStatus.playing,
        tray: _buildTray(puzzle, puzzle.index),
        slots: List<int?>.filled(puzzle.pieceCount, null),
        board: List<int?>.of(state.initialBoard),
        showGuide: false,
        clearHintSlot: true,
        hintsUsed: 0,
        usedHint: false,
        moves: 0,
      ),
    );
  }

  // ------------------------------------------------------------------ win

  void _finish(Emitter<PuzzleState> emit) {
    final AnimalPuzzle? puzzle = state.puzzle;
    if (puzzle == null) return;
    final int stars = 3 - state.hintsUsed.clamp(0, _hintPenaltyCap);
    final int best = stars > state.bestStars ? stars : state.bestStars;
    emit(
      state.copyWith(
        status: PuzzleStatus.solved,
        starsAwarded: stars,
        bestStars: best,
        clearHintSlot: true,
      ),
    );
    // Fire-and-forget: persist stars and the hint-free streak. The bonus star
    // event arrives a moment later and the celebration awaits it itself.
    _recordSolved(puzzle.index, stars, state.usedHint);
  }

  Future<void> _recordSolved(int index, int stars, bool usedHint) async {
    final bool bonus =
        await _progress.recordPuzzleSolved(index, stars, usedHint: usedHint);
    if (!isClosed && bonus) {
      add(const _BonusStarEarned());
    }
  }

  void _onBonusStar(_BonusStarEarned event, Emitter<PuzzleState> emit) {
    emit(state.copyWith(bonusStar: true));
  }
}

/// Internal event: the hint-free bonus star landed after the win.
class _BonusStarEarned extends PuzzleEvent {
  const _BonusStarEarned();

  @override
  List<Object?> get props => <Object?>[];
}
