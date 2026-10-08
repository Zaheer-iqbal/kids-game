import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/letter_item.dart';
import '../../domain/repositories/alphabet_repository.dart';
import '../models/letter_model.dart';

class AlphabetRepositoryImpl implements AlphabetRepository {
  static const String _assetPath = 'assets/data/alphabet.json';

  @override
  Future<List<LetterItem>> getLetters() async {
    final String raw = await rootBundle.loadString(_assetPath);
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic item) =>
              LetterModel.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}