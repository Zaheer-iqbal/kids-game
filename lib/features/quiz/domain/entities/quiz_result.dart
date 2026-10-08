import 'package:equatable/equatable.dart';

import 'quiz_type.dart';

/// Outcome of one finished quiz, handed to the results screen.
class QuizResult extends Equatable {
  const QuizResult({
    required this.type,
    required this.score,
    required this.totalQuestions,
    required this.newHighScore,
    required this.bestScore,
  });

  final QuizType type;
  final int score;
  final int totalQuestions;
  final bool newHighScore;
  final int bestScore;

  @override
  List<Object?> get props =>
      <Object?>[type, score, totalQuestions, newHighScore, bestScore];
}