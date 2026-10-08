import 'lesson.dart';

/// Builds the playable steps for one world level.
abstract interface class LessonRepository {
  /// Throws [StateError] for unknown worlds or out-of-range levels.
  Future<Lesson> buildLesson(String worldId, int level);
}
