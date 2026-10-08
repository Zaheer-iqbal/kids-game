import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The three worlds on the adventure map.
enum WorldId {
  alphabet('alphabet'),
  numbers('numbers'),
  quiz('quiz');

  const WorldId(this.storageKey);

  /// Key used in persistence (level stars, etc.).
  final String storageKey;
}

/// One world on the map: its look, how its levels are chunked and how to
/// address them in routes.
class AdventureWorld {
  const AdventureWorld({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.colorEnd,
    required this.levelSizes,
  });

  final WorldId id;
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final Color colorEnd;

  /// How many letters/numbers each level covers (quiz levels are 1 each).
  final List<int> levelSizes;

  int get levelCount => levelSizes.length;

  /// Total lesson items in the world (26 letters, 100 numbers, 4 quizzes).
  int get totalItems => levelSizes.fold<int>(0, (int sum, int size) => sum + size);

  /// First and last letter of one alphabet level, e.g. ("A", "E").
  ({String from, String to}) lettersForLevel(int level) {
    int first = 0;
    for (int i = 0; i < level; i++) {
      first += levelSizes[i];
    }
    final int last = first + levelSizes[level] - 1;
    return (
      from: String.fromCharCode(65 + first),
      to: String.fromCharCode(65 + last),
    );
  }

  /// First and last number of one numbers level, e.g. (1, 10).
  ({int from, int to}) numbersForLevel(int level) {
    int first = 1;
    for (int i = 0; i < level; i++) {
      first += levelSizes[i];
    }
    return (from: first, to: first + levelSizes[level] - 1);
  }

  /// Everything the adventure map needs, in map order.
  static const List<AdventureWorld> all = <AdventureWorld>[
    AdventureWorld(
      id: WorldId.alphabet,
      title: 'Alphabet Land',
      subtitle: 'Learn letters, sounds and tracing',
      emoji: '🔤',
      color: AppColors.accentCoral,
      colorEnd: AppColors.accentPink,
      // 26 letters in six bite-size lessons of 3-5.
      levelSizes: <int>[5, 5, 5, 5, 3, 3],
    ),
    AdventureWorld(
      id: WorldId.numbers,
      title: 'Number Jungle',
      subtitle: 'Count, read and match 1-100',
      emoji: '🌴',
      color: AppColors.accentMint,
      colorEnd: Color(0xFF10B981),
      // Ten levels of ten numbers each.
      levelSizes: <int>[10, 10, 10, 10, 10, 10, 10, 10, 10, 10],
    ),
    AdventureWorld(
      id: WorldId.quiz,
      title: 'Quiz Arena',
      subtitle: 'Four tricky games to show what you know',
      emoji: '🏆',
      color: AppColors.accentPurple,
      colorEnd: AppColors.accentPink,
      // One level per quiz mode.
      levelSizes: <int>[1, 1, 1, 1],
    ),
  ];

  static AdventureWorld byId(WorldId id) =>
      all.firstWhere((AdventureWorld world) => world.id == id);

  static AdventureWorld? tryParse(String? storageKey) {
    for (final AdventureWorld world in all) {
      if (world.id.storageKey == storageKey) return world;
    }
    return null;
  }
}
