import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids/core/services/tone_generator.dart';

void main() {
  group('ToneGenerator', () {
    test('chimeWav emits a well-formed 16-bit PCM WAV', () {
      final Uint8List bytes = ToneGenerator.chimeWav(const <double>[440.0]);
      expect(bytes.length, greaterThan(44));

      String ascii(int offset, int count) =>
          String.fromCharCodes(bytes.sublist(offset, offset + count));
      expect(ascii(0, 4), 'RIFF');
      expect(ascii(8, 4), 'WAVE');
      expect(ascii(12, 4), 'fmt ');
      expect(ascii(36, 4), 'data');

      final ByteData bd = ByteData.sublistView(bytes);
      expect(bd.getUint16(20, Endian.little), 1); // PCM
      expect(bd.getUint16(22, Endian.little), 1); // mono
      expect(bd.getUint32(24, Endian.little), ToneGenerator.sampleRate);
      expect(bd.getUint16(34, Endian.little), 16); // bits/sample
      expect(
        bd.getUint32(40, Endian.little),
        bytes.length - 44,
        reason: 'data size matches payload',
      );
    });

    test('multi-note chimes produce separable note/gap sections', () {
      final Uint8List bytes = ToneGenerator.chimeWav(const <double>[523.25, 659.25]);
      expect(bytes.length, greaterThan(44));
      final ByteData bd = ByteData.sublistView(bytes);
      final int total =
          bd.getUint32(40, Endian.little) ~/ 2; // number of samples
      final int noteSamples = (22050 * 130 / 1000).round();
      final int gapSamples = (22050 * 18 / 1000).round();
      expect(total, 2 * noteSamples + gapSamples);
      // A silent gap separates the two notes.
      final int gapStart = noteSamples;
      int maxAbs = 0;
      for (int i = 0; i < gapSamples; i++) {
        final int sample =
            bd.getInt16(44 + (gapStart + i) * 2, Endian.little).abs();
        if (sample > maxAbs) maxAbs = sample;
      }
      expect(maxAbs, 0, reason: 'gap between notes must be silent');
    });

    test('samples stay within 16-bit range', () {
      final Uint8List bytes = ToneGenerator.chimeWav(const <double>[880.0]);
      final ByteData bd = ByteData.sublistView(bytes);
      final int total = bd.getUint32(40, Endian.little) ~/ 2;
      for (int i = 0; i < total; i++) {
        final int s = bd.getInt16(44 + i * 2, Endian.little);
        expect(s, inInclusiveRange(-32768, 32767));
      }
    });
  });
}