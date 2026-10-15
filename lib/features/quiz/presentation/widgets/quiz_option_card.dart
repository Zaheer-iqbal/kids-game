import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/emoji_picture.dart';
import '../../../../core/widgets/pressable_scale.dart';
import '../../domain/entities/quiz_option.dart';

/// One answer choice in any quiz mode. Shows the emoji picture for letters
/// or a big numeral for numbers. Bounces in on arrival, shakes gently on a
/// wrong tap, and pulses green when revealed as the correct answer.
class QuizOptionCard extends StatefulWidget {
  const QuizOptionCard({
    super.key,
    required this.option,
    required this.isDimmed,
    required this.isWrong,
    required this.wrongToken,
    required this.isCorrect,
    required this.showCorrect,
    required this.onTap,
    this.entrancePhase = 0,
    this.isHidden = false,
  });

  final QuizOption option;
  final bool isDimmed;
  final bool isWrong;
  final int wrongToken;
  final bool isCorrect;
  final bool showCorrect;
  final VoidCallback onTap;

  /// 0..1 stagger so cards pop in one after another on a new question.
  final double entrancePhase;

  /// True once a hint has removed this (wrong) option: it fades away and can
  /// no longer be tapped.
  final bool isHidden;

  @override
  State<QuizOptionCard> createState() => _QuizOptionCardState();
}

class _QuizOptionCardState extends State<QuizOptionCard>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  late final Animation<double> _shakeOffset = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: -9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 16,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -9, end: 8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 16,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 8, end: -6)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 16,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -6, end: 5)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 16,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 5, end: -3)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 16,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -3, end: 0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
    ],
  ).animate(_shakeController);

  late final AnimationController _popController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  /// One-shot entrance: a small bounce-and-wiggle that finishes on its own so
  /// `pumpAndSettle` always settles.
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  late final CurvedAnimation _entranceProgress = CurvedAnimation(
    parent: _entranceController,
    // Bounded [0,1] so feeding it into the TweenSequence stays valid; the
    // "bounce" for the entrance is applied as a scalar on the scale below.
    curve: Interval(
      widget.entrancePhase.clamp(0.0, 0.6).toDouble(),
      1.0,
      curve: Curves.easeOut,
    ),
  );

  late final Animation<double> _entranceAngle = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -0.06, end: 0.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.05, end: -0.02)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -0.02, end: 0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
    ],
  ).animate(_entranceProgress);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _entranceController.forward(from: 0);
      }
    });
  }

  @override
  void didUpdateWidget(QuizOptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWrong && widget.wrongToken != oldWidget.wrongToken) {
      _shakeController.forward(from: 0);
    }
    if (widget.showCorrect && widget.isCorrect && !oldWidget.showCorrect) {
      _popController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _popController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool revealed = widget.showCorrect && widget.isCorrect;

    return IgnorePointer(
      ignoring: widget.isHidden,
      child: AnimatedOpacity(
        opacity: widget.isHidden ? 0 : 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: PressableScale(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              _shakeController,
              _popController,
              _entranceController,
            ]),
            builder: (BuildContext context, Widget? child) {
              return Transform.translate(
                offset: Offset(_shakeOffset.value, 0),
                child: Transform.rotate(
                  angle: _entranceAngle.value,
                  child: Transform.scale(
                    scale: (0.7 + 0.3 * _entranceProgress.value) *
                        (0.9 +
                            0.1 *
                                Curves.easeOutBack
                                    .transform(_popController.value)),
                    child: child,
                  ),
                ),
              );
            },
            child: _OptionFace(
              option: widget.option,
              isDimmed: widget.isDimmed,
              isWrong: widget.isWrong,
              revealed: revealed,
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionFace extends StatelessWidget {
  const _OptionFace({
    required this.option,
    required this.isDimmed,
    required this.isWrong,
    required this.revealed,
  });

  final QuizOption option;
  final bool isDimmed;
  final bool isWrong;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isDimmed ? 0.45 : 1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isWrong ? const Color(0xFFFFE8C9) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: revealed
                ? AppColors.success
                : isWrong
                    ? AppColors.quiz
                    : const Color(0xDDEFDFCF),
            width: revealed ? 4 : (isWrong ? 3 : 2),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: option.style == QuizOptionStyle.picture
                    ? EmojiPicture(
                        key: ValueKey<String>('emoji-${option.key}'),
                        emoji: option.emoji,
                        color: Color(option.colorValue),
                        fontSize: 96,
                      )
                    : _NumeralFace(option: option),
              ),
            ),
            if (revealed)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Gradient tile with the number's emoji peeking in from the corner and a big
/// white numeral on top.
class _NumeralFace extends StatelessWidget {
  const _NumeralFace({required this.option});

  final QuizOption option;

  @override
  Widget build(BuildContext context) {
    final Color color = Color(option.colorValue);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[color, Color.lerp(color, Colors.white, 0.22)!],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Text(
                  option.displayText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: (constraints.maxWidth * 0.34).clamp(28, 64).toDouble(),
                    shadows: const <Shadow>[
                      Shadow(
                        color: Color(0x33000000),
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 4,
            bottom: 2,
            child: EmojiPicture(
              emoji: option.emoji,
              fontSize: (MediaQuery.sizeOf(context).width * 0.05).clamp(16, 30),
              tint: false,
            ),
          ),
        ],
      ),
    );
  }
}