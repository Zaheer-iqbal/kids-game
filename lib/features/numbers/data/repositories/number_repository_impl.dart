import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/number_entity.dart';
import '../../domain/repositories/number_repository.dart';
import '../models/number_model.dart';

class NumberRepositoryImpl implements NumberRepository {
  static const String _assetPath = 'assets/data/numbers.json';

  @override
  Future<List<NumberEntity>> getNumbers() async {
    final String raw = await rootBundle.loadString(_assetPath);
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic item) =>
              NumberModel.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}