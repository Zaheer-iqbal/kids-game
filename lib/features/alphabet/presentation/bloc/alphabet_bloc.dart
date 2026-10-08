import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/audio_service.dart';
import '../../../../core/services/progress_service.dart';
import '../../domain/repositories/alphabet_repository.dart';
import 'alphabet_event.dart';
import 'alphabet_state.dart';

class AlphabetBloc extends Bloc<AlphabetEvent, AlphabetState> {
  AlphabetBloc({
    required AlphabetRepository repository,
    required AudioService audioService,
    required ProgressService progressService,
  })  : _repository = repository,
        _audioService = audioService,
        _progressService = progressService,
        super(const AlphabetInitial()) {
    on<LoadAlphabet>(_onLoadAlphabet);
    on<LetterTapped>(_onLetterTapped);
  }

  final AlphabetRepository _repository;
  final AudioService _audioService;
  final ProgressService _progressService;

  Future<void> _onLoadAlphabet(
    LoadAlphabet event,
    Emitter<AlphabetState> emit,
  ) async {
    emit(const AlphabetLoading());
    try {
      final letters = await _repository.getLetters();
      letters.sort((a, b) => a.letter.compareTo(b.letter));
      emit(AlphabetLoaded(
        letters: letters,
        explored: _progressService.exploredLetters,
      ));
    } catch (_) {
      emit(const AlphabetError('Could not load the alphabet.'));
    }
  }

  Future<void> _onLetterTapped(
    LetterTapped event,
    Emitter<AlphabetState> emit,
  ) async {
    final AlphabetState current = state;
    // Persistence drives the UI update; narration is fire-and-forget so the
    // explored badge never waits on the (possibly absent) TTS engine.
    await _progressService.markLetterExplored(event.letter.letter);
    unawaited(_audioService.speakPhonics(event.letter.letter, event.letter.word));
    if (current is AlphabetLoaded) {
      emit(AlphabetLoaded(
        letters: current.letters,
        explored: _progressService.exploredLetters,
      ));
    }
  }
}