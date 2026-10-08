import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/audio_service.dart';
import '../settings/presentation/settings_cubit.dart';
import 'mascot_mood.dart';
import 'mascot_state.dart';

/// Holds the mascot's mood plus the line it says.
///
/// The cubit is the single source of truth for the mascot: screens push
/// reactions in ([happy], [excited], [encouraging], [giggle]) and
/// [MascotView] renders whatever comes out. It owns no timers — the return to
/// idle is driven by the mascot's own reaction animation (see
/// `MascotWidget.onSettle`), so the cubit can never keep a frame or a fake
/// clock busy after the mascot is gone.
class MascotCubit extends Cubit<MascotState> {
  MascotCubit({
    required AudioService audioService,
    required SettingsCubit settingsCubit,
    Random? random,
  })  : _audioService = audioService,
        _settingsCubit = settingsCubit,
        _random = random ?? Random(),
        super(const MascotState());

  final AudioService _audioService;
  final SettingsCubit _settingsCubit;
  final Random _random;

  /// Picks one of the mood's lines at random.
  String randomLineFor(MascotMood mood) {
    final List<String> lines = mood.lines;
    return lines[_random.nextInt(lines.length)];
  }

  /// Shows [mood] with a random speech bubble, or an exact [message] when the
  /// screen has to say something specific (for example "Great job!").
  ///
  /// Pass `speak: true` when nothing else is talking — on the learning grids
  /// the letter or number is already being read out loud, so the mascot stays
  /// silent there and only reacts visually.
  void setMood(MascotMood mood, {bool speak = false, String? message}) {
    final String line = message ?? randomLineFor(mood);
    emit(MascotState(
      mood: mood,
      message: line,
      token: state.token + 1,
      giggleToken: state.giggleToken,
    ));
    if (speak) _speak(line);
  }

  /// Drops back to the calm idle pose and hides the bubble.
  void idle() {
    if (state.mood == MascotMood.idle && state.message == null) return;
    emit(MascotState(token: state.token + 1, giggleToken: state.giggleToken));
  }

  /// A letter or number was tapped, or an answer was right.
  void happy({bool speak = false, String? message}) =>
      setMood(MascotMood.happy, speak: speak, message: message);

  /// A star, badge or milestone was earned.
  void excited({bool speak = false, String? message}) =>
      setMood(MascotMood.excited, speak: speak, message: message);

  /// A wrong answer: warm and encouraging, never negative.
  void encouraging({bool speak = false}) =>
      setMood(MascotMood.encouraging, speak: speak);

  /// The child tapped the mascot itself: wiggle plus a short squeak.
  void giggle() {
    final String line = mascotGiggles[_random.nextInt(mascotGiggles.length)];
    emit(state.copyWith(
      message: line,
      token: state.token + 1,
      giggleToken: state.giggleToken + 1,
    ));
    _speak(line);
  }

  /// Hides the bubble without touching the mood.
  void dismissBubble() {
    if (state.message == null) return;
    emit(state.copyWith(message: null));
  }

  /// Reads the line aloud, unless a parent turned mascot speech off.
  void _speak(String line) {
    if (!_settingsCubit.state.mascotSpeechEnabled) return;
    unawaited(_audioService.speakText(line));
  }
}
