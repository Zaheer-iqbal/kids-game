import '../entities/number_entity.dart';

abstract interface class NumberRepository {
  Future<List<NumberEntity>> getNumbers();
}