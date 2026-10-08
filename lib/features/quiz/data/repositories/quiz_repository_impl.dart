import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../alphabet/data/models/letter_model.dart';
import '../../../alphabet/domain/entities/letter_item.dart';
import '../../../numbers/data/models/number_model.dart';
import '../../../numbers/domain/entities/number_entity.dart';
import '../../domain/repositories/quiz_repository.dart';

class QuizRepositoryImpl implements QuizRepository {
  static const String _lettersAssetPath = 'assets/data/alphabet.json';
  static const String _numbersAssetPath = 'assets/data/numbers.json';

  @override
  Future<List<LetterItem>> getLetters() async {
    final String raw = await rootBundle.loadString(_lettersAssetPath);
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic item) =>
              LetterModel.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<List<NumberEntity>> getNumbers() async {
    final String raw = await rootBundle.loadString(_numbersAssetPath);
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic item) =>
              NumberModel.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}