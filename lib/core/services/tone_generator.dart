/// Synthesizes playful, click-free WAV chimes in memory so the app never needs
/// to ship a single audio file.
///
/// Output is standard 44-byte header + 16-bit PCM mono data at 22050 Hz.
library;

import 'dart:math';
import 'dart:typed_data';

class ToneGenerator {
  ToneGenerator._();

  static const int sampleRate = 22050;

  /// Renders one chime built from [frequencies] (Hz).
  ///
  /// Each note rings for ~130 ms with a small gap, wrapped in a fast attack /
  /// long release envelope so the result sounds like a soft music box rather
  /// than a harsh beep. Distortion is baked into the waveform with a gentle
  /// `sin(x) + 0.4*sin(2x)` color.
  static Uint8List chimeWav(
    List<double> frequencies, {
    double noteMs = 130,
    double gapMs = 18,
  }) {
    final List<int> samples = <int>[];
    final int noteSamples = (sampleRate * noteMs / 1000).round();
    final int gapSamples = (sampleRate * gapMs / 1000).round();

    for (int n = 0; n < frequencies.length; n++) {
      final double freq = frequencies[n];
      final int attack = (noteSamples * 0.06).round();
      for (int i = 0; i < noteSamples; i++) {
        final double t = i / sampleRate;
        final double decay = exp(-2.2 * t);
        final double env = _envelope(i, noteSamples, attack);
        final double raw =
            sin(2 * pi * freq * t) + 0.4 * sin(4 * pi * freq * t);
        samples.add((32767 * 0.6 * raw * decay * env).round());
      }
      if (n < frequencies.length - 1) {
        samples.addAll(List<int>.filled(gapSamples, 0));
      }
    }

    return _toWav(samples);
  }

  static double _envelope(int i, int total, int attack) {
    if (i < attack) return i / attack;
    return 1.0;
  }

  // ------------------------------------------------------- game sound kit

  /// A bright, short UI "pop" - a sine that drops a fifth in pitch.
  static Uint8List popWav({
    double startHz = 460,
    double endHz = 260,
    double durationMs = 110,
  }) {
    final int total = (sampleRate * durationMs / 1000).round();
    final List<int> samples = <int>[];
    double phase = 0;
    for (int i = 0; i < total; i++) {
      final double t = i / total;
      final double freq = startHz + (endHz - startHz) * t;
      phase += 2 * pi * freq / sampleRate;
      // Soft click transient at the very start keeps it percussive.
      final double env = (1 - t) * (1 - t) * (i < 4 ? i / 4 : 1);
      samples.add((32767 * 0.5 * sin(phase) * env).round());
    }
    return _toWav(samples);
  }

  /// A clear "ding" for correct answers and rewards: two partials ringing out.
  static Uint8List dingWav({
    double freqHz = 880,
    double durationMs = 520,
  }) {
    final int total = (sampleRate * durationMs / 1000).round();
    final List<int> samples = <int>[];
    for (int i = 0; i < total; i++) {
      final double t = i / sampleRate;
      final double decay = exp(-3.4 * t);
      final double raw = sin(2 * pi * freqHz * t) +
          0.35 * sin(4 * pi * freqHz * t) +
          0.18 * sin(6 * pi * freqHz * t);
      final double attack = i < 60 ? i / 60 : 1.0;
      samples.add((32767 * 0.55 * raw * decay * attack).round());
    }
    return _toWav(samples);
  }

  /// A rounded, friendly "boop" for taps, selections and wrong-answer nudge.
  static Uint8List boopWav({
    double freqHz = 320,
    double durationMs = 150,
  }) {
    final int total = (sampleRate * durationMs / 1000).round();
    final List<int> samples = <int>[];
    for (int i = 0; i < total; i++) {
      final double t = i / sampleRate;
      final double decay = exp(-6.0 * t);
      final double raw =
          sin(2 * pi * freqHz * t) + 0.3 * sin(2 * pi * freqHz * 1.5 * t);
      final double attack = i < 80 ? i / 80 : 1.0;
      samples.add((32767 * 0.5 * raw * decay * attack).round());
    }
    return _toWav(samples);
  }

  /// A soft filtered-noise "whoosh" for screen transitions.
  static Uint8List whooshWav({double durationMs = 320}) {
    final int total = (sampleRate * durationMs / 1000).round();
    final Random random = Random(11);
    final List<int> samples = <int>[];
    double lowpass = 0;
    for (int i = 0; i < total; i++) {
      final double t = i / total;
      // Bell shaped volume...
      final double env = sin(pi * t) * (1 - t * 0.3);
      // ...with the cutoff opening up as it sweeps.
      final double cutoff = 0.04 + 0.35 * t;
      final double noise = random.nextDouble() * 2 - 1;
      lowpass += cutoff * (noise - lowpass);
      samples.add((32767 * 0.55 * lowpass * env).round());
    }
    return _toWav(samples);
  }

  /// A short celebratory fanfare (four rising notes) for level completion.
  static Uint8List fanfareWav() => chimeWav(
        const <double>[523.25, 659.25, 783.99, 1046.5],
        noteMs: 170,
        gapMs: 30,
      );

  /// Rising two-note "level up" blip used when a star is awarded.
  static Uint8List levelUpWav() => chimeWav(
        const <double>[392.0, 523.25, 783.99],
        noteMs: 120,
        gapMs: 24,
      );

  /// Packs mono 16-bit samples into a full WAV file byte array.
  static Uint8List _toWav(List<int> samples) {
    final int dataSize = samples.length * 2;
    final ByteData wav = ByteData(44 + dataSize);

    // "RIFF" chunk
    _setAscii(wav, 0, 'RIFF');
    wav.setUint32(4, 36 + dataSize, Endian.little);
    _setAscii(wav, 8, 'WAVE');

    // "fmt " chunk
    _setAscii(wav, 12, 'fmt ');
    wav.setUint32(16, 16, Endian.little); // fmt chunk size
    wav.setUint16(20, 1, Endian.little); // PCM
    wav.setUint16(22, 1, Endian.little); // mono
    wav.setUint32(24, sampleRate, Endian.little);
    wav.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    wav.setUint16(32, 2, Endian.little); // block align
    wav.setUint16(34, 16, Endian.little); // bits per sample

    // "data" chunk
    _setAscii(wav, 36, 'data');
    wav.setUint32(40, dataSize, Endian.little);
    for (int i = 0; i < samples.length; i++) {
      wav.setInt16(44 + i * 2, samples[i].clamp(-32768, 32767), Endian.little);
    }

    return wav.buffer.asUint8List();
  }

  static void _setAscii(ByteData data, int offset, String text) {
    for (int i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }
}