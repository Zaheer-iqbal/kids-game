import 'package:flutter_test/flutter_test.dart';
import 'package:kids/core/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A mutable clock lets a test "wait" several days without any real time.
class _Clock {
  DateTime value = DateTime(2024, 3, 1, 9);

  DateTime call() => value;

  void setDay(int year, int month, int day) {
    value = DateTime(year, month, day, 9);
  }
}

Future<ProgressService> _progress(_Clock clock) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return ProgressService(prefs, now: clock.call);
}

void main() {
  group('Daily streak', () {
    test('the first play starts a one-day streak', () async {
      final _Clock clock = _Clock();
      final ProgressService progress = await _progress(clock);
      expect(await progress.recordDailyActivity(), DailyActivity.firstEver);
      expect(progress.streakDays, 1);
      expect(progress.bestStreak, 1);
      expect(progress.lastPlayedDay, '2024-03-01');
    });

    test('playing twice in a day keeps the streak the same', () async {
      final _Clock clock = _Clock();
      final ProgressService progress = await _progress(clock);
      await progress.recordDailyActivity();
      expect(await progress.recordDailyActivity(), DailyActivity.sameDay);
      expect(progress.streakDays, 1);
    });

    test('playing the next day continues the flame', () async {
      final _Clock clock = _Clock();
      final ProgressService progress = await _progress(clock);
      await progress.recordDailyActivity();
      clock.setDay(2024, 3, 2);
      expect(await progress.recordDailyActivity(), DailyActivity.continued);
      expect(progress.streakDays, 2);
      expect(progress.bestStreak, 2);
    });

    test('a missed day restarts kindly and flags a welcome back', () async {
      final _Clock clock = _Clock();
      final ProgressService progress = await _progress(clock);
      await progress.recordDailyActivity();
      clock.setDay(2024, 3, 5);
      expect(await progress.recordDailyActivity(), DailyActivity.restarted);
      expect(progress.streakDays, 1);
      expect(progress.bestStreak, 1);
      expect(progress.consumeWelcomeBack(), isTrue);
      expect(progress.consumeWelcomeBack(), isFalse);
    });
  });

  group('Streak milestones', () {
    test('a 3 day streak makes one chest claimable exactly once', () async {
      final _Clock clock = _Clock();
      final ProgressService progress = await _progress(clock);
      for (int day = 1; day <= 3; day++) {
        clock.setDay(2024, 3, day);
        await progress.recordDailyActivity();
      }
      expect(progress.streakDays, 3);
      expect(progress.pendingStreakMilestone, 3);
      expect(progress.claimedStreakMilestones, isEmpty);

      await progress.claimStreakMilestone(3);
      expect(progress.claimedStreakMilestones, contains(3));
      expect(progress.pendingStreakMilestone, isNull);
    });

    test('the next milestone appears after the previous is claimed', () async {
      final _Clock clock = _Clock();
      final ProgressService progress = await _progress(clock);
      for (int day = 1; day <= 7; day++) {
        clock.setDay(2024, 3, day);
        await progress.recordDailyActivity();
      }
      expect(progress.pendingStreakMilestone, 3);
      await progress.claimStreakMilestone(3);
      expect(progress.pendingStreakMilestone, 7);
    });
  });

  group('Completing work keeps the flame', () {
    test('a lesson, a quiz and a puzzle all count as today', () async {
      final _Clock clock = _Clock();
      final ProgressService progress = await _progress(clock);

      await progress.awardStars('alphabet', 0, 3);
      expect(progress.streakDays, 1);

      clock.setDay(2024, 3, 2);
      await progress.updateQuizHighScore(8);
      expect(progress.streakDays, 2);

      clock.setDay(2024, 3, 3);
      await progress.recordPuzzleSolved(0, 3, usedHint: false);
      expect(progress.streakDays, 3);
    });

    test('replaying a finished level still counts the day', () async {
      final _Clock clock = _Clock();
      final ProgressService progress = await _progress(clock);
      await progress.awardStars('alphabet', 0, 3);
      clock.setDay(2024, 3, 2);
      // A lower score must not lower the stored stars...
      await progress.awardStars('alphabet', 0, 1);
      expect(progress.starsForLevel('alphabet', 0), 3);
      // ...but still counts as played today.
      expect(progress.streakDays, 2);
    });
  });
}
