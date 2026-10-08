import 'package:equatable/equatable.dart';

import '../../domain/entities/number_entity.dart';

sealed class NumberState extends Equatable {
  const NumberState();

  @override
  List<Object?> get props => const <Object?>[];
}

class NumberInitial extends NumberState {
  const NumberInitial();
}

class NumberLoading extends NumberState {
  const NumberLoading();
}

class NumberLoaded extends NumberState {
  const NumberLoaded({required this.numbers, required this.explored});

  final List<NumberEntity> numbers;
  final Set<String> explored;

  int get exploredCount => explored.length;

  @override
  List<Object?> get props => <Object?>[numbers, explored];
}

class NumberError extends NumberState {
  const NumberError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}