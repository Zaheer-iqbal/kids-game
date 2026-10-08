import 'package:equatable/equatable.dart';

import '../../domain/entities/letter_item.dart';

sealed class AlphabetState extends Equatable {
  const AlphabetState();

  @override
  List<Object?> get props => const <Object?>[];
}

class AlphabetInitial extends AlphabetState {
  const AlphabetInitial();
}

class AlphabetLoading extends AlphabetState {
  const AlphabetLoading();
}

class AlphabetLoaded extends AlphabetState {
  const AlphabetLoaded({required this.letters, required this.explored});

  final List<LetterItem> letters;
  final Set<String> explored;

  int get exploredCount => explored.length;

  @override
  List<Object?> get props => <Object?>[letters, explored];
}

class AlphabetError extends AlphabetState {
  const AlphabetError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}