import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:kids/core/services/audio_service.dart';

/// Stands in for the platform TTS engine, including voice discovery, so the
/// tests can prove the service picks a sensible English voice, lets a parent
/// override it, and still says each line exactly once.
class _FakeTts extends FlutterTts {
  final List<String> calls = <String>[];
  final List<String> spoken = <String>[];

  List<Map<String, String>> voices = <Map<String, String>>[];
  String? selectedVoice;
  double? rate;

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async =>
      _log('await');

  @override
  Future<dynamic> setLanguage(String language) async => _log('lang:$language');

  @override
  Future<dynamic> setSpeechRate(double value) async {
    rate = value;
    return _log('rate:$value');
  }

  @override
  Future<dynamic> setPitch(double pitch) async => _log('pitch:$pitch');

  @override
  Future<dynamic> setVolume(double volume) async => _log('volume:$volume');

  @override
  Future<dynamic> get getVoices async => voices;

  @override
  Future<dynamic> setVoice(Map<String, String> voice) async {
    selectedVoice = voice['name'];
    return _log('voice:${voice['name']}');
  }

  @override
  Future<dynamic> stop() async => _log('stop');

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    spoken.add(text);
    return _log('speak:$text');
  }

  dynamic _log(String call) {
    calls.add(call);
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceClips naming', () {
    test('letters, numbers and animals map to their clip names', () {
      expect(VoiceClips.letter('A'), 'letter_a');
      expect(VoiceClips.number(27), 'number_27');
      expect(VoiceClips.animal('Lion'), 'animal_lion');
    });

    test('multi-word animal names become a single slug', () {
      expect(VoiceClips.animal('Guinea Pig'), 'animal_guinea_pig');
      expect(VoiceClips.animal('  Polar  Bear '), 'animal_polar_bear');
    });
  });

  group('AudioService voice selection', () {
    late _FakeTts tts;
    late AudioService audio;

    setUp(() {
      tts = _FakeTts();
      audio = AudioService(tts: tts);
    });

    test('auto-selects a local en-US voice on the first narration', () async {
      tts.voices = <Map<String, String>>[
        <String, String>{'name': 'en-GB-X'},
        <String, String>{'name': 'en-US-x-sfg-local'},
        <String, String>{'name': 'fr-FR'},
      ];

      await audio.speakText('Hello');

      expect(audio.selectedVoice, 'en-US-x-sfg-local');
      expect(tts.selectedVoice, 'en-US-x-sfg-local');
      expect(audio.availableVoices, hasLength(3));
    });

    test('a parent pick wins over the automatic choice', () async {
      tts.voices = <Map<String, String>>[
        <String, String>{'name': 'en-US-default'},
        <String, String>{'name': 'en-US-parent'},
      ];

      audio.configure(
        soundEnabled: true,
        voiceEnabled: true,
        voiceName: 'en-US-parent',
      );
      await audio.speakText('Hello');

      expect(audio.selectedVoice, 'en-US-parent');
      expect(tts.selectedVoice, 'en-US-parent');
    });

    test('the configured speaking speed reaches the engine', () async {
      audio.configure(
        soundEnabled: true,
        voiceEnabled: true,
        speechRate: 0.3,
      );

      await audio.speakText('Hello');

      expect(tts.rate, 0.3);
    });

    test('a missing recorded clip quietly falls back to the voice', () async {
      // There is no `assets/audio/voice/letter_a.mp3` in the test bundle, so
      // the service must still speak the line exactly once.
      await audio.speakLetterSound('A');

      expect(tts.spoken, <String>['A.']);
    });

    test('test voice speaks its sample exactly once', () async {
      await audio.testVoice();

      expect(tts.spoken, hasLength(1));
      expect(tts.spoken.single, contains('how I will read'));
    });

    test('voice narration still stops the previous line before speaking',
        () async {
      await audio.speakText('One');
      await audio.speakText('Two');

      final int second = tts.calls.indexOf('speak:Two');
      expect(second, greaterThan(0));
      expect(tts.calls[second - 1], 'stop');
    });
  });
}
