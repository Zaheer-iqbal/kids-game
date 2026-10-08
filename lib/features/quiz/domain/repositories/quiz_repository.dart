import '../../../alphabet/domain/entities/letter_item.dart';
import '../../../numbers/domain/entities/number_entity.dart';

abstract interface class QuizRepository {
  Future<List<LetterItem>> getLetters();

  Future<List<NumberEntity>> getNumbers();
}