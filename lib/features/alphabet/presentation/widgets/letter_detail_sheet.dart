import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/router/app_router.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/services/fun_facts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/emoji_picture.dart';
import '../../../../core/widgets/fun_fact_bubble.dart';
import '../../domain/entities/letter_item.dart';

/// Full-screen modal shown when a letter card is tapped.
/// Shows the big letter + animal picture, phonics replay, a fun-fact bubble,
/// and a pinned "Trace it!" button at the very bottom.
class LetterDetailSheet extends StatefulWidget {
  const LetterDetailSheet({super.key, required this.letter});

  final LetterItem letter;

  static Future<void> show(BuildContext context, LetterItem letter) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (BuildContext sheetContext) => LetterDetailSheet(letter: letter),
    );
  }

  @override
  State<LetterDetailSheet> createState() => _LetterDetailSheetState();
}

class _LetterDetailSheetState extends State<LetterDetailSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _scaleAnim = CurvedAnimation(
    parent: _animCtrl,
    curve: Curves.elasticOut,
  );

  @override
  void initState() {
    super.initState();
    _animCtrl.forward();
    // Auto-play phonics when sheet opens
    unawaited(di.sl<AudioService>()
        .speakPhonics(widget.letter.letter, widget.letter.word));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _replaySound() {
    unawaited(di.sl<AudioService>()
        .speakPhonics(widget.letter.letter, widget.letter.word));
  }

  void _hearFact() {
    unawaited(di.sl<AudioService>()
        .speakFunFact(FunFacts.forLetter(widget.letter.letter)));
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Color(widget.letter.colorValue);
    final ThemeData theme = Theme.of(context);
    final String fact = FunFacts.forLetter(widget.letter.letter);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: <Widget>[
          // ── drag handle ────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          // ── header: badge + label + close ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // animated letter badge
                ScaleTransition(
                  scale: _scaleAnim,
                  child: _LetterBadge(letter: widget.letter.letter, color: color),
                ),
                const SizedBox(width: 16),
                // label + large emoji
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.letter.label,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Large animal / object emoji shown prominently
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: EmojiPicture(
                          emoji: widget.letter.emoji,
                          color: color,
                          fontSize: 72,
                        ),
                      ),
                    ],
                  ),
                ),
                // close button
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 30),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // ── scrollable body ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Hear Again
                  FilledButton.icon(
                    onPressed: _replaySound,
                    style: FilledButton.styleFrom(
                      backgroundColor: color.withValues(alpha: 0.18),
                      foregroundColor: color,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(54),
                      textStyle: const TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.volume_up_rounded, size: 26),
                    label: const Text('Hear it again'),
                  ),

                  const SizedBox(height: 20),

                  // Fun Fact bubble
                  FunFactBubble(
                    fact: fact,
                    onHearFact: _hearFact,
                    accentColor: color,
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // ── pinned Trace It button at the very bottom ──────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.letterTrace(widget.letter.letter));
              },
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(62),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.gesture_rounded, size: 30),
              label: const Text('Trace it!'),
            ),
          ),
        ],
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
      width: 86,
      height: 86,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[color, Color.lerp(color, Colors.white, 0.3)!],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 52,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
