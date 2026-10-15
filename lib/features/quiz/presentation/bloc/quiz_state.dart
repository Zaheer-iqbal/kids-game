import 'package:equatable/equatable.dart';

import '../../domain/entities/quiz_option.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/entities/quiz_type.dart';

enum QuizStatus { initial, loading, ready, finished, error }

class QuizState extends Equatable {
  const QuizState({
    this.status = QuizStatus.initial,
    this.quizType = QuizType.letterSounds,
    this.promptTitle = '',
    this.spokenPrompt,
    this.options = const <QuizOption>[],
    this.targetKey,
    this.score = 0,
    this.highScore = 0,
    this.wrongOption,
    this.revealCorrect = false,
    this.wrongToken = 0,
    this.questionNumber = 0,
    this.totalQuestions = 10,
    this.newHighScore = false,
    this.result,
    this.error,
    this.hintsUsed = 0,
    this.hiddenKeys = const <String>[],
    this.hintMessage,
    this.hintToken = 0,
  });

  final QuizStatus status;
  final QuizType quizType;

  /// Instruction text shown under the sound button for the current round.
  final String promptTitle;

  /// Text spoken aloud for the current round (null for letter phonics, which
  /// is spoken through the dedicated phonics call).
  final String? spokenPrompt;

  final List<QuizOption> options;

  /// Key of the correct option for the current round.
  final String? targetKey;

  final int score;
  final int highScore;

  /// Key of the option that was just tapped wrong (drives the shake).
  final String? wrongOption;

  /// True while the correct answer is being celebrated before the next round.
  final bool revealCorrect;

  /// Increments whenever a wrong option is tapped so the shake retriggers.
  final int wrongToken;

  final int questionNumber;
  final int totalQuestions;
  final bool newHighScore;

  /// Set once the quiz finishes (carried to the results screen).
  final QuizResult? result;

  final String? error;

  /// How many hints have been spent on the current question.
  final int hintsUsed;

  /// Keys of wrong options a hint has already removed from view for the
  /// current question. The options themselves stay in [options] so the layout
  /// and tests are unaffected — the cards just fade these out.
  final List<String> hiddenKeys;

  /// The line the owl last said when a hint was spent (drives its bubble).
  final String? hintMessage;

  /// Bumped on every hint so the owl replays its talking animation.
  final int hintToken;

  /// True when the child can still take a hint on this question: at most two
  /// per question, and never on an easy two-choice round.
  bool get canHint =>
      status == QuizStatus.ready &&
      !revealCorrect &&
      options.length > 2 &&
      hintsUsed < maxHintsPerQuestion &&
      hiddenKeys.length < options.length - 1;

  /// Hints allowed per question.
  static const int maxHintsPerQuestion = 2;

  /// Sentinel so nullable fields can be explicitly cleared to null.
  /// Without it, `wrongOption ?? this.wrongOption` would keep the old value
  /// and a correct answer could never dismiss the retry state.
  static const Object _unset = Object();

  QuizState copyWith({
    QuizStatus? status,
    QuizType? quizType,
    String? promptTitle,
    Object? spokenPrompt = _unset,
    List<QuizOption>? options,
    Object? targetKey = _unset,
    int? score,
    int? highScore,
    Object? wrongOption = _unset,
    bool? revealCorrect,
    int? wrongToken,
    int? questionNumber,
    int? totalQuestions,
    bool? newHighScore,
    Object? result = _unset,
    Object? error = _unset,
    int? hintsUsed,
    List<String>? hiddenKeys,
    Object? hintMessage = _unset,
    int? hintToken,
  }) {
    return QuizState(
      status: status ?? this.status,
      quizType: quizType ?? this.quizType,
      promptTitle: promptTitle ?? this.promptTitle,
      spokenPrompt: identical(spokenPrompt, _unset)
          ? this.spokenPrompt
          : spokenPrompt as String?,
      options: options ?? this.options,
      targetKey: identical(targetKey, _unset) ? this.targetKey : targetKey as String?,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      wrongOption:
          identical(wrongOption, _unset) ? this.wrongOption : wrongOption as String?,
      revealCorrect: revealCorrect ?? this.revealCorrect,
      wrongToken: wrongToken ?? this.wrongToken,
      questionNumber: questionNumber ?? this.questionNumber,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      newHighScore: newHighScore ?? this.newHighScore,
      result: identical(result, _unset) ? this.result : result as QuizResult?,
      error: identical(error, _unset) ? this.error : error as String?,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      hiddenKeys: hiddenKeys ?? this.hiddenKeys,
      hintMessage:
          identical(hintMessage, _unset) ? this.hintMessage : hintMessage as String?,
      hintToken: hintToken ?? this.hintToken,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        quizType,
        promptTitle,
        spokenPrompt,
        options,
        targetKey,
        score,
        highScore,
        wrongOption,
        revealCorrect,
        wrongToken,
        questionNumber,
        totalQuestions,
        newHighScore,
        result,
        error,
        hintsUsed,
        hiddenKeys,
        hintMessage,
        hintToken,
      ];
}