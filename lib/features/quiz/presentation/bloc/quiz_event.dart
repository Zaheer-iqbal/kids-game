import 'package:equatable/equatable.dart';

import '../../domain/entities/quiz_option.dart';
import '../../domain/entities/quiz_type.dart';

sealed class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class QuizStarted extends QuizEvent {
  const QuizStarted([this.type = QuizType.letterSounds]);

  final QuizType type;

  @override
  List<Object?> get props => <Object?>[type];
}

class OptionSelected extends QuizEvent {
  const OptionSelected(this.option);

  final QuizOption option;

  @override
  List<Object?> get props => <Object?>[option];
}

class NextQuestion extends QuizEvent {
  const NextQuestion();
}

class ReplaySound extends QuizEvent {
  const ReplaySound();
}