import 'package:equatable/equatable.dart';

import 'quiz_option.dart';

/// One round of any quiz game: the text shown, the words spoken aloud, the
/// answer and the choices.
class QuizQuestion extends Equatable {
  const QuizQuestion({
    required this.promptTitle,
    required this.spokenPrompt,
    required this.options,
    required this.targetKey,
  });

  /// Instruction text displayed under the sound button, e.g. "Tap the picture
  /// this sound says!".
  final String promptTitle;

  /// Text read out loud when the question is asked (may be empty for the
  /// letter mode, which speaks the phonics separately).
  final String? spokenPrompt;

  /// Choices for this round, already shuffled.
  final List<QuizOption> options;

  /// Key of the correct option.
  final String targetKey;

  @override
  List<Object?> get props => <Object?>[promptTitle, spokenPrompt, options, targetKey];
}