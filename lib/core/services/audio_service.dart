import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'test_environment_stub.dart' if (dart.library.io) 'test_environment_io.dart';
import 'tone_generator.dart';

/// Plays all audio through on-device systems only — no audio files required.
///
/// Voice narration uses the platform text-to-speech engine; short feedback
/// chimes are synthesized into WAV bytes in memory and played back through
/// [AudioPlayer] with a [BytesSource].
class AudioService {
  AudioService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  AudioPlayer? _player;

  // Parent switches (kept here so every play/speak call is one gate away).
  bool _soundEnabled = true;
  bool _voiceEnabled = true;

  /// Called once at startup and again whenever the parent flips a switch.
  void configure({required bool soundEnabled, required bool voiceEnabled}) {
    final bool voiceJustTurnedOn = !_voiceEnabled && voiceEnabled;
    _soundEnabled = soundEnabled;
    _voiceEnabled = voiceEnabled;
    if (!voiceEnabled) {
      unawaited(stopSpeaking());
    } else if (voiceJustTurnedOn) {
      // Warm the engine so the first narration is instant.
      unawaited(_ensureTtsReady());
    }
  }

  bool get soundEnabled => _soundEnabled;
  bool get voiceEnabled => _voiceEnabled;

  /// Completed once the TTS engine is configured. Speaking first awaits this
  /// so a rapid tap can never start talking before `setLanguage` finished.
  Future<void>? _ttsReady;

  Future<void> _ensureTtsReady() => _ttsReady ??= _initTts();

  Future<void> _initTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.15);
      await _tts.setVolume(1.0);
      debugPrint('TTS ready');
    } catch (e) {
      debugPrint('TTS init failed: $e');
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
  Future<void> speakText(String text) => _speak(text);

  /// Reads a letter the way a parent teaches it: the letter on its own, a
  /// short pause, then the word - "A. Apple."
  ///
  /// The word is never prefixed with the letter again ("A. A for Apple."), so
  /// nothing is said twice.
  Future<void> speakPhonics(String letter, String word) =>
      _speak('$letter. $word.');

  /// Speaks only the letter sound ("A."), used when the answer is a picture
  /// so the word itself is never given away.
  Future<void> speakLetterSound(String letter) => _speak('$letter.');

  /// Reads a number as its word, once: "Forty Two."
  ///
  /// The digit is not spoken as well, which is what used to make the engine
  /// say "42. Forty Two." out as a doubled, mixed up phrase.
  Future<void> speakNumber(String word) => _speak('$word.');

  /// Reads a fun fact with a cheerful little intro.
  Future<void> speakFunFact(String fact) => _speak('Fun fact. $fact');

  Future<void> _speak(String text) async {
    if (!_voiceEnabled) return;
    try {
      // Wait for engine init and interrupt any utterance still playing so
      // rapid consecutive taps each get their sound instead of queueing.
      await _ensureTtsReady();
      await _tts.stop();
      debugPrint('TTS speak: $text');
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
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
    } catch (_) {}
  }
}