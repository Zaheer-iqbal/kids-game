import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/mascot/mascot_cubit.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/celebration_overlay.dart';
import '../../../../core/widgets/mascot_view.dart';
import '../../../../core/widgets/mascot_widget.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../domain/entities/quiz_option.dart';
import '../../domain/entities/quiz_result.dart';
import '../../domain/entities/quiz_type.dart';
import '../bloc/quiz_bloc.dart';
import '../bloc/quiz_event.dart';
import '../bloc/quiz_state.dart';
import '../widgets/quiz_option_card.dart';

/// Quiz screen for one of the four quiz modes: hear a prompt, tap the match.
class QuizPage extends StatelessWidget {
  const QuizPage({super.key, required this.quizType});

  final QuizType quizType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QuizBloc>(
      create: (_) => di.sl<QuizBloc>()..add(QuizStarted(quizType)),
      child: const QuizView(),
    );
  }
}

class QuizView extends StatelessWidget {
  const QuizView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocListener<QuizBloc, QuizState>(
          listenWhen: (QuizState previous, QuizState current) =>
              previous.wrongToken != current.wrongToken,
          listener: (BuildContext context, QuizState state) {
            // Never a sad mascot: a wrong answer gets a warm head tilt and an
            // encouraging line instead.
            context.read<MascotCubit>().encouraging(speak: true);
          },
          child: BlocListener<QuizBloc, QuizState>(
            listenWhen: (QuizState previous, QuizState current) =>
                previous.status == QuizStatus.ready &&
                current.status == QuizStatus.ready &&
                current.revealCorrect &&
                !previous.revealCorrect,
            listener: (BuildContext context, QuizState state) {
              context.read<MascotCubit>().happy(speak: true);
              unawaited(
                showCelebrationOverlay(context, message: 'Correct! +1'),
              );
              Timer(const Duration(milliseconds: 1300), () {
                if (context.mounted) {
                  context.read<QuizBloc>().add(const NextQuestion());
                }
              });
            },
            child: BlocBuilder<QuizBloc, QuizState>(
              builder: (BuildContext context, QuizState state) {
                return switch (state.status) {
                  QuizStatus.initial || QuizStatus.loading =>
                    const Center(child: CircularProgressIndicator()),
                  QuizStatus.error => _QuizErrorView(
                      error: state.error,
                      quizType: state.quizType,
                    ),
                  QuizStatus.finished => _QuizFinishedNavigator(state: state),
                  QuizStatus.ready => _QuizPlayView(state: state),
                };
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Switches to the results screen once the quiz wraps up.
class _QuizFinishedNavigator extends StatefulWidget {
  const _QuizFinishedNavigator({required this.state});

  final QuizState state;

  @override
  State<_QuizFinishedNavigator> createState() => _QuizFinishedNavigatorState();
}

class _QuizFinishedNavigatorState extends State<_QuizFinishedNavigator> {
  bool _navigated = false;

  @override
  Widget build(BuildContext context) {
    if (!_navigated) {
      _navigated = true;
      final QuizResult result = widget.state.result ?? QuizResult(
            type: widget.state.quizType,
            score: widget.state.score,
            totalQuestions: widget.state.totalQuestions,
            newHighScore: widget.state.newHighScore,
            bestScore: widget.state.highScore,
          );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushReplacement(
            AppRoutes.quizResults,
            extra: result,
          );
        }
      });
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class _QuizPlayView extends StatelessWidget {
  const _QuizPlayView({required this.state});

  final QuizState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Landscape phones are short: tighten the frame and drop the extra mascot
    // so the fixed header/prompt can never outgrow the window.
    final bool compact = Responsive.isShort(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, compact ? 4 : 10, 20, compact ? 10 : 24),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 30),
                tooltip: 'Back to quizzes',
              ),
              const Spacer(),
              _ScoreChip(
                icon: Icons.emoji_events_rounded,
                color: AppColors.gold,
                label: '${state.score}',
              ),
              const SizedBox(width: 10),
              _ScoreChip(
                icon: Icons.star_rounded,
                color: AppColors.inkMuted,
                label: '${state.highScore}',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Question ${state.questionNumber} of ${state.totalQuestions}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Column(
                children: <Widget>[
                  _SoundButton(
                    onPressed: () =>
                        context.read<QuizBloc>().add(const ReplaySound()),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    state.promptTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _RetryPrompt(),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      // Landscape gets a single row of options; portrait uses
                      // two columns. Either way the tiles stay square and
                      // shrink with the available width.
                      final int columns = Responsive.isLandscape(context)
                          ? state.options.length.clamp(2, 4)
                          : 2;
                      final double cellWidth =
                          (constraints.maxWidth - (columns - 1) * 14) / columns;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.options.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          mainAxisExtent: cellWidth.clamp(96, 240).toDouble(),
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final QuizOption option = state.options[index];
                          return QuizOptionCard(
                            key: ValueKey<String>('option-${option.key}'),
                            option: option,
                            entrancePhase: index / state.options.length,
                            isDimmed: state.revealCorrect &&
                                option.key != state.targetKey,
                            isWrong: state.wrongOption == option.key,
                            wrongToken: state.wrongToken,
                            isCorrect: option.key == state.targetKey,
                            showCorrect: state.revealCorrect &&
                                option.key == state.targetKey,
                            onTap: () => context
                                .read<QuizBloc>()
                                .add(OptionSelected(option)),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          if (!compact)
            const Padding(
              padding: EdgeInsets.only(left: 6, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: MascotView(
                  key: ValueKey<String>('quiz-mascot'),
                  size: 86,
                  bubbleLayout: MascotBubbleLayout.leading,
                  bubbleMaxWidth: 200,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RetryPrompt extends StatelessWidget {
  const _RetryPrompt();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuizBloc, QuizState>(
      buildWhen: (QuizState previous, QuizState current) =>
          previous.wrongOption != current.wrongOption,
      builder: (BuildContext context, QuizState state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (Widget child, Animation<double> animation) =>
              FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.2),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: state.wrongOption == null
              ? const SizedBox(
                  key: ValueKey<String>('retry-none'),
                  height: 24,
                )
              : Padding(
                  key: const ValueKey<String>('retry-prompt'),
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const <Widget>[
                      Icon(
                        Icons.sentiment_satisfied_alt_rounded,
                        color: AppColors.quiz,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Oops! Give it another try!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.quiz,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _SoundButton extends StatelessWidget {
  const _SoundButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onPressed,
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[AppColors.quiz, Color(0xFFFFB199)],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.quiz.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.volume_up_rounded,
          color: Colors.white,
          size: 68,
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.icon, required this.color, required this.label});

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuizErrorView extends StatelessWidget {
  const _QuizErrorView({required this.error, required this.quizType});

  final String? error;
  final QuizType quizType;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.sentiment_dissatisfied_rounded,
            size: 56,
            color: AppColors.inkMuted,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () =>
                context.read<QuizBloc>().add(QuizStarted(quizType)),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}