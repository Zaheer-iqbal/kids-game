import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/mascot/mascot_cubit.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/delight_settings.dart';
import '../../../../core/widgets/game_button.dart';
import '../../../../core/widgets/illustrated_background.dart';
import '../../../../core/widgets/mascot_view.dart';
import '../../../../core/widgets/particle_field.dart';
import '../../../../core/widgets/star_badge.dart';
import '../../domain/lesson.dart';
import '../../domain/lesson_repository.dart';
import '../bloc/lesson_bloc.dart';
import '../bloc/lesson_event.dart';
import '../bloc/lesson_state.dart';
import '../widgets/lesson_steps.dart';

/// One playable level: loads the lesson for `<world, level>` and hands it to
/// the game shell. Shows a friendly retry screen if the level cannot load.
class LessonPage extends StatefulWidget {
  const LessonPage({super.key, required this.worldId, required this.level});

  final String worldId;
  final int level;

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late Future<Lesson> _lesson;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _lesson = di.sl<LessonRepository>()
        .buildLesson(widget.worldId, widget.level);
  }

  void _retry() => setState(_load);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Lesson>(
      future: _lesson,
      builder: (BuildContext context, AsyncSnapshot<Lesson> snapshot) {
        if (snapshot.hasError) {
          return _LessonMessage(
            icon: Icons.sentiment_dissatisfied_rounded,
            message: 'Oops! That level is not ready yet.',
            buttonLabel: 'Try again',
            onPressed: _retry,
          );
        }
        final Lesson? lesson = snapshot.data;
        if (lesson == null) {
          return const _LessonLoading();
        }
        return BlocProvider<LessonBloc>(
          create: (_) => LessonBloc(
            lesson: lesson,
            audioService: di.sl<AudioService>(),
            progressService: di.sl<ProgressService>(),
          ),
          child: LessonView(lesson: lesson),
        );
      },
    );
  }
}

class LessonView extends StatelessWidget {
  const LessonView({super.key, required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final bool isAlphabet = lesson.worldId == 'alphabet';
    final LessonAudio audio = LessonAudio(
      audioService: di.sl<AudioService>(),
      isAlphabet: isAlphabet,
    );

    return BlocListener<LessonBloc, LessonState>(
      listenWhen: (LessonState previous, LessonState current) =>
          previous.wrongToken != current.wrongToken ||
          current.status != previous.status ||
          (current.answered && !previous.answered),
      listener: (BuildContext context, LessonState state) {
        final MascotCubit mascot = context.read<MascotCubit>();
        if (state.status == LessonStatus.finished) {
          mascot.excited(speak: true);
        } else if (!state.answered && state.wrongKey != null) {
          mascot.encouraging(speak: true);
        } else if (state.answered) {
          mascot.happy(speak: true);
        }
      },
      child: BlocBuilder<LessonBloc, LessonState>(
        builder: (BuildContext context, LessonState state) {
          final LessonBloc bloc = context.read<LessonBloc>();
          final LessonStep step = lesson.steps[state.stepIndex];
          final bool isLast = state.stepIndex == lesson.steps.length - 1;
          final _Feedback? feedback = _feedbackFor(step, state);

          return Scaffold(
            backgroundColor: AppColors.bgTop,
            body: Stack(
              children: <Widget>[
                const Positioned.fill(child: IllustratedBackground()),
                SafeArea(
                  child: Column(
                    children: <Widget>[
                      _LessonHeader(lesson: lesson, state: state),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: AppTokens.screenFade,
                          child: _StepHost(
                            key: ValueKey<int>(state.stepIndex),
                            audio: audio,
                            step: step,
                            child: _buildStep(step, state, audio, bloc),
                          ),
                        ),
                      ),
                      _LessonFooter(
                        feedback: feedback,
                        showNext: step is MeetStep || state.answered,
                        isLast: isLast,
                        onNext: () => bloc.add(const LessonNextPressed()),
                      ),
                    ],
                  ),
                ),
                if (state.status == LessonStatus.finished)
                  _LevelCompleteView(lesson: lesson, stars: state.stars),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep(
    LessonStep step,
    LessonState state,
    LessonAudio audio,
    LessonBloc bloc,
  ) {
    switch (step) {
      case MeetStep():
        return MeetStepView(step: step, audio: audio);
      case TraceStep():
        return TraceStepView(
          step: step,
          audio: audio,
          onCompleted: () => bloc.add(const LessonStepCompleted()),
        );
      case PickStep():
      case MatchStep():
      case CountStep():
        return ChallengeStepView(
          step: step,
          state: state,
          audio: audio,
          onOption: (String key) => bloc.add(LessonAnswered(key)),
        );
    }
  }
}

_Feedback? _feedbackFor(LessonStep step, LessonState state) {
  if (!state.answered) {
    if (state.wrongKey != null) {
      return const _Feedback(
        'Oops! Give it another try!',
        AppColors.accentOrange,
      );
    }
    return null;
  }
  if (step is MeetStep) {
    return null;
  }
  if (step is TraceStep) {
    return const _Feedback('Traced!', AppColors.success);
  }
  return const _Feedback('Great job!', AppColors.success);
}

@immutable
class _Feedback {
  const _Feedback(this.text, this.color);

  final String text;
  final Color color;
}

/// Speaks the step once it is on screen, then shows its content.
class _StepHost extends StatefulWidget {
  const _StepHost({
    super.key,
    required this.audio,
    required this.step,
    required this.child,
  });

  final LessonAudio audio;
  final LessonStep step;
  final Widget child;

  @override
  State<_StepHost> createState() => _StepHostState();
}

class _StepHostState extends State<_StepHost> {
  @override
  void initState() {
    super.initState();
    final LessonAudio audio = widget.audio;
    final LessonStep step = widget.step;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) audio.announce(step);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({required this.lesson, required this.state});

  final Lesson lesson;
  final LessonState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              key: const ValueKey<String>('lesson-close'),
              tooltip: 'Back to home',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.inkBright,
                size: 30,
              ),
            ),
            Expanded(
              child: Text(
                lesson.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontVariations: <FontVariation>[
                    FontVariation('wght', 600),
                  ],
                  color: AppColors.inkBright,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppTokens.space4),
              child: Text(
                '${state.stepIndex + 1}/${lesson.steps.length}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xCCFFFFFF),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.space2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < lesson.steps.length; i++)
                AnimatedContainer(
                  duration: AppTokens.screenFade,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space1,
                  ),
                  width: i == state.stepIndex ? 22 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: i < state.stepIndex
                        ? AppColors.success
                        : i == state.stepIndex
                            ? AppColors.inkBright
                            : const Color(0x55FFFFFF),
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LessonFooter extends StatelessWidget {
  const _LessonFooter({
    required this.feedback,
    required this.showNext,
    required this.isLast,
    required this.onNext,
  });

  final _Feedback? feedback;
  final bool showNext;
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        AppTokens.space2,
        AppTokens.space5,
        AppTokens.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 30,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: feedback == null
                  ? const SizedBox.shrink()
                  : Text(
                      feedback!.text,
                      key: ValueKey<String>(feedback!.text),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontVariations: const <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        color: feedback!.color,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          if (showNext)
            GameButton.large(
              key: const ValueKey<String>('lesson-next'),
              label: isLast ? 'Finish' : 'Next',
              onPressed: onNext,
            )
          else
            const SizedBox(height: 72),
        ],
      ),
    );
  }
}

class _LevelCompleteView extends StatelessWidget {
  const _LevelCompleteView({required this.lesson, required this.stars});

  final Lesson lesson;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final bool animate = DelightSettings.of(context).animationsEnabled;
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.bgTop.withValues(alpha: 0.94),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: animate ? 1 : 0),
          duration: const Duration(milliseconds: 900),
          builder: (BuildContext context, double burst, Widget? child) {
            return Stack(
              children: <Widget>[
                if (animate)
                  Positioned.fill(child: BurstOverlay(progress: burst)),
                child!,
              ],
            );
          },
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: AppTokens.screenPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Level complete!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                        color: AppColors.inkBright,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space3),
                    RatingStars(earned: stars, size: 46, animate: animate),
                    const SizedBox(height: AppTokens.space3),
                    const MascotView(size: 120, showBubble: false),
                    const SizedBox(height: AppTokens.space2),
                    Text(
                      stars == 3
                          ? 'Purr-fect! You are a star!'
                          : 'Great work! Keep going!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xE6FFFFFF),
                      ),
                    ),
                    const SizedBox(height: AppTokens.space5),
                    GameButton.large(
                      key: const ValueKey<String>('lesson-continue'),
                      label: 'Continue',
                      color: AppColors.accentMint,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonLoading extends StatelessWidget {
  const _LessonLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: IllustratedBackground()),
          Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
        ],
      ),
    );
  }
}

class _LessonMessage extends StatelessWidget {
  const _LessonMessage({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: IllustratedBackground()),
          SafeArea(
            child: Padding(
              padding: AppTokens.screenPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, color: AppColors.gold, size: 64),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontVariations: <FontVariation>[
                        FontVariation('wght', 700),
                      ],
                      color: AppColors.inkBright,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space5),
                  GameButton.large(label: buttonLabel, onPressed: onPressed),
                  const SizedBox(height: AppTokens.space3),
                  GameButton.small(
                    label: 'Back to home',
                    color: AppColors.accentCoral,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
