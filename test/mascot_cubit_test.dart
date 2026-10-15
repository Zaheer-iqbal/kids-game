import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids/core/mascot/mascot_cubit.dart';
import 'package:kids/core/mascot/mascot_mood.dart';
import 'package:kids/core/mascot/mascot_state.dart';
import 'package:kids/core/services/audio_service.dart';
import 'package:kids/core/settings/data/settings_repository_impl.dart';
import 'package:kids/core/settings/presentation/settings_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what would have been spoken, so the tests never touch the platform
/// TTS channel.
class _RecordingAudioService extends AudioService {
  final List<String> spoken = <String>[];

  @override
  Future<void> speakText(String text, {String? clipKey}) async =>
      spoken.add(text);
}

Future<({MascotCubit mascot, _RecordingAudioService audio, SettingsCubit settings})>
    buildCubit({
  bool speechEnabled = true,
  int? randomSeed,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    if (!speechEnabled) SettingsRepositoryImpl.speechKey: false,
  });
  final SharedPreferences store = await SharedPreferences.getInstance();
  final SettingsCubit settings =
      SettingsCubit(repository: SettingsRepositoryImpl(store))..load();
  final _RecordingAudioService audio = _RecordingAudioService();
  return (
    mascot: MascotCubit(
      audioService: audio,
      settingsCubit: settings,
      random: randomSeed == null ? Random() : Random(randomSeed),
    ),
    audio: audio,
    settings: settings,
  );
}

void main() {
  // AudioService builds a FlutterTts instance, which needs the binary messenger
  // to exist even though the tests never speak through it.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mascot voice lines', () {
    test('every mood has at least 8 short, friendly, non-empty lines', () {
      for (final MascotMood mood in MascotMood.values) {
        final List<String> lines = mood.lines;
        expect(lines.length, greaterThanOrEqualTo(8), reason: '$mood');
        expect(lines.toSet().length, lines.length,
            reason: '$mood should not repeat a line');
        for (final String line in lines) {
          expect(line.trim(), line, reason: 'no stray whitespace in "$line"');
          expect(line, isNotEmpty);
          expect(line.length, lessThan(70), reason: '"$line" is too long');
          expect(
            RegExp(r'\b(sad|bad|stupid|wrong|fail|lose)\b', caseSensitive: false)
                .hasMatch(line),
            isFalse,
            reason: '"$line" must never feel negative',
          );
        }
      }
    });

    test('there are plenty of giggles to tap through', () {
      expect(mascotGiggles.length, greaterThanOrEqualTo(8));
    });
  });

  group('MascotCubit', () {
    test('starts calm and silent', () async {
      final cubit = await buildCubit();

      expect(cubit.mascot.state, const MascotState());
      expect(cubit.mascot.state.mood, MascotMood.idle);
      expect(cubit.mascot.state.message, isNull);
      expect(cubit.audio.spoken, isEmpty);

      await cubit.mascot.close();
      await cubit.settings.close();
    });

    test('every reaction mood reaches the cubit with one of its own lines',
        () async {
      final cubit = await buildCubit();

      cubit.mascot.happy();
      expect(cubit.mascot.state.mood, MascotMood.happy);
      expect(cubit.mascot.state.isReacting, isTrue);
      expect(cubit.mascot.state.message, isIn(MascotMood.happy.lines));

      cubit.mascot.excited();
      expect(cubit.mascot.state.mood, MascotMood.excited);
      expect(cubit.mascot.state.message, isIn(MascotMood.excited.lines));

      cubit.mascot.encouraging();
      expect(cubit.mascot.state.mood, MascotMood.encouraging);
      expect(cubit.mascot.state.message, isIn(MascotMood.encouraging.lines));

      await cubit.mascot.close();
      await cubit.settings.close();
    });

    test('repeating the same mood bumps the token so the animation replays',
        () async {
      final cubit = await buildCubit();

      cubit.mascot.happy();
      final int firstToken = cubit.mascot.state.token;
      cubit.mascot.happy();

      expect(cubit.mascot.state.mood, MascotMood.happy);
      expect(cubit.mascot.state.token, firstToken + 1,
          reason: 'a repeated happy must restart the reaction');

      await cubit.mascot.close();
      await cubit.settings.close();
    });

    test('lines vary between taps and never stick on one', () async {
      final cubit = await buildCubit(randomSeed: 20260928);

      final Set<String> seen = <String>{};
      for (int i = 0; i < 40; i++) {
        cubit.mascot.happy();
        seen.add(cubit.mascot.state.message!);
      }

      expect(seen.length, greaterThan(3),
          reason: 'the same line should not be chosen every single time');
      expect(seen, everyElement(isIn(MascotMood.happy.lines)));

      await cubit.mascot.close();
      await cubit.settings.close();
    });

    test('the same seed produces the same sequence', () async {
      final first = await buildCubit(randomSeed: 7);
      final second = await buildCubit(randomSeed: 7);

      final List<String?> firstLines = <String?>[];
      final List<String?> secondLines = <String?>[];
      for (int i = 0; i < 5; i++) {
        first.mascot.excited();
        second.mascot.excited();
        firstLines.add(first.mascot.state.message);
        secondLines.add(second.mascot.state.message);
      }

      expect(firstLines, secondLines);

      await first.mascot.close();
      await first.settings.close();
      await second.mascot.close();
      await second.settings.close();
    });

    test('a giggle keeps the mood and only bumps the giggle token', () async {
      final cubit = await buildCubit();

      cubit.mascot
        ..happy()
        ..giggle();

      expect(cubit.mascot.state.mood, MascotMood.happy,
          reason: 'a tap on the owl must not change how it feels');
      expect(cubit.mascot.state.message, isIn(mascotGiggles));
      expect(cubit.mascot.state.giggleToken, 1);

      await cubit.mascot.close();
      await cubit.settings.close();
    });

    test('idle returns to the calm pose and hides the bubble', () async {
      final cubit = await buildCubit();

      cubit.mascot
        ..excited()
        ..idle();

      expect(cubit.mascot.state.mood, MascotMood.idle);
      expect(cubit.mascot.state.message, isNull);
      expect(cubit.mascot.state.isReacting, isFalse);

      await cubit.mascot.close();
      await cubit.settings.close();
    });

    test('going idle twice emits only once', () async {
      final cubit = await buildCubit();
      int emissions = 0;
      final sub = cubit.mascot.stream.listen((_) => emissions++);

      cubit.mascot
        ..happy()
        ..idle();
      await pumpEventQueue();
      cubit.mascot.idle();
      await pumpEventQueue();

      expect(emissions, 2, reason: 'the second idle() must be a no-op');
      await sub.cancel();
      await cubit.mascot.close();
      await cubit.settings.close();
    });

    test('a silent reaction is the default on the learning grids', () async {
      final cubit = await buildCubit();

      // The letter or number itself is being read out loud, so the mascot only
      // reacts visually unless a caller explicitly asks for speech.
      cubit.mascot
        ..happy()
        ..excited()
        ..encouraging();
      expect(cubit.audio.spoken, isEmpty);

      await cubit.mascot.close();
      await cubit.settings.close();
    });

    test('speak: true reads the line out loud', () async {
      final cubit = await buildCubit();

      cubit.mascot.happy(speak: true);
      final String happyLine = cubit.mascot.state.message!;
      cubit.mascot.excited(speak: true);
      final String excitedLine = cubit.mascot.state.message!;
      await pumpEventQueue();

      // Speech and bubble share one source, so a child always hears exactly
      // what they read.
      expect(cubit.audio.spoken, <String>[happyLine, excitedLine]);
      expect(happyLine, isIn(MascotMood.happy.lines));
      expect(excitedLine, isIn(MascotMood.excited.lines));

      await cubit.mascot.close();
      await cubit.settings.close();
    });

    test('a giggle always squeaks, and respects the parent switch', () async {
      final chatty = await buildCubit();
      chatty.mascot.giggle();
      await pumpEventQueue();
      expect(chatty.audio.spoken, isNotEmpty);
      expect(chatty.audio.spoken.single, isIn(mascotGiggles));

      final quiet = await buildCubit(speechEnabled: false);
      quiet.mascot
        ..giggle()
        ..excited(speak: true)
        ..setMood(MascotMood.idle, speak: true);
      await pumpEventQueue();

      expect(quiet.audio.spoken, isEmpty,
          reason: 'a parent turned the mascot voice off');
      // The visual part still happens while the voice stays silent.
      expect(quiet.mascot.state.mood, MascotMood.idle);
      expect(quiet.mascot.state.message, isNotNull);

      await chatty.mascot.close();
      await chatty.settings.close();
      await quiet.mascot.close();
      await quiet.settings.close();
    });

    test('turning the voice off mid-session silences the next reaction',
        () async {
      final cubit = await buildCubit();

      cubit.mascot.excited(speak: true);
      await pumpEventQueue();
      expect(cubit.audio.spoken, hasLength(1));

      cubit.settings.setMascotSpeechEnabled(false);
      cubit.mascot.excited(speak: true);
      await pumpEventQueue();

      expect(cubit.audio.spoken, hasLength(1));

      await cubit.mascot.close();
      await cubit.settings.close();
    });

    test('dismissBubble keeps the mood and only hides the line', () async {
      final cubit = await buildCubit();

      cubit.mascot
        ..encouraging()
        ..dismissBubble();

      expect(cubit.mascot.state.mood, MascotMood.encouraging);
      expect(cubit.mascot.state.message, isNull);

      await cubit.mascot.close();
      await cubit.settings.close();
    });
  });
}
