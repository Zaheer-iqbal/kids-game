import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kids/core/services/audio_service.dart';

/// Stands in for the platform TTS engine and records the exact call order, so
/// the tests can prove the app never says a word twice and always interrupts
/// the previous utterance.
class _FakeTts extends FlutterTts {
  final List<String> calls = <String>[];
  final List<String> spoken = <String>[];
  int stopCount = 0;

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async =>
      _log('await');

  @override
  Future<dynamic> setLanguage(String language) async => _log('lang:$language');

  @override
  Future<dynamic> setSpeechRate(double rate) async => _log('rate:$rate');

  @override
  Future<dynamic> setPitch(double pitch) async => _log('pitch:$pitch');

  @override
  Future<dynamic> setVolume(double volume) async => _log('volume:$volume');

  @override
  Future<dynamic> stop() async {
    stopCount++;
    calls.add('stop');
    return null;
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spoken.add(text);
    calls.add('speak:$text');
    return 1;
  }

  dynamic _log(String call) {
    calls.add(call);
    return null;
  }

  /// The index of the `speak` call for [text].
  int indexOfSpeak(String text) => calls.indexOf('speak:$text');
}

void main() {
  // AudioService builds an AudioPlayer for its chimes, which needs the binary
  // messenger even though these tests never play one.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioService narration', () {
    late _FakeTts tts;
    late AudioService audio;

    setUp(() {
      tts = _FakeTts();
      audio = AudioService(tts: tts);
    });

    test('a number is spoken as its word, once', () async {
      await audio.speakNumber('One');

      expect(tts.spoken, <String>['One.']);
      // The digit must never be read out as well.
      expect(tts.spoken.single, isNot(contains('1')));
    });

    test('a two word number is still only said once', () async {
      await audio.speakNumber('Forty Two');

      expect(tts.spoken, <String>['Forty Two.']);
      expect(tts.spoken.single, isNot(contains('42')));
    });

    test('a letter is the letter, a pause, then the word', () async {
      await audio.speakPhonics('A', 'Apple');

      expect(tts.spoken, <String>['A. Apple.']);
    });

    test('the letter is not repeated inside the phrase', () async {
      await audio.speakPhonics('B', 'Ball');

      final String phrase = tts.spoken.single;
      expect(phrase, 'B. Ball.');
      // "B." must appear once: the old wording said "B. B for Ball.".
      expect('B.'.allMatches(phrase).length, 1);
    });

    test('every phrase is stopped before it is spoken', () async {
      await audio.speakPhonics('C', 'Cat');
      await audio.speakNumber('Ten');
      await audio.speakText('Great job!');

      expect(tts.stopCount, greaterThanOrEqualTo(3));
      for (final int index in <int>[
        tts.indexOfSpeak('C. Cat.'),
        tts.indexOfSpeak('Ten.'),
        tts.indexOfSpeak('Great job!'),
      ]) {
        expect(index, greaterThan(0));
        expect(tts.calls[index - 1], 'stop', reason: 'stop must come first');
      }
    });

    test('rapid taps interrupt instead of queueing duplicates', () async {
      // Not awaited in between, exactly like two fast card taps.
      final Future<void> first = audio.speakNumber('One');
      final Future<void> second = audio.speakNumber('Two');
      final Future<void> third = audio.speakNumber('Three');
      await Future.wait(<Future<void>>[first, second, third]);

      // One utterance per tap, no repeats, and each one stopped the last.
      expect(tts.spoken, <String>['One.', 'Two.', 'Three.']);
      expect(tts.spoken.toSet().length, 3);
      expect(tts.stopCount, greaterThanOrEqualTo(3));
    });

    test('a fun fact keeps its friendly intro', () async {
      await audio.speakFunFact('A day has 24 hours.');

      expect(tts.spoken, <String>['Fun fact. A day has 24 hours.']);
    });

    test('the engine is configured before the first word is spoken', () async {
      await audio.speakText('Hi');

      final int index = tts.indexOfSpeak('Hi');
      expect(tts.calls.sublist(0, index), contains('lang:en-US'));
      expect(tts.calls.indexOf('lang:en-US'), lessThan(index));
    });

    test('text passed to TTS contains the word form exactly once', () async {
      await audio.speakNumber('One');
      expect(tts.spoken.last, 'One.');
      expect(RegExp(r'One').allMatches(tts.spoken.last).length, 1);

      await audio.speakNumber('Forty Two');
      expect(tts.spoken.last, 'Forty Two.');
      expect(RegExp(r'Forty Two').allMatches(tts.spoken.last).length, 1);

      await audio.speakPhonics('A', 'Apple');
      expect(tts.spoken.last, 'A. Apple.');
      expect(RegExp(r'Apple').allMatches(tts.spoken.last).length, 1);
    });
  });
}
