import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/audio_service.dart';
import '../../../../core/services/progress_service.dart';
import '../../domain/repositories/number_repository.dart';
import 'number_event.dart';
import 'number_state.dart';

class NumberBloc extends Bloc<NumberEvent, NumberState> {
  NumberBloc({
    required NumberRepository repository,
    required AudioService audioService,
    required ProgressService progressService,
  })  : _repository = repository,
        _audioService = audioService,
        _progressService = progressService,
        super(const NumberInitial()) {
    on<LoadNumbers>(_onLoadNumbers);
    on<NumberTapped>(_onNumberTapped);
  }

  final NumberRepository _repository;
  final AudioService _audioService;
  final ProgressService _progressService;

  Future<void> _onLoadNumbers(
    LoadNumbers event,
    Emitter<NumberState> emit,
  ) async {
    emit(const NumberLoading());
    try {
      final numbers = await _repository.getNumbers();
      numbers.sort((a, b) => a.number.compareTo(b.number));
      emit(NumberLoaded(
        numbers: numbers,
        explored: _progressService.exploredNumbers,
      ));
    } catch (_) {
      emit(const NumberError('Could not load the numbers.'));
    }
  }

  Future<void> _onNumberTapped(
    NumberTapped event,
    Emitter<NumberState> emit,
  ) async {
    final NumberState current = state;
    // Persistence is what the UI reflects, so let it complete. Narration is a
    // fire-and-forget side effect: the TTS future must never gate the explored
    // badge/header update (it can hang when the platform engine is absent).
    await _progressService.markNumberExplored(event.number.number);
    unawaited(
      _audioService.speakNumber(event.number.word, value: event.number.number),
    );
    if (current is NumberLoaded) {
      emit(NumberLoaded(
        numbers: current.numbers,
        explored: _progressService.exploredNumbers,
      ));
    }
  }
}