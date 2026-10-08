import 'package:shared_preferences/shared_preferences.dart';

/// Local-only progress tracking (no accounts, no backend).
///
/// Persists the set of explored letters, the set of explored numbers, the
/// all-time best quiz score, and the best score per quiz mode.
class ProgressService {
  ProgressService(this._prefs);

  final SharedPreferences _prefs;

  static const String _exploredKey = 'explored_letters';
  static const String _exploredNumbersKey = 'explored_numbers';
  static const String _highScoreKey = 'quiz_high_score';
  static const String _bestsKey = 'quiz_best_scores';

  Set<String> get exploredLetters =>
      (_prefs.getStringList(_exploredKey) ?? const <String>[]).toSet();

  int get exploredCount => exploredLetters.length;

  Future<void> markLetterExplored(String letter) async {
    final Set<String> current = exploredLetters;
    if (current.add(letter)) {
      await _prefs.setStringList(_exploredKey, (current.toList()..sort()));
    }
  }

  Set<String> get exploredNumbers =>
      (_prefs.getStringList(_exploredNumbersKey) ?? const <String>[]).toSet();

  int get exploredNumberCount => exploredNumbers.length;

  Future<void> markNumberExplored(int number) async {
    final Set<String> current = exploredNumbers;
    if (current.add('$number')) {
      await _prefs.setStringList(_exploredNumbersKey, (current.toList()..sort()));
    }
  }

  int get quizHighScore => _prefs.getInt(_highScoreKey) ?? 0;

  Future<void> updateQuizHighScore(int score) async {
    if (score > quizHighScore) {
      await _prefs.setInt(_highScoreKey, score);
    }
  }

  /// Best score for one quiz mode, keyed by [QuizType.name].
  int bestScoreFor(String type) => _prefs.getInt('$_bestsKey.$type') ?? 0;

  Future<void> updateBestScore(String type, int score) async {
    if (score > bestScoreFor(type)) {
      await _prefs.setInt('$_bestsKey.$type', score);
    }
  }

  // ------------------------------------------------------ adventure levels

  static const String _levelStarsPrefix = 'level_stars_';

  /// Stars (0-3) earned on one adventure-map level.
  int starsForLevel(String worldId, int level) =>
      _prefs.getInt('$_levelStarsPrefix$worldId$level') ?? 0;

  /// Keeps the best result for a level (replaying never lowers a score).
  Future<void> awardStars(String worldId, int level, int stars) async {
    if (stars <= starsForLevel(worldId, level)) return;
    await _prefs.setInt('$_levelStarsPrefix$worldId$level', stars);
  }

  /// True when a level can be played: the first level is always open and the
  /// rest unlock as the previous one is completed.
  bool isLevelUnlocked(String worldId, int level) =>
      level == 0 || starsForLevel(worldId, level - 1) > 0;

  /// Total stars across every world (drives the top bar counter).
  int get totalStars {
    int total = 0;
    for (final String key in _prefs.getKeys()) {
      if (key.startsWith(_levelStarsPrefix)) {
        total += _prefs.getInt(key) ?? 0;
      }
    }
    return total;
  }

  // ---------------------------------------------------------------- streak

  static const String _streakCountKey = 'streak_count';
  static const String _streakDayKey = 'streak_last_day';

  /// Consecutive days the child has played (0 for a brand new install).
  int get streakDays => _prefs.getInt(_streakCountKey) ?? 0;

  /// Called whenever the map is opened: keeps the daily streak alive.
  Future<void> touchStreak() async {
    final DateTime today = DateTime.now();
    final String todayKey = _dayKey(today);
    final String? lastKey = _prefs.getString(_streakDayKey);
    if (lastKey == todayKey) return;

    final DateTime? last =
        lastKey == null ? null : DateTime.tryParse(lastKey);
    int daysSinceLast = -1;
    if (last != null) {
      daysSinceLast = DateTime(today.year, today.month, today.day)
          .difference(DateTime(last.year, last.month, last.day))
          .inDays;
    }
    final int next = daysSinceLast == 1 ? streakDays + 1 : 1;
    await _prefs.setString(_streakDayKey, todayKey);
    await _prefs.setInt(_streakCountKey, next);
  }

  String _dayKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}