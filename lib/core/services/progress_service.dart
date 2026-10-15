import 'package:shared_preferences/shared_preferences.dart';

/// Result of registering a daily play, so the UI can greet a returning child.
enum DailyActivity { firstEver, sameDay, continued, restarted }

/// Local-only progress tracking (no accounts, no backend).
///
/// Persists explored letters/numbers, quiz scores, adventure level stars,
/// animal-puzzle progress and the daily play streak.
///
/// Day maths uses the device's local calendar (not UTC), so a child changing
/// timezone simply keeps playing: a day only ever moves forward, and a gap of
/// one day continues the streak while a bigger gap starts a friendly new one.
class ProgressService {
  ProgressService(this._prefs, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;

  /// Injectable clock so streak logic is fully testable.
  final DateTime Function() _now;

  // ------------------------------------------------------------ letters
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

  // -------------------------------------------------------------- quizzes
  int get quizHighScore => _prefs.getInt(_highScoreKey) ?? 0;

  Future<void> updateQuizHighScore(int score) async {
    if (score > quizHighScore) {
      await _prefs.setInt(_highScoreKey, score);
    }
    // Finishing a quiz always counts as today's play.
    await recordDailyActivity();
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
    if (stars > starsForLevel(worldId, level)) {
      await _prefs.setInt('$_levelStarsPrefix$worldId$level', stars);
    }
    // Completing a lesson keeps the daily flame alive.
    await recordDailyActivity();
  }

  /// True when a level can be played: the first level is always open and the
  /// rest unlock as the previous one is completed.
  bool isLevelUnlocked(String worldId, int level) =>
      level == 0 || starsForLevel(worldId, level - 1) > 0;

  // -------------------------------------------------------- animal puzzles
  static const String _puzzleStarsPrefix = 'puzzle_stars_';
  static const String _puzzleBonusKey = 'puzzle_bonus_stars';
  static const String _puzzleHintStreakKey = 'puzzle_hintless_streak';

  /// Best stars (0-3) earned on one animal puzzle.
  int puzzleStars(int puzzleIndex) =>
      _prefs.getInt('$_puzzleStarsPrefix$puzzleIndex') ?? 0;

  int get solvedPuzzleCount => _prefs
      .getKeys()
      .where((String key) => key.startsWith(_puzzleStarsPrefix))
      .where((String key) => (_prefs.getInt(key) ?? 0) > 0)
      .length;

  /// Animals unlocked in the "My Animals" collection.
  bool isAnimalUnlocked(int puzzleIndex) => puzzleStars(puzzleIndex) > 0;

  /// Puzzles unlock sequentially: the first is always open and each one opens
  /// the next once solved.
  bool isPuzzleUnlocked(int puzzleIndex) =>
      puzzleIndex == 0 || puzzleStars(puzzleIndex - 1) > 0;

  int get puzzleBonusStars => _prefs.getInt(_puzzleBonusKey) ?? 0;

  /// How many hint-free puzzles in a row the child has solved (resets to 0
  /// after the bonus fires or when a hint is used).
  int get hintlessPuzzleStreak => _prefs.getInt(_puzzleHintStreakKey) ?? 0;

  static const String _lastPuzzleIndexKey = 'last_played_puzzle_index';

  /// Index of the puzzle the child last played, or the next unlocked one.
  int get lastPlayedPuzzleIndex {
    final int? saved = _prefs.getInt(_lastPuzzleIndexKey);
    if (saved != null && saved >= 0 && saved < 100) {
      return saved;
    }
    return nextUnlockedPuzzleIndex;
  }

  /// Finds the first unsolved puzzle (0-99).
  int get nextUnlockedPuzzleIndex {
    for (int i = 0; i < 100; i++) {
      if (puzzleStars(i) == 0) return i;
    }
    return 0;
  }

  /// Saves the last visited or active puzzle.
  Future<void> recordLastPlayedPuzzle(int index) async {
    await _prefs.setInt(_lastPuzzleIndexKey, index.clamp(0, 99));
  }

  /// Records a solved puzzle and returns true when the hint-free bonus star
  /// fired (three in a row without a hint).
  Future<bool> recordPuzzleSolved(
    int puzzleIndex,
    int stars, {
    required bool usedHint,
  }) async {
    if (stars > puzzleStars(puzzleIndex)) {
      await _prefs.setInt('$_puzzleStarsPrefix$puzzleIndex', stars);
    }
    if (puzzleIndex < 99) {
      await recordLastPlayedPuzzle(puzzleIndex + 1);
    }
    // Solving a puzzle always counts as today's play.
    await recordDailyActivity();

    if (usedHint) {
      await _prefs.setInt(_puzzleHintStreakKey, 0);
      return false;
    }

    final int streak = hintlessPuzzleStreak + 1;
    if (streak >= 3) {
      await _prefs.setInt(_puzzleHintStreakKey, 0);
      await _prefs.setInt(_puzzleBonusKey, puzzleBonusStars + 1);
      return true;
    }
    await _prefs.setInt(_puzzleHintStreakKey, streak);
    return false;
  }

  /// Total stars across every world, quiz and puzzle (drives the counter).
  int get totalStars {
    int total = puzzleBonusStars;
    for (final String key in _prefs.getKeys()) {
      if (key.startsWith(_levelStarsPrefix) || key.startsWith(_puzzleStarsPrefix)) {
        total += _prefs.getInt(key) ?? 0;
      }
    }
    return total;
  }

  // ---------------------------------------------------------------- streak
  static const String _streakCountKey = 'streak_count';
  static const String _streakDayKey = 'streak_last_day';
  static const String _streakBestKey = 'streak_best';
  static const String _streakMilestonesKey = 'streak_milestones_claimed';

  /// Milestone days that award a chest of confetti, a sticker and an outfit.
  static const List<int> streakMilestones = <int>[3, 7, 14, 30];

  bool _welcomeBackPending = false;

  /// True exactly once after a missed day: the caller shows the friendly
  /// "Welcome back!" note and the flag clears.
  bool consumeWelcomeBack() {
    if (!_welcomeBackPending) return false;
    _welcomeBackPending = false;
    return true;
  }

  /// Consecutive days the child has played (0 for a brand new install).
  int get streakDays => _prefs.getInt(_streakCountKey) ?? 0;

  /// Best streak ever reached (shown in the parent dashboard).
  int get bestStreak => _prefs.getInt(_streakBestKey) ?? 0;

  /// The last calendar day that counted as played.
  String? get lastPlayedDay => _prefs.getString(_streakDayKey);

  /// Milestones already celebrated.
  Set<int> get claimedStreakMilestones =>
      (_prefs.getStringList(_streakMilestonesKey) ?? const <String>[])
          .map(int.tryParse)
          .whereType<int>()
          .toSet();

  /// The reward for a streak milestone, if it has been reached but not claimed.
  int? get pendingStreakMilestone {
    final Set<int> claimed = claimedStreakMilestones;
    for (final int milestone in streakMilestones) {
      if (streakDays >= milestone && !claimed.contains(milestone)) {
        return milestone;
      }
    }
    return null;
  }

  Future<void> claimStreakMilestone(int days) async {
    final Set<int> claimed = claimedStreakMilestones..add(days);
    await _prefs.setStringList(
      _streakMilestonesKey,
      claimed.map((int value) => '$value').toList()..sort(),
    );
  }

  /// Registers that the child finished at least one lesson, quiz or puzzle
  /// today, keeping the flame alive.
  Future<DailyActivity> recordDailyActivity() async {
    final DateTime today = _now();
    final String todayKey = dayKey(today);
    final String? lastKey = _prefs.getString(_streakDayKey);

    if (lastKey == null) {
      await _saveStreak(1, todayKey);
      return DailyActivity.firstEver;
    }
    if (lastKey == todayKey) return DailyActivity.sameDay;

    final DateTime? last = parseDayKey(lastKey);
    final int daysSinceLast = last == null
        ? -1
        : _dateOnly(today).difference(_dateOnly(last)).inDays;

    if (daysSinceLast == 1) {
      final int next = streakDays + 1;
      await _saveStreak(next, todayKey);
      return DailyActivity.continued;
    }

    // A missed day (or a clock that jumped): start a fresh, cheerful streak.
    _welcomeBackPending = streakDays > 0 || daysSinceLast > 1;
    await _saveStreak(1, todayKey);
    return DailyActivity.restarted;
  }

  /// API kept for older call sites: the map opening used to count as a day.
  /// Now a day only counts on real lesson/quiz/puzzle completion, so this is
  /// a no-op read used nowhere in the app.
  @Deprecated('A day counts on completion: use recordDailyActivity().')
  Future<void> touchStreak() => recordDailyActivity();

  Future<void> _saveStreak(int count, String dayKey) async {
    await _prefs.setString(_streakDayKey, dayKey);
    await _prefs.setInt(_streakCountKey, count);
    if (count > bestStreak) {
      await _prefs.setInt(_streakBestKey, count);
    }
  }

  /// `yyyy-MM-dd` in local time.
  String dayKey(DateTime day) {
    final DateTime local = day.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  DateTime? parseDayKey(String key) {
    final List<String> parts = key.split('-');
    if (parts.length != 3) return null;
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  DateTime _dateOnly(DateTime day) {
    final DateTime local = day.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  // ----------------------------------------------------- owlie customization
  static const String _owlieHatKey = 'owlie_selected_hat';
  static const String _owlieRoomKey = 'owlie_selected_room';
  static const String _owlieFestivalKey = 'owlie_selected_festival';
  static const String _owlieChildNameKey = 'owlie_child_name';

  int get selectedHat => _prefs.getInt(_owlieHatKey) ?? 0;
  Future<void> setSelectedHat(int index) => _prefs.setInt(_owlieHatKey, index);

  int get selectedRoom => _prefs.getInt(_owlieRoomKey) ?? 0;
  Future<void> setSelectedRoom(int index) => _prefs.setInt(_owlieRoomKey, index);

  String get selectedFestival => _prefs.getString(_owlieFestivalKey) ?? 'Eid';
  Future<void> setSelectedFestival(String name) =>
      _prefs.setString(_owlieFestivalKey, name);

  String get childName => _prefs.getString(_owlieChildNameKey) ?? 'Little Champion';
  Future<void> setChildName(String name) =>
      _prefs.setString(_owlieChildNameKey, name);

  // Bonus star awards (used by daily mission, challenges, etc.)
  Future<void> awardBonusStars(int count) async {
    final int current = puzzleBonusStars;
    await _prefs.setInt(_puzzleBonusKey, current + count);
    await recordDailyActivity();
  }

  // Daily mission claim tracker
  String get _dailyMissionClaimKey => 'daily_mission_claimed_${dayKey(_now())}';
  bool get isDailyMissionClaimed => _prefs.getBool(_dailyMissionClaimKey) ?? false;
  Future<void> markDailyMissionClaimed() =>
      _prefs.setBool(_dailyMissionClaimKey, true);

  // Weekly challenge claim tracker
  String get _weeklyChallengeClaimKey {
    final DateTime now = _now();
    final int weekNumber =
        (now.difference(DateTime(now.year, 1, 1)).inDays / 7).floor();
    return 'weekly_challenge_claimed_${now.year}_$weekNumber';
  }

  bool get isWeeklyChallengeClaimed =>
      _prefs.getBool(_weeklyChallengeClaimKey) ?? false;
  Future<void> markWeeklyChallengeClaimed() =>
      _prefs.setBool(_weeklyChallengeClaimKey, true);
}