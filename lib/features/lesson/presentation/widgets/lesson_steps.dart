import 'package:flutter/material.dart';

import '../../../../core/motion/app_motion.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/emoji_picture.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../../../core/widgets/tracing_canvas.dart';
import '../../../numbers/presentation/widgets/count_objects.dart';
import '../../../quiz/domain/entities/quiz_option.dart';
import '../../../quiz/presentation/widgets/quiz_option_card.dart';
import '../../domain/lesson.dart';
import '../bloc/lesson_state.dart';

/// Voices the different lesson steps through the shared [AudioService].
///
/// Lives outside the widgets so the answer is never leaked by accident: the
/// picture-matching step hears only the letter sound, and the counting step
/// only hears its question.
class LessonAudio {
  LessonAudio({required AudioService audioService, required this.isAlphabet})
      : _audio = audioService;

  final AudioService _audio;
  final bool isAlphabet;

  Future<void> speakGlyph(LessonGlyph glyph) => isAlphabet
      ? _audio.speakPhonics(glyph.key, glyph.word)
      : _audio.speakNumber(glyph.word);

  Future<void> playPop() => _audio.playPop();

  /// Voices the step when it arrives and whenever the child taps the speaker.
  Future<void> announce(LessonStep step) async {
    switch (step) {
      case MeetStep():
        return;
      case TraceStep(:final LessonGlyph glyph):
        await _audio.speakText('Trace the ${glyph.key}');
      case PickStep(:final LessonGlyph target):
        await speakGlyph(target);
      case MatchStep(:final LessonGlyph target):
        await _audio.speakLetterSound(target.key);
      case CountStep():
        await _audio.speakText(step.prompt);
    }
  }
}

/// Big white instruction line (with an optional hint or trailing action).
class LessonPrompt extends StatelessWidget {
  const LessonPrompt(this.text, {super.key, this.hint, this.trailing});

  final String text;
  final String? hint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        AppTokens.space2,
        AppTokens.space5,
        AppTokens.space3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    fontVariations: <FontVariation>[
                      FontVariation('wght', 700),
                    ],
                    color: AppColors.inkBright,
                    height: 1.15,
                    shadows: <Shadow>[
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (hint != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTokens.space1),
                    child: Text(
                      hint!,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xCCFFFFFF),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// "Meet A, B, C" - one tap-to-hear tile per glyph.
class MeetStepView extends StatelessWidget {
  const MeetStepView({super.key, required this.step, required this.audio});

  final MeetStep step;
  final LessonAudio audio;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        LessonPrompt(step.prompt, hint: 'Tap a picture to hear it!'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space4,
              AppTokens.space2,
              AppTokens.space4,
              AppTokens.space4,
            ),
            // The whole tray of glyphs fades up together on one shared
            // controller, cascading left to right.
            child: MotionStagger(
              itemCount: step.glyphs.length,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: AppTokens.space3,
                runSpacing: AppTokens.space3,
                children: <Widget>[
                  for (int i = 0; i < step.glyphs.length; i++)
                    AppMotion(
                      index: i,
                      child: _GlyphTile(glyph: step.glyphs[i], audio: audio),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlyphTile extends StatelessWidget {
  const _GlyphTile({required this.glyph, required this.audio});

  final LessonGlyph glyph;
  final LessonAudio audio;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(glyph.colorValue);
    return PressableScale(
      onTap: () {
        audio.playPop();
        audio.speakGlyph(glyph);
      },
      child: Container(
        key: ValueKey<String>('lesson-glyph-${glyph.key}'),
        width: 106,
        padding: const EdgeInsets.symmetric(
          vertical: AppTokens.space3,
          horizontal: AppTokens.space2,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          border: Border.all(color: color, width: 3),
          boxShadow: AppTokens.softShadow(),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            EmojiPicture(emoji: glyph.emoji, color: color, fontSize: 40),
            const SizedBox(height: AppTokens.space1),
            Text(
              glyph.key,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 30,
                fontWeight: FontWeight.w700,
                fontVariations: const <FontVariation>[
                  FontVariation('wght', 700),
                ],
                color: color,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trace the level's middle glyph with a finger.
class TraceStepView extends StatelessWidget {
  const TraceStepView({
    super.key,
    required this.step,
    required this.audio,
    required this.onCompleted,
  });

  final TraceStep step;
  final LessonAudio audio;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        LessonPrompt(step.prompt, hint: 'Follow the dotted lines!'),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460, maxHeight: 420),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.all(AppTokens.space3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                    boxShadow: AppTokens.softShadow(),
                  ),
                  child: TracingCanvas(
                    label: step.glyph.key,
                    color: Color(step.glyph.colorValue),
                    onCompleted: onCompleted,
                    onReset: audio.playPop,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum ChallengeKind { pick, match, count }

/// Hear (or count) and tap the answer, for the last step of a lesson.
class ChallengeStepView extends StatelessWidget {
  const ChallengeStepView({
    super.key,
    required this.step,
    required this.state,
    required this.audio,
    required this.onOption,
  });

  final LessonStep step;
  final LessonState state;
  final LessonAudio audio;
  final ValueChanged<String> onOption;

  @override
  Widget build(BuildContext context) {
    final (LessonGlyph target, List<LessonGlyph> options, String prompt) =
        switch (step) {
      PickStep(:final LessonGlyph target, :final List<LessonGlyph> options, :final String prompt) =>
        (target, options, prompt),
      MatchStep(:final LessonGlyph target, :final List<LessonGlyph> options, :final String prompt) =>
        (target, options, prompt),
      CountStep(:final LessonGlyph target, :final List<LessonGlyph> options, :final String prompt) =>
        (target, options, prompt),
      _ => throw StateError('Not a challenge step: $step'),
    };
    final QuizOptionStyle style =
        step is MatchStep ? QuizOptionStyle.picture : QuizOptionStyle.numeral;

    return Column(
      children: <Widget>[
        LessonPrompt(
          prompt,
          trailing: _ReplayButton(onTap: () => audio.announce(step)),
        ),
        if (step is CountStep)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              0,
              AppTokens.space5,
              AppTokens.space2,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space3,
                vertical: AppTokens.space2,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                boxShadow: AppTokens.softShadow(),
              ),
              child: CountObjects(
                count: int.parse(target.key),
                emoji: target.emoji,
                color: Color(target.colorValue),
                maxHeight: 150,
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int columns = constraints.maxWidth >= 620 ? 4 : 2;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: GridView.count(
                    padding: const EdgeInsets.fromLTRB(
                      AppTokens.space4,
                      AppTokens.space1,
                      AppTokens.space4,
                      AppTokens.space4,
                    ),
                    crossAxisCount: columns,
                    mainAxisSpacing: AppTokens.space3,
                    crossAxisSpacing: AppTokens.space3,
                    childAspectRatio: 1,
                    children: <Widget>[
                      // QuizOptionCard staggers itself in via [entrancePhase],
                      // so it needs no extra wrapper here.
                      for (int i = 0; i < options.length; i++)
                        QuizOptionCard(
                          key: ValueKey<String>(
                            'lesson-option-${options[i].key}',
                          ),
                          entrancePhase: i / options.length,
                          option: QuizOption(
                            key: options[i].key,
                            displayText: options[i].key,
                            hintText: options[i].word,
                            emoji: options[i].emoji,
                            colorValue: options[i].colorValue,
                            style: style,
                          ),
                          isDimmed:
                              state.answered && options[i].key != target.key,
                          isWrong: state.wrongKey == options[i].key,
                          wrongToken: state.wrongToken,
                          isCorrect: options[i].key == target.key,
                          showCorrect: state.answered,
                          onTap: () => onOption(options[i].key),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReplayButton extends StatelessWidget {
  const _ReplayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Tooltip(
          message: 'Hear again',
          child: Padding(
            padding: EdgeInsets.all(AppTokens.space3),
            child: Icon(
              Icons.volume_up_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

