import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';

import 'test_environment_stub.dart' if (dart.library.io) 'test_environment_io.dart';
import 'tone_generator.dart';

/// Names the pre-recorded voice clips that may live in `assets/audio/voice/`.
///
/// The folder is optional: when a clip is missing the service simply falls back
/// to the on-device voice, so the app narrates everything even with no files.
/// Clip names are derived from what they say — `letter_a.mp3` for the letter
/// "A", `number_27.mp3` for the number 27 and `animal_lion.mp3` for a lion.
class VoiceClips {
  const VoiceClips._();

  /// Path inside `assets/` where recorded clips are looked up.
  static const String basePath = 'audio/voice';

  static String letter(String letter) => 'letter_${letter.toLowerCase()}';

  static String number(int value) => 'number_$value';

  static String animal(String name) => 'animal_${_slug(name)}';

  static String _slug(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

/// The single place the app makes a sound.
///
/// Voice narration prefers a recorded clip in `assets/audio/voice/` and falls
/// back to the platform text-to-speech engine; short feedback chimes are
/// synthesized into WAV bytes in memory and played through [AudioPlayer] with a
/// [BytesSource]. Every voice call also goes through here so "one utterance per
/// tap" and the parent's sound/voice switches hold everywhere.
class AudioService {
  AudioService({FlutterTts? tts, AudioPlayer? clipPlayer})
      : _tts = tts ?? FlutterTts(),
        _clipPlayer = clipPlayer;

  final FlutterTts _tts;
  AudioPlayer? _clipPlayer;
  AudioPlayer? _player;

  // Parent switches (kept here so every play/speak call is one gate away).
  bool _soundEnabled = true;
  bool _voiceEnabled = true;

  /// Speaking speed used by the device voice. Slower than the platform default
  /// so young listeners can follow every sound.
  double _speechRate = 0.45;

  /// The voice the parent picked, or `null` to let the engine auto-select the
  /// best English voice at startup.
  String? _voiceName;

  /// Every voice the engine reported, as a stable list for the settings screen.
  List<String> _voices = const <String>[];

  /// Called once at startup and again whenever the parent changes a setting.
  void configure({
    required bool soundEnabled,
    required bool voiceEnabled,
    double? speechRate,
    String? voiceName,
  }) {
    final bool voiceJustTurnedOn = !_voiceEnabled && voiceEnabled;
    _soundEnabled = soundEnabled;
    _voiceEnabled = voiceEnabled;
    if (speechRate != null && speechRate != _speechRate) {
      _speechRate = speechRate;
      unawaited(_applySpeechRate());
    }
    if (voiceName != _voiceName) {
      _voiceName = voiceName;
      unawaited(_applyVoice());
    }
    if (!voiceEnabled) {
      unawaited(stopSpeaking());
    } else if (voiceJustTurnedOn) {
      // Warm the engine so the first narration is instant.
      unawaited(_ensureTtsReady());
    }
  }

  bool get soundEnabled => _soundEnabled;
  bool get voiceEnabled => _voiceEnabled;

  /// The voices the engine offers, once they have been read. Empty until the
  /// first narration or a call to [listVoices].
  List<String> get availableVoices =>
      List<String>.unmodifiable(_voices);

  /// The voice in use right now, or `null` while the engine auto-selects.
  String? get selectedVoice => _voiceName;

  /// Reads the available voices (also warming the engine if needed) so the
  /// settings screen can let a parent pick one.
  Future<List<String>> listVoices() async {
    await _ensureTtsReady();
    return availableVoices;
  }

  /// Speaks a short sample so a parent can hear the current voice and speed.
  Future<void> testVoice() =>
      _speak('Hi! This is how I will read to you.');

  /// Completed once the TTS engine is configured. Speaking first awaits this
  /// so a rapid tap can never start talking before `setLanguage` finished.
  Future<void>? _ttsReady;

  Future<void> _ensureTtsReady() => _ttsReady ??= _initTts();

  Future<void> _initTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(1.15);
      await _tts.setVolume(1.0);
      debugPrint('TTS ready');
    } catch (e) {
      debugPrint('TTS init failed: $e');
    }
    // Voice discovery is best effort and kept out of the block above so an
    // engine that cannot list voices still gets configured and can speak.
    await _loadVoices();
  }

  Future<void> _loadVoices() async {
    try {
      final dynamic raw = await _tts.getVoices;
      if (raw is List) {
        _voices = raw
            .whereType<Map<dynamic, dynamic>>()
            .map((Map<dynamic, dynamic> voice) => voice['name']?.toString())
            .whereType<String>()
            .where((String name) => name.isNotEmpty)
            .toList(growable: false);
      }
    } catch (e) {
      debugPrint('Voice discovery failed: $e');
      return;
    }
    if (_voices.isEmpty) return;
    final String? preferred = _voiceName ?? _bestEnglishVoice();
    if (preferred != null) {
      _voiceName = preferred;
      // Set directly: `_applyVoice` awaits engine readiness, and we are still
      // inside that very future here, so awaiting it would deadlock.
      try {
        await _tts.setVoice(<String, String>{'name': preferred});
      } catch (e) {
        debugPrint('TTS voice failed: $e');
      }
    }
  }

  /// Picks a sensible English voice: a local en-US voice if there is one,
  /// otherwise any en-US, otherwise any English.
  String? _bestEnglishVoice() {
    String? enUs;
    String? english;
    String? localEnUs;
    for (final String name in _voices) {
      final String lower = name.toLowerCase();
      final bool isEnUs = lower.contains('en-us') || lower.contains('en_us');
      if (isEnUs) {
        enUs ??= name;
        if (lower.contains('local')) localEnUs ??= name;
      } else if ((lower.startsWith('en') ||
              lower.contains('en-gb') ||
              lower.contains('en_gb')) &&
          english == null) {
        english = name;
      }
    }
    return localEnUs ?? enUs ?? english;
  }

  Future<void> _applySpeechRate() async {
    await _ensureTtsReady();
    try {
      await _tts.setSpeechRate(_speechRate);
    } catch (e) {
      debugPrint('TTS rate failed: $e');
    }
  }

  Future<void> _applyVoice() async {
    await _ensureTtsReady();
    // A null selection means "automatic": fall back to the best English voice
    // so clearing a parent's pick really does change the voice.
    final String name = _voiceName ?? _bestEnglishVoice() ?? '';
    if (name.isEmpty) return;
    try {
      await _tts.setVoice(<String, String>{'name': name});
    } catch (e) {
      debugPrint('TTS voice failed: $e');
    }
  }

  /// Stops any ongoing narration and releases the TTS engine.
  Future<void> stopSpeaking() async {
    if (_ttsReady == null) return;
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('TTS stop failed: $e');
    }
  }

  /// Speaks a raw text phrase (a fallback if platform engines are flaky).
  ///
  /// Pass [clipKey] (see [VoiceClips]) to play a recorded clip when one exists.
  Future<void> speakText(String text, {String? clipKey}) =>
      _speak(text, clipKey: clipKey);

  /// Reads a letter the way a parent teaches it: the letter on its own, a
  /// short pause, then the word - "A. Apple."
  ///
  /// The word is never prefixed with the letter again ("A. A for Apple."), so
  /// nothing is said twice.
  Future<void> speakPhonics(String letter, String word) =>
      _speak('$letter. $word.', clipKey: VoiceClips.letter(letter));

  /// Speaks only the letter sound ("A."), used when the answer is a picture
  /// so the word itself is never given away.
  Future<void> speakLetterSound(String letter) =>
      _speak('$letter.', clipKey: VoiceClips.letter(letter));

  /// Reads a number as its word, once: "Forty Two."
  ///
  /// The digit is not spoken as well, which is what used to make the engine
  /// say "42. Forty Two." out as a doubled, mixed up phrase. Pass [value] so a
  /// matching recorded clip can be used when one exists.
  Future<void> speakNumber(String word, {int? value}) => _speak(
        '$word.',
        clipKey: value == null ? null : VoiceClips.number(value),
      );

  /// Reads a fun fact with a cheerful little intro.
  Future<void> speakFunFact(String fact) => _speak('Fun fact. $fact');

  Future<void> _speak(String text, {String? clipKey}) async {
    if (!_voiceEnabled) return;
    try {
      // Wait for engine init and interrupt any utterance still playing so
      // rapid consecutive taps each get their sound instead of queueing.
      await _ensureTtsReady();
      await _tts.stop();
      if (clipKey != null && await _playClip(clipKey)) {
        debugPrint('Voice clip: $clipKey');
        return;
      }
      debugPrint('TTS speak: $text');
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  /// Plays `assets/audio/voice/<key>.mp3` when it exists. Returns false when
  /// there is no clip (or nothing can be played) so the caller uses the voice.
  Future<bool> _playClip(String key) async {
    if (isFlutterTest) return false;
    final String assetPath = 'assets/${VoiceClips.basePath}/$key.mp3';
    Uint8List bytes;
    try {
      final ByteData data = await rootBundle.load(assetPath);
      bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on FlutterError {
      // No clip recorded for this key: quietly use the device voice.
      return false;
    }
    try {
      final AudioPlayer player =
          _clipPlayer ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await player.stop();
      await player.play(BytesSource(bytes));
      return true;
    } catch (e) {
      debugPrint('Voice clip "$key" failed, using TTS: $e');
      return false;
    }
  }

  /// A quick ascending arpeggio for a correct answer.
  Future<void> playSuccessChime() => _playWav(
        ToneGenerator.chimeWav(const <double>[
          523.25,
          659.25,
          783.99,
        ]),
      );

  /// A soft, low two-note fall for a wrong answer.
  Future<void> playWrongChime() => _playWav(
        ToneGenerator.chimeWav(const <double>[
          293.66,
          261.63,
        ]),
      );

  /// A gentle two-note sparkle when the tracing is completed.
  Future<void> playTraceChime() => _playWav(
        ToneGenerator.chimeWav(const <double>[
          659.25,
          880.0,
        ]),
      );

  /// Bright single ding - correct answer, star earned, badge unlocked.
  Future<void> playDing() => _playWav(ToneGenerator.dingWav());

  /// Short UI pop for taps, card presses and selections.
  Future<void> playPop() =>
      _playWav(ToneGenerator.popWav(durationMs: 95));

  /// Rounded boop for gentle nudges and "try again" moments.
  Future<void> playBoop() => _playWav(ToneGenerator.boopWav());

  /// Filtered-noise sweep for screen transitions.
  Future<void> playWhoosh() => _playWav(ToneGenerator.whooshWav());

  /// Four-note celebration for finishing a level.
  Future<void> playFanfare() => _playWav(ToneGenerator.fanfareWav());

  /// Rising blip when stars are awarded.
  Future<void> playLevelUp() => _playWav(ToneGenerator.levelUpWav());

  Future<void> _playWav(Uint8List wav) async {
    if (!_soundEnabled || isFlutterTest) {
      // The audioplayers platform channel does not exist under `flutter test`;
      // creating an AudioPlayer there leaks an unawaited MissingPluginException
      // that fails the test, so skip playback while still exercising the game
      // logic that triggers it.
      debugPrint('Chime skipped in test environment');
      return;
    }
    try {
      final AudioPlayer player =
          _player ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await player.stop();
      await player.play(BytesSource(wav));
    } catch (e) {
      debugPrint('Chime playback failed: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
      await _player?.dispose();
      await _clipPlayer?.dispose();
    } catch (_) {}
  }
}
