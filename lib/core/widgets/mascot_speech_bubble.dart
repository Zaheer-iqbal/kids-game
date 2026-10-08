import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The little speech bubble above/beside the mascot.
///
/// Uses a [ValueKey] on the message so [AnimatedSwitcher] cross-fades between
/// two different lines instead of morphing one into the other.
class MascotSpeechBubble extends StatelessWidget {
  const MascotSpeechBubble({
    super.key,
    required this.message,
    this.maxWidth = 230,
  });

  final String message;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.7, end: 1).animate(animation),
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<String>(message),
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xDDEFDFCF), width: 2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
