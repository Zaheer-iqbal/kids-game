import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/audio_service.dart';
import '../../../../core/services/fun_facts.dart';
import '../../../../core/services/progress_service.dart';
import '../../../alphabet/domain/entities/letter_item.dart';
import '../../../numbers/domain/entities/number_entity.dart';
import '../../domain/entities/quiz_option.dart';
import '../../domain/entities/quiz_question.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/entities/quiz_type.dart';
import '../../domain/repositories/quiz_repository.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  QuizBloc({
    required QuizRepository repository,
    required AudioService audioService,
    required ProgressService progressService,
  })  : _repository = repository,
        _audioService = audioService,
        _progressService = progressService,
        super(const QuizState()) {
    on<QuizStarted>(_onStarted);
    on<OptionSelected>(_onOptionSelected);
    on<NextQuestion>(_onNextQuestion);
    on<ReplaySound>(_onReplaySound);
  }

  final QuizRepository _repository;
  final AudioService _audioService;
  final ProgressService _progressService;
  final Random _random = Random();

  List<LetterItem>? _letters;
  List<NumberEntity>? _numbers;
  QuizType _type = QuizType.letterSounds;
  int _bestAtStart = 0;

  /// Targets of the current round so "replay sound" can re-speak correctly.
  LetterItem? _lastLetter;
  NumberEntity? _lastNumber;

  /// Category per letter for the Odd One Out game, so a round can offer three
  /// animals and one odd non-animal, for example.
  static const Map<String, String> _letterCategory = <String, String>{
    'A': 'food', 'I': 'food', 'J': 'food', 'M': 'food', 'O': 'food', 'W': 'food',
    'B': 'toys', 'K': 'toys', 'X': 'toys', 'Y': 'toys',
    'C': 'animals', 'D': 'animals', 'E': 'animals', 'F': 'animals',
    'G': 'animals', 'L': 'animals', 'P': 'animals', 'R': 'animals',
    'T': 'animals', 'Z': 'animals',
    'H': 'things', 'N': 'things', 'Q': 'things', 'S': 'things',
    'U': 'things', 'V': 'things',
  };

  Future<void> _onStarted(QuizStarted event, Emitter<QuizState> emit) async {
    emit(const QuizState(status: QuizStatus.loading));
    try {
      final List<LetterItem> letters = await _repository.getLetters()
        ..sort((a, b) => a.letter.compareTo(b.letter));
      final List<NumberEntity> numbers = await _repository.getNumbers()
        ..sort((a, b) => a.number.compareTo(b.number));
      if (letters.length < 4 || numbers.length < 4) {
        throw StateError('Not enough items available for a quiz.');
      }
      _letters = letters;
      _numbers = numbers;
      _type = event.type;
      _bestAtStart = _progressService.bestScoreFor(_type.name);
      emit(QuizState(
        status: QuizStatus.ready,
        quizType: _type,
        highScore: _bestAtStart,
        questionNumber: 1,
      ));
      await _askNextQuestion(emit);
    } catch (_) {
      emit(const QuizState(
        status: QuizStatus.error,
        error: 'Could not start the quiz.',
      ));
    }
  }

  Future<void> _onOptionSelected(
    OptionSelected event,
    Emitter<QuizState> emit,
  ) async {
    final QuizState current = state;
    if (current.status != QuizStatus.ready ||
        current.revealCorrect ||
        current.targetKey == null) {
      return;
    }

    if (event.option.key == current.targetKey) {
      final int newScore = current.score + 1;
      final bool beatBest = newScore > _bestAtStart;
      await _progressService.updateQuizHighScore(newScore);
      await _progressService.updateBestScore(_type.name, newScore);
      unawaited(_audioService.playSuccessChime());
      emit(current.copyWith(
        score: newScore,
        highScore: _progressService.bestScoreFor(_type.name),
        revealCorrect: true,
        wrongOption: null,
        newHighScore: beatBest,
      ));
    } else {
      unawaited(_audioService.playWrongChime());
      emit(current.copyWith(
        wrongOption: event.option.key,
        wrongToken: current.wrongToken + 1,
      ));
    }
  }

  Future<void> _onNextQuestion(
    NextQuestion event,
    Emitter<QuizState> emit,
  ) async {
    final QuizState current = state;
    if (current.status != QuizStatus.ready) return;

    if (current.questionNumber >= current.totalQuestions) {
      final QuizResult result = QuizResult(
        type: _type,
        score: current.score,
        totalQuestions: current.totalQuestions,
        newHighScore: current.score > _bestAtStart && current.score > 0,
        bestScore: _progressService.bestScoreFor(_type.name),
      );
      emit(current.copyWith(
        status: QuizStatus.finished,
        revealCorrect: false,
        result: result,
      ));
      unawaited(_audioService.playSuccessChime());
      return;
    }
    emit(current.copyWith(questionNumber: current.questionNumber + 1));
    await _askNextQuestion(emit);
  }

  Future<void> _onReplaySound(ReplaySound event, Emitter<QuizState> emit) async {
    switch (_type) {
      case QuizType.letterSounds:
        final LetterItem? target = _lastLetter;
        if (target != null) {
          unawaited(_audioService.speakPhonics(target.letter, target.word));
        }
      case QuizType.numberMatch:
        final NumberEntity? target = _lastNumber;
        if (target != null) {
          unawaited(_audioService.speakNumber(target.word));
        }
      case QuizType.funFacts:
      case QuizType.oddOneOut:
        final String? prompt = state.spokenPrompt;
        if (prompt != null && prompt.isNotEmpty) {
          unawaited(_audioService.speakText(prompt));
        }
    }
  }

  Future<void> _askNextQuestion(Emitter<QuizState> emit) async {
    final _Round round = _buildRound();
    _lastLetter = round.letterTarget;
    _lastNumber = round.numberTarget;

    emit(state.copyWith(
      promptTitle: round.question.promptTitle,
      spokenPrompt: round.question.spokenPrompt,
      options: round.question.options,
      targetKey: round.question.targetKey,
      revealCorrect: false,
      wrongOption: null,
    ));

    switch (_type) {
      case QuizType.letterSounds:
        final LetterItem? target = round.letterTarget;
        if (target != null) {
          unawaited(_audioService.speakPhonics(target.letter, target.word));
        }
      case QuizType.numberMatch:
        final NumberEntity? target = round.numberTarget;
        if (target != null) {
          unawaited(_audioService.speakNumber(target.word));
        }
      case QuizType.funFacts:
        final String? fact = round.question.spokenPrompt;
        if (fact != null) {
          unawaited(_audioService.speakFunFact(fact));
        }
      case QuizType.oddOneOut:
        unawaited(_audioService.speakText("Which one doesn't belong?"));
    }
  }

  _Round _buildRound() {
    switch (_type) {
      case QuizType.letterSounds:
        return _buildLetterSoundsRound();
      case QuizType.numberMatch:
        return _buildNumberMatchRound();
      case QuizType.funFacts:
        final bool useLetters = _random.nextBool();
        return useLetters
            ? _buildFunFactLetterRound()
            : _buildFunFactNumberRound();
      case QuizType.oddOneOut:
        final bool useLetters = _random.nextBool();
        return useLetters
            ? _buildOddOneOutLetterRound()
            : _buildOddOneOutNumberRound();
    }
  }

  _Round _buildLetterSoundsRound() {
    final List<LetterItem> letters = _letters!;
    final LetterItem target = letters[_random.nextInt(letters.length)];
    final List<QuizOption> options = _letterOptions(
      excludeKey: target.letter,
      count: 3,
    ).map(QuizOption.fromLetter).toList()
      ..add(QuizOption.fromLetter(target))
      ..shuffle(_random);
    return _Round(
      question: QuizQuestion(
        promptTitle: 'Tap the picture this sound says!',
        spokenPrompt: null,
        options: options,
        targetKey: target.letter,
      ),
      letterTarget: target,
    );
  }

  _Round _buildNumberMatchRound() {
    final List<NumberEntity> numbers = _numbers!;
    final NumberEntity target = numbers[_random.nextInt(numbers.length)];
    final List<QuizOption> options = _numberOptions(count: 3)
      ..add(QuizOption.fromNumber(target))
      ..shuffle(_random);
    return _Round(
      question: QuizQuestion(
        promptTitle: 'Tap the number you hear!',
        spokenPrompt: null,
        options: options,
        targetKey: '${target.number}',
      ),
      numberTarget: target,
    );
  }

  _Round _buildFunFactLetterRound() {
    final List<LetterItem> letters = _letters!;
    final LetterItem target = letters[_random.nextInt(letters.length)];
    final List<QuizOption> options = _letterOptions(
      excludeKey: target.letter,
      count: 3,
    ).map(QuizOption.fromLetter).toList()
      ..add(QuizOption.fromLetter(target))
      ..shuffle(_random);
    return _Round(
      question: QuizQuestion(
        promptTitle: 'Who am I? Listen to my fun fact!',
        spokenPrompt: FunFacts.forLetter(target.letter),
        options: options,
        targetKey: target.letter,
      ),
      letterTarget: target,
    );
  }

  _Round _buildFunFactNumberRound() {
    final List<NumberEntity> candidates = _numbers!
        .where(
          (NumberEntity n) => FunFacts.forNumber(n.number) != null,
        )
        .toList();
    final NumberEntity target =
        candidates[_random.nextInt(candidates.length)];
    final List<QuizOption> options = _numberOptions(count: 3)
      ..add(QuizOption.fromNumber(target))
      ..shuffle(_random);
    return _Round(
      question: QuizQuestion(
        promptTitle: 'Who am I? Listen to my fun fact!',
        spokenPrompt: FunFacts.forNumber(target.number),
        options: options,
        targetKey: '${target.number}',
      ),
      numberTarget: target,
    );
  }

  _Round _buildOddOneOutLetterRound() {
    final List<LetterItem> letters = _letters!;

    // Categories with at least four members can supply the three "same" cards.
    final List<String> richCategories = _letterCategory.values.toSet().where(
          (String category) =>
              _letterCategory.entries
                  .where((MapEntry<String, String> e) => e.value == category)
                  .length >=
              4,
        ).toList();
    final String category =
        richCategories[_random.nextInt(richCategories.length)];
    final List<LetterItem> inCategory = letters
        .where((LetterItem l) => _letterCategory[l.letter] == category)
        .toList();
    final List<LetterItem> outsiders = letters
        .where((LetterItem l) => _letterCategory[l.letter] != category)
        .toList();

    final List<LetterItem> same = _distinctIconLetters(inCategory, 3);
    final List<LetterItem> usedIcons = same;
    final LetterItem odd = _firstDistinctFrom(outsiders, usedIcons);

    final List<QuizOption> options =
        same.map(QuizOption.fromLetter).toList()
          ..add(QuizOption.fromLetter(odd))
          ..shuffle(_random);

    return _Round(
      question: QuizQuestion(
        promptTitle: "Which one doesn't belong?",
        spokenPrompt: "Which one doesn't belong?",
        options: options,
        targetKey: odd.letter,
      ),
      letterTarget: odd,
      numberTarget: null,
    );
  }

  _Round _buildOddOneOutNumberRound() {
    final List<NumberEntity> numbers = _numbers!;
    final List<NumberEntity> evens =
        numbers.where((NumberEntity n) => n.number.isEven).toList();
    final List<NumberEntity> odds =
        numbers.where((NumberEntity n) => n.number.isOdd).toList();

    final bool oddIsOddOneOut = _random.nextBool();
    final List<NumberEntity> majority =
        (oddIsOddOneOut ? evens : odds)..shuffle(_random);
    final List<NumberEntity> minorityPool =
        (oddIsOddOneOut ? odds : evens)..shuffle(_random);

    final List<NumberEntity> same = majority.take(3).toList();
    final NumberEntity odd = minorityPool.first;

    final List<QuizOption> options =
        same.map(QuizOption.fromNumber).toList()
          ..add(QuizOption.fromNumber(odd))
          ..shuffle(_random);

    return _Round(
      question: QuizQuestion(
        promptTitle: "Which one doesn't belong?",
        spokenPrompt: "Which one doesn't belong?",
        options: options,
        targetKey: '${odd.number}',
      ),
      numberTarget: odd,
      letterTarget: null,
    );
  }

  /// Three distractor letters whose pictures are all distinct from each other
  /// (used by modes where four distinct pictures matter).
  List<LetterItem> _letterOptions({
    required String excludeKey,
    required int count,
  }) {
    return _distinctIconLetters(
      _letters!.where((LetterItem l) => l.letter != excludeKey).toList(),
      count,
    );
  }

  /// Shuffles [pool] and takes [count] distinct letters that also have four
  /// different pictures among themselves so no two cards look the same.
  List<LetterItem> _distinctIconLetters(List<LetterItem> pool, int count) {
    final List<LetterItem> result = <LetterItem>[];
    final Set<String> usedEmoji = <String>{};
    final List<LetterItem> working = List<LetterItem>.of(pool)..shuffle(_random);
    for (final LetterItem letter in working) {
      if (usedEmoji.contains(letter.emoji)) continue;
      result.add(letter);
      usedEmoji.add(letter.emoji);
      if (result.length >= count) break;
    }
    if (result.length < count) {
      result.addAll(
        pool.where(
          (LetterItem l) => !usedEmoji.contains(l.emoji) && !result.contains(l),
        ).take(count - result.length),
      );
    }
    return result;
  }

  LetterItem _firstDistinctFrom(List<LetterItem> pool, List<LetterItem> used) {
    final Set<String> usedEmoji = used.map((LetterItem l) => l.emoji).toSet();
    final List<LetterItem> working = List<LetterItem>.of(pool)..shuffle(_random);
    return working.firstWhere(
      (LetterItem l) => !usedEmoji.contains(l.emoji),
      orElse: () => working.first,
    );
  }

  /// Three distractor numbers.
  List<QuizOption> _numberOptions({required int count}) {
    final List<NumberEntity> working =
        List<NumberEntity>.of(_numbers!)..shuffle(_random);
    return working.take(count).map(QuizOption.fromNumber).toList();
  }
}

class _Round {
  const _Round({
    required this.question,
    this.letterTarget,
    this.numberTarget,
  });

  final QuizQuestion question;
  final LetterItem? letterTarget;
  final NumberEntity? numberTarget;
}