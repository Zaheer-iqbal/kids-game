import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/progress_service.dart';
import '../../domain/entities/animal.dart';
import '../../domain/entities/animal_puzzle.dart';
import '../../domain/repositories/puzzle_repository.dart';

/// One row on the puzzles map / in the My Animals collection.
class PuzzleCatalogEntry extends Equatable {
  const PuzzleCatalogEntry({
    required this.animal,
    required this.puzzle,
    required this.stars,
    required this.unlocked,
  });

  final Animal animal;
  final AnimalPuzzle puzzle;
  final int stars;
  final bool unlocked;

  bool get solved => stars > 0;

  @override
  List<Object?> get props => <Object?>[animal.id, stars, unlocked, puzzle.type];
}

class PuzzleCatalogState extends Equatable {
  const PuzzleCatalogState({
    this.entries = const <PuzzleCatalogEntry>[],
    this.solvedCount = 0,
    this.bonusStars = 0,
    this.totalStars = 0,
  });

  final List<PuzzleCatalogEntry> entries;
  final int solvedCount;
  final int bonusStars;
  final int totalStars;

  @override
  List<Object?> get props =>
      <Object?>[entries, solvedCount, bonusStars, totalStars];
}

/// Read-only view of the whole zoo with the child's stars and unlocks, shared
/// by the puzzles map and the My Animals collection.
class PuzzleCatalogCubit extends Cubit<PuzzleCatalogState> {
  PuzzleCatalogCubit({
    required PuzzleRepository repository,
    required ProgressService progress,
  })  : _repository = repository,
        _progress = progress,
        super(const PuzzleCatalogState());

  final PuzzleRepository _repository;
  final ProgressService _progress;

  void refresh() {
    final List<PuzzleCatalogEntry> entries = <PuzzleCatalogEntry>[
      for (Animal animal in _repository.animals)
        PuzzleCatalogEntry(
          animal: animal,
          puzzle: _repository.puzzleAt(animal.id),
          stars: _progress.puzzleStars(animal.id),
          unlocked: _progress.isPuzzleUnlocked(animal.id),
        ),
    ];
    emit(
      PuzzleCatalogState(
        entries: entries,
        solvedCount: _progress.solvedPuzzleCount,
        bonusStars: _progress.puzzleBonusStars,
        totalStars: _progress.totalStars,
      ),
    );
  }
}