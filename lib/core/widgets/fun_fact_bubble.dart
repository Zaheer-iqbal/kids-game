import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A speech-bubble style card showing a kid-friendly fun fact, with a button
/// to hear it read aloud.
class FunFactBubble extends StatelessWidget {
  const FunFactBubble({
    super.key,
    required this.fact,
    required this.onHearFact,
    this.accentColor,
  });

  final String fact;
  final VoidCallback onHearFact;

  /// Optional accent color for the bubble border and icon tint.
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = accentColor ?? AppColors.gold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // ── Header row ────────────────────────────────────────────────
        Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lightbulb_rounded, color: accent, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Fun Fact!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Bubble card ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white,
                accent.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
            border: Border.all(
              color: accent.withValues(alpha: 0.30),
              width: 1.5,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            fact,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Hear button ───────────────────────────────────────────────
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onHearFact,
            style: FilledButton.styleFrom(
              backgroundColor: accent.withValues(alpha: 0.14),
              foregroundColor: accent,
              elevation: 0,
              textStyle: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            icon: const Icon(Icons.volume_up_rounded, size: 22),
            label: const Text('Hear fun fact'),
          ),
        ),
      ],
    );
  }
}