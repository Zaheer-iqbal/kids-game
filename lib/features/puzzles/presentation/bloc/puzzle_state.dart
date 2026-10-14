import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/animal.dart';
import '../../domain/entities/animal_puzzle.dart';

enum PuzzleStatus { loading, playing, solved }

/// Everything one puzzle session needs: the board, the child's progress and
/// the little "oops" signals the views animate.
@immutable
class PuzzleState extends Equatable {
  const PuzzleState({
    this.status = PuzzleStatus.loading,
    this.puzzle,
    this.animal,
    this.tray = const <int>[],
    this.slots = const <int?>[],
    this.hintSlot,
    this.board = const <int?>[],
    this.initialBoard = const <int?>[],
    this.showGuide = false,
    this.options = const <int>[],
    this.hintsUsed = 0,
    this.mistakes = 0,
    this.moves = 0,
    this.wrongToken = 0,
    this.starsAwarded = 0,
    this.bonusStar = false,
    this.bestStars = 0,
    this.usedHint = false,
    this.tries = 0,
  });

  final PuzzleStatus status;
  final AnimalPuzzle? puzzle;
  final Animal? animal;

  /// Jigsaw pieces still waiting in the tray.
  final List<int> tray;

  /// Jigsaw slots: index is the slot position, value is the piece id in it
  /// (`null` while empty). A piece only fits its own slot.
  final List<int?> slots;

  /// The slot the current hint points at, if any.
  final int? hintSlot;

  /// Sliding board: index is the board position, value is the tile id
  /// (`null` is the empty gap).
  final List<int?> board;
  final List<int?> initialBoard;
  final bool showGuide;

  /// Shadow-match silhouettes (animal ids); exactly one is the answer.
  final List<int> options;

  final int hintsUsed;
  final int mistakes;
  final int moves;

  /// Bumped on every rejected touch so the view can play a gentle shake.
  final int wrongToken;

  final int starsAwarded;
  final bool bonusStar;
  final int bestStars;
  final bool usedHint;

  /// How many times the child has played into this level (for the parent
  /// dashboard "attempts" figure).
  final int tries;

  bool get isLoading => status == PuzzleStatus.loading;
  bool get isSolved => status == PuzzleStatus.solved;

  int get pieceCount => puzzle?.pieceCount ?? 0;

  /// 0-1 completion, used by the progress bar.
  double get progress {
    if (puzzle == null) return 0;
    switch (puzzle!.type) {
      case AnimalPuzzleType.jigsaw:
        final int filled = slots.whereType<int>().length;
        return pieceCount == 0 ? 0 : filled / pieceCount;
      case AnimalPuzzleType.sliding:
        int correct = 0;
        for (int i = 0; i < board.length; i++) {
          if (board[i] == i) correct++;
        }
        return board.isEmpty ? 0 : correct / board.length;
      case AnimalPuzzleType.shadowMatch:
        return isSolved ? 1 : 0;
    }
  }

  PuzzleState copyWith({
    PuzzleStatus? status,
    AnimalPuzzle? puzzle,
    Animal? animal,
    List<int>? tray,
    List<int?>? slots,
    int? hintSlot,
    bool clearHintSlot = false,
    List<int?>? board,
    List<int?>? initialBoard,
    bool? showGuide,
    List<int>? options,
    int? hintsUsed,
    int? mistakes,
    int? moves,
    int? wrongToken,
    int? starsAwarded,
    bool? bonusStar,
    int? bestStars,
    bool? usedHint,
    int? tries,
  }) {
    return PuzzleState(
      status: status ?? this.status,
      puzzle: puzzle ?? this.puzzle,
      animal: animal ?? this.animal,
      tray: tray ?? this.tray,
      slots: slots ?? this.slots,
      hintSlot: clearHintSlot ? null : (hintSlot ?? this.hintSlot),
      board: board ?? this.board,
      initialBoard: initialBoard ?? this.initialBoard,
      showGuide: showGuide ?? this.showGuide,
      options: options ?? this.options,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      mistakes: mistakes ?? this.mistakes,
      moves: moves ?? this.moves,
      wrongToken: wrongToken ?? this.wrongToken,
      starsAwarded: starsAwarded ?? this.starsAwarded,
      bonusStar: bonusStar ?? this.bonusStar,
      bestStars: bestStars ?? this.bestStars,
      usedHint: usedHint ?? this.usedHint,
      tries: tries ?? this.tries,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        puzzle?.index,
        animal?.id,
        tray,
        slots,
        hintSlot,
        board,
        initialBoard,
        showGuide,
        options,
        hintsUsed,
        mistakes,
        moves,
        wrongToken,
        starsAwarded,
        bonusStar,
        bestStars,
        usedHint,
        tries,
      ];
}