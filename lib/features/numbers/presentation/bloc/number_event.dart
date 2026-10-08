import 'package:equatable/equatable.dart';

import '../../domain/entities/number_entity.dart';

sealed class NumberEvent extends Equatable {
  const NumberEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

class LoadNumbers extends NumberEvent {
  const LoadNumbers();
}

class NumberTapped extends NumberEvent {
  const NumberTapped(this.number);

  final NumberEntity number;

  @override
  List<Object?> get props => <Object?>[number];
}