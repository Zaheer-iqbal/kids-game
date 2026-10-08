import 'package:equatable/equatable.dart';

import '../../domain/entities/letter_item.dart';

sealed class AlphabetEvent extends Equatable {
  const AlphabetEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class LoadAlphabet extends AlphabetEvent {
  const LoadAlphabet();
}

class LetterTapped extends AlphabetEvent {
  const LetterTapped(this.letter);

  final LetterItem letter;

  @override
  List<Object?> get props => <Object?>[letter];
}