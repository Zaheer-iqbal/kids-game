import 'package:equatable/equatable.dart';

import '../../domain/lesson.dart';

enum LessonStatus { ready, finished }

class LessonState extends Equatable {
  const LessonState({
    this.status = LessonStatus.ready,
    this.stepIndex = 0,
    this.answered = false,
    this.wrongKey,
    this.wrongToken = 0,
    this.mistakes = 0,
    this.stars = 0,
  });

  final LessonStatus status;
  final int stepIndex;

  /// The current step has been completed (shows the Next button / celebration).
  final bool answered;

  /// Option key that was just tapped wrong (drives the shake).
  final String? wrongKey;

  /// Increments on every mistake so the shake retriggers.
  final int wrongToken;

  final int mistakes;

  /// Stars earned, set once the lesson is finished.
  final int stars;

  static const Object _unset = Object();

  LessonState copyWith({
    LessonStatus? status,
    int? stepIndex,
    bool? answered,
    Object? wrongKey = _unset,
    int? wrongToken,
    int? mistakes,
    int? stars,
  }) {
    return LessonState(
      status: status ?? this.status,
      stepIndex: stepIndex ?? this.stepIndex,
      answered: answered ?? this.answered,
      wrongKey: identical(wrongKey, _unset) ? this.wrongKey : wrongKey as String?,
      wrongToken: wrongToken ?? this.wrongToken,
      mistakes: mistakes ?? this.mistakes,
      stars: stars ?? this.stars,
    );
  }

  LessonStep stepIn(Lesson lesson) => lesson.steps[stepIndex];

  @override
  List<Object?> get props => <Object?>[
        status,
        stepIndex,
        answered,
        wrongKey,
        wrongToken,
        mistakes,
        stars,
      ];
}
