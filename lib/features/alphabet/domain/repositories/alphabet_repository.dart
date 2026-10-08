import '../entities/letter_item.dart';

abstract interface class AlphabetRepository {
  Future<List<LetterItem>> getLetters();
}