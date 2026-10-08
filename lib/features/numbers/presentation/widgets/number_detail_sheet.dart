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
import '../../domain/entities/number_entity.dart';
import 'count_objects.dart';

/// Bottom sheet shown when a number card is tapped: the big numeral, the
/// objects being counted, a replay button, a tracing canvas for the digits and
/// the number's fun fact (which can be read aloud).
class NumberDetailSheet extends StatefulWidget {
  const NumberDetailSheet({super.key, required this.number});

  final NumberEntity number;

  static Future<void> show(BuildContext context, NumberEntity number) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black38,
      builder: (BuildContext sheetContext) => FractionallySizedBox(
        alignment: Alignment.bottomCenter,
        heightFactor: 0.86,
        child: NumberDetailSheet(number: number),
      ),
    );
  }

  @override
  State<NumberDetailSheet> createState() => _NumberDetailSheetState();
}

class _NumberDetailSheetState extends State<NumberDetailSheet> {
  bool _traced = false;

  void _replaySound() {
    unawaited(di.sl<AudioService>().speakNumber(widget.number.word));
  }

  void _onTraceCompleted() {
    setState(() => _traced = true);
    di.sl<MascotCubit>().excited(speak: true, message: 'Great job!');
    unawaited(showCelebrationOverlay(context, message: 'Great job!'));
  }

  void _hearFact() {
    final String? fact = FunFacts.forNumber(widget.number.number);
    if (fact != null) {
      unawaited(di.sl<AudioService>().speakFunFact(fact));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Color(widget.number.colorValue);
    final ThemeData theme = Theme.of(context);
    final String? fact = FunFacts.forNumber(widget.number.number);

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
                        _NumeralBadge(number: widget.number.number, color: color),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                widget.number.label,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              EmojiPicture(
                                emoji: widget.number.emoji,
                                color: color,
                                fontSize: 44,
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
                    Text(
                      'Count them!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                      child: CountObjects(
                        count: widget.number.number,
                        emoji: widget.number.emoji,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: <Widget>[
                        Text(
                          'Trace the number!',
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
                        label: '${widget.number.number}',
                        color: color,
                        onCompleted: _onTraceCompleted,
                        onReset: () => setState(() => _traced = false),
                      ),
                    ),
                    if (fact != null) ...<Widget>[
                      const SizedBox(height: 26),
                      FunFactBubble(fact: fact, onHearFact: _hearFact),
                    ],
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

/// The big rounded numeral tile in the sheet header.
class _NumeralBadge extends StatelessWidget {
  const _NumeralBadge({required this.number, required this.color});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
