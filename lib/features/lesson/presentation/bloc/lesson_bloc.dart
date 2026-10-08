import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/audio_service.dart';
import '../../../../core/services/progress_service.dart';
import '../../domain/lesson.dart';
import 'lesson_event.dart';
import 'lesson_state.dart';

/// Drives one playable lesson: validates answers, counts mistakes, awards
/// stars when the last step is finished and records the explored glyphs.
class LessonBloc extends Bloc<LessonEvent, LessonState> {
  LessonBloc({
    required this.lesson,
    required AudioService audioService,
    required ProgressService progressService,
  })  : _audio = audioService,
        _progress = progressService,
        super(const LessonState()) {
    on<LessonAnswered>(_onAnswered);
    on<LessonStepCompleted>(_onStepCompleted);
    on<LessonNextPressed>(_onNext);
  }

  final Lesson lesson;
  final AudioService _audio;
  final ProgressService _progress;

  LessonStep get _step => lesson.steps[state.stepIndex];
  bool get _isLast => state.stepIndex == lesson.steps.length - 1;

  String? get _answerKey => switch (_step) {
        PickStep(:final LessonGlyph target) => target.key,
        MatchStep(:final LessonGlyph target) => target.key,
        CountStep(:final LessonGlyph target) => target.key,
        MeetStep() || TraceStep() => null,
      };

  Future<void> _onAnswered(
    LessonAnswered event,
    Emitter<LessonState> emit,
  ) async {
    if (state.answered || _answerKey == null) return;

    if (event.key == _answerKey) {
      emit(state.copyWith(answered: true, wrongKey: null));
      await _audio.playDing();
      return;
    }

    emit(state.copyWith(
      mistakes: state.mistakes + 1,
      wrongKey: event.key,
      wrongToken: state.wrongToken + 1,
    ));
    await _audio.playBoop();
  }

  Future<void> _onStepCompleted(
    LessonStepCompleted event,
    Emitter<LessonState> emit,
  ) async {
    if (state.answered) return;
    emit(state.copyWith(answered: true));
    await _audio.playTraceChime();
  }

  Future<void> _onNext(
    LessonNextPressed event,
    Emitter<LessonState> emit,
  ) async {
    final bool needsAnswer =
        _step is! MeetStep && !state.answered;
    if (needsAnswer) return;

    if (_isLast) {
      final int stars = switch (state.mistakes) {
        0 => 3,
        <= 2 => 2,
        _ => 1,
      };
      emit(state.copyWith(
        status: LessonStatus.finished,
        stars: stars,
        answered: true,
      ));
      await _finish(stars);
      return;
    }

    emit(state.copyWith(
      stepIndex: state.stepIndex + 1,
      answered: false,
      wrongKey: null,
    ));
    await _audio.playPop();
  }

  Future<void> _finish(int stars) async {
    await _progress.awardStars(lesson.worldId, lesson.level, stars);
    for (final LessonGlyph glyph in lesson.glyphs) {
      if (lesson.worldId == 'alphabet') {
        await _progress.markLetterExplored(glyph.key);
      } else {
        await _progress.markNumberExplored(int.parse(glyph.key));
      }
    }
    await _audio.playFanfare();
    await _audio.playLevelUp();
  }
}
