import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/mascot/mascot_cubit.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/fun_facts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/celebration_overlay.dart';
import '../../../../core/widgets/emoji_picture.dart';
import '../../../../core/widgets/fun_fact_bubble.dart';
import '../../../../core/widgets/tracing_canvas.dart';
import '../../domain/entities/letter_item.dart';

/// Bottom sheet shown when a letter card is tapped: the big letter with its
/// emoji picture, the "A for Apple" phrase, a replay button and an in-sheet
/// finger-tracing canvas.
class LetterDetailSheet extends StatefulWidget {
  const LetterDetailSheet({super.key, required this.letter});

  final LetterItem letter;

  static Future<void> show(BuildContext context, LetterItem letter) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      builder: (BuildContext sheetContext) => FractionallySizedBox(
        alignment: Alignment.bottomCenter,
        heightFactor: 0.86,
        child: LetterDetailSheet(letter: letter),
      ),
    );
  }

  @override
  State<LetterDetailSheet> createState() => _LetterDetailSheetState();
}

class _LetterDetailSheetState extends State<LetterDetailSheet> {
  bool _traced = false;

  void _replaySound() {
    unawaited(di.sl<AudioService>()
        .speakPhonics(widget.letter.letter, widget.letter.word));
  }

  void _onTraceCompleted() {
    setState(() => _traced = true);
    // Tracing the whole letter is a milestone: Pip jumps and says exactly
    // "Great job!", then the confetti and the star appear.
    di.sl<MascotCubit>().excited(speak: true, message: 'Great job!');
    unawaited(showCelebrationOverlay(
      context,
      message: 'Great job!',
    ));
  }

  void _hearFact() {
    unawaited(di.sl<AudioService>()
        .speakFunFact(FunFacts.forLetter(widget.letter.letter)));
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Color(widget.letter.colorValue);
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        _LetterBadge(letter: widget.letter.letter, color: color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                widget.letter.label,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              EmojiPicture(
                                emoji: widget.letter.emoji,
                                color: color,
                                fontSize: 54,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 30),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _replaySound,
                      icon: const Icon(Icons.volume_up_rounded, size: 26),
                      label: const Text('Hear again'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Text(
                          'Trace it!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                        const Spacer(),
                        if (_traced)
                          const Row(
                            children: <Widget>[
                              Icon(
                                Icons.star_rounded,
                                color: AppColors.gold,
                                size: 26,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Traced!',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 210,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TracingCanvas(
                        label: widget.letter.letter,
                        color: color,
                        onCompleted: _onTraceCompleted,
                        onReset: () => setState(() => _traced = false),
                      ),
                    ),
                    const SizedBox(height: 26),
                    FunFactBubble(
                      fact: FunFacts.forLetter(widget.letter.letter),
                      onHearFact: _hearFact,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The big rounded letter tile in the sheet header.
class _LetterBadge extends StatelessWidget {
  const _LetterBadge({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[color, Color.lerp(color, Colors.white, 0.25)!],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 46,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
