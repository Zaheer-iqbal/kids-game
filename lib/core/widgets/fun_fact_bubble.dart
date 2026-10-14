import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A speech-bubble style card showing a kid-friendly fun fact, with a button
/// to hear it read aloud.
class FunFactBubble extends StatelessWidget {
  const FunFactBubble({
    super.key,
    required this.fact,
    required this.onHearFact,
  });

  final String fact;
  final VoidCallback onHearFact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.lightbulb_rounded, color: AppColors.gold, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Fun fact!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    theme.textTheme.titleLarge?.copyWith(color: AppColors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(8),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            fact,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: onHearFact,
            icon: const Icon(Icons.volume_up_rounded, size: 22),
            label: const Text('Hear fun fact'),
          ),
        ),
      ],
    );
  }
}