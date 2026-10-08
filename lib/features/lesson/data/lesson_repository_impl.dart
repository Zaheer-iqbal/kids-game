import '../../alphabet/domain/entities/letter_item.dart';
import '../../alphabet/domain/repositories/alphabet_repository.dart';
import '../../home/domain/adventure_world.dart';
import '../../numbers/domain/entities/number_entity.dart';
import '../../numbers/domain/repositories/number_repository.dart';
import '../domain/lesson.dart';
import '../domain/lesson_repository.dart';

/// Turns repository data into a fixed, friendly four-step lesson:
/// meet the glyphs -> trace one -> hear and pick -> final challenge
/// (picture match for letters, counting for numbers).
class LessonRepositoryImpl implements LessonRepository {
  LessonRepositoryImpl({
    required AlphabetRepository alphabetRepository,
    required NumberRepository numberRepository,
  })  : _alphabet = alphabetRepository,
        _numbers = numberRepository;

  final AlphabetRepository _alphabet;
  final NumberRepository _numbers;

  @override
  Future<Lesson> buildLesson(String worldId, int level) async {
    if (worldId == WorldId.alphabet.storageKey) {
      return _buildAlphabet(level);
    }
    if (worldId == WorldId.numbers.storageKey) {
      return _buildNumbers(level);
    }
    throw StateError('Unknown lesson world: $worldId');
  }

  Future<Lesson> _buildAlphabet(int level) async {
    final AdventureWorld world = AdventureWorld.byId(WorldId.alphabet);
    _validateLevel(world, level, 'alphabet');

    final List<LetterItem> letters = await _alphabet.getLetters();
    final ({String from, String to}) range = world.lettersForLevel(level);
    final int first = range.from.codeUnitAt(0) - 65;
    final int last = range.to.codeUnitAt(0) - 65;

    final List<LessonGlyph> glyphs = <LessonGlyph>[
      for (int i = first; i <= last; i++)
        LessonGlyph(
          key: letters[i].letter,
          word: letters[i].word,
          emoji: letters[i].emoji,
          colorValue: letters[i].colorValue,
        ),
    ];

    final LessonGlyph traceTarget = glyphs[glyphs.length ~/ 2];
    final LessonGlyph pickTarget = glyphs.first;
    final LessonGlyph matchTarget = glyphs.last;

    return Lesson(
      worldId: world.id.storageKey,
      level: level,
      title: '${world.title} - Level ${level + 1}',
      glyphs: glyphs,
      steps: <LessonStep>[
        MeetStep(glyphs: glyphs),
        TraceStep(glyph: traceTarget),
        PickStep(
          target: pickTarget,
          options: _optionsFor(letters, first, level, _letterGlyph),
          prompt: 'Tap the letter you hear!',
        ),
        MatchStep(
          target: matchTarget,
          options: _optionsFor(letters, last, level + 1, _letterGlyph),
        ),
      ],
    );
  }

  Future<Lesson> _buildNumbers(int level) async {
    final AdventureWorld world = AdventureWorld.byId(WorldId.numbers);
    _validateLevel(world, level, 'numbers');

    final List<NumberEntity> numbers = await _numbers.getNumbers();
    final ({int from, int to}) range = world.numbersForLevel(level);
    final int first = range.from - 1;
    final int last = range.to - 1;

    final List<LessonGlyph> glyphs = <LessonGlyph>[
      for (int i = first; i <= last; i++)
        LessonGlyph(
          key: '${numbers[i].number}',
          word: numbers[i].word,
          emoji: numbers[i].emoji,
          colorValue: numbers[i].colorValue,
        ),
    ];

    final LessonGlyph traceTarget = glyphs[glyphs.length ~/ 2];
    final LessonGlyph pickTarget = glyphs.first;
    final LessonGlyph countTarget = glyphs.last;

    return Lesson(
      worldId: world.id.storageKey,
      level: level,
      title: '${world.title} - Level ${level + 1}',
      glyphs: glyphs,
      steps: <LessonStep>[
        MeetStep(glyphs: glyphs),
        TraceStep(glyph: traceTarget),
        PickStep(
          target: pickTarget,
          options: _optionsFor(numbers, first, level, _numberGlyph),
          prompt: 'Tap the number you hear!',
        ),
        CountStep(
          target: countTarget,
          options: _optionsFor(numbers, last, level + 1, _numberGlyph),
        ),
      ],
    );
  }

  void _validateLevel(AdventureWorld world, int level, String worldId) {
    if (level < 0 || level >= world.levelCount) {
      throw StateError('Level $level out of range for $worldId');
    }
  }

  /// Four options including the target, always in a deterministic order so
  /// lessons (and the tests that play them) are repeatable.
  List<LessonGlyph> _optionsFor<T>(
    List<T> items,
    int targetIndex,
    int rotation,
    LessonGlyph Function(T item) toGlyph,
  ) {
    final int n = items.length;
    final List<int> indices = <int>[];
    for (int k = 1; indices.length < 3 && k < n; k++) {
      final int i = (targetIndex + k) % n;
      if (i != targetIndex && !indices.contains(i)) {
        indices.add(i);
      }
    }
    // Keep the target, placed by a level-dependent rotation so the answer is
    // not always in the same spot.
    final int insertAt = rotation % (indices.length + 1);
    indices.insert(insertAt, targetIndex);
    return indices.map((int i) => toGlyph(items[i])).toList();
  }

  LessonGlyph _letterGlyph(LetterItem letter) => LessonGlyph(
        key: letter.letter,
        word: letter.word,
        emoji: letter.emoji,
        colorValue: letter.colorValue,
      );

  LessonGlyph _numberGlyph(NumberEntity number) => LessonGlyph(
        key: '${number.number}',
        word: number.word,
        emoji: number.emoji,
        colorValue: number.colorValue,
      );
}
