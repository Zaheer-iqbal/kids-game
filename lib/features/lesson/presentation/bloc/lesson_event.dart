import 'package:equatable/equatable.dart';

sealed class LessonEvent extends Equatable {
  const LessonEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The child tapped "Next" after finishing the current step.
class LessonNextPressed extends LessonEvent {
  const LessonNextPressed();
}

/// The child tapped an answer option ([key] is the option's glyph key).
class LessonAnswered extends LessonEvent {
  const LessonAnswered(this.key);

  final String key;

  @override
  List<Object?> get props => <Object?>[key];
}

/// A step that finishes by itself (the trace was completed) is done.
class LessonStepCompleted extends LessonEvent {
  const LessonStepCompleted();
}
