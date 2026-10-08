import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import 'delight_settings.dart';

/// The app-wide button: a chunky "3D pill" that visibly presses down on tap
/// (the face translates into its own shadow and the shadow shrinks), then
/// springs back. Every primary action in the game uses this, so taps feel
/// identical everywhere.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color = AppColors.primary,
    this.filled = true,
    this.size = GameButtonSize.medium,
    this.expand = false,
    this.haptic = true,
  });

  /// Big CTA (level start, "Next", "Play").
  const GameButton.large({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color = AppColors.primary,
    this.filled = true,
    this.expand = true,
    this.haptic = true,
  }) : size = GameButtonSize.large;

  /// Compact pill for secondary rows.
  const GameButton.small({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color = AppColors.primary,
    this.filled = true,
    this.expand = false,
    this.haptic = true,
  }) : size = GameButtonSize.small;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  /// Filled = solid colored face. Unfilled = white face with a colored rim.
  final bool filled;
  final GameButtonSize size;
  final bool expand;
  final bool haptic;

  @override
  State<GameButton> createState() => _GameButtonState();
}

enum GameButtonSize { small, medium, large }

class _GameButtonState extends State<GameButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppTokens.pressDuration,
    value: 0,
  );

  bool get _animate => DelightSettings.of(context).animationsEnabled;

  void _handleTapDown(TapDownDetails _) {
    if (!_animate) return;
    _controller.forward();
  }

  void _handleTapEnd() {
    if (!_animate) return;
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.haptic) {
      HapticFeedback.lightImpact().catchError((Object _) {});
    }
    widget.onPressed?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double depth = switch (widget.size) {
      GameButtonSize.small => 6,
      GameButtonSize.medium => AppTokens.buttonDepth,
      GameButtonSize.large => 10,
    };
    final double height = switch (widget.size) {
      GameButtonSize.small => 48,
      GameButtonSize.medium => AppTokens.buttonHeight,
      GameButtonSize.large => 72,
    };
    final double fontSize = switch (widget.size) {
      GameButtonSize.small => 16,
      GameButtonSize.medium => 20,
      GameButtonSize.large => 24,
    };

    final Color face = widget.filled ? widget.color : Colors.white;
    final Color content = widget.filled ? Colors.white : widget.color;

    final Widget button = Semantics(
      button: true,
      label: widget.label,
      enabled: widget.onPressed != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: (_) => _handleTapEnd(),
        onTapCancel: _handleTapEnd,
        onTap: widget.onPressed == null ? null : _handleTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            // The face slides into its shadow as the shadow compresses.
            final double press = _controller.value;
            return Transform.translate(
              offset: Offset(0, depth * press),
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: face,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  border: widget.filled
                      ? null
                      : Border.all(color: widget.color, width: 2.5),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: widget.color.withValues(
                        alpha: widget.filled ? 1 : 0.35,
                      ),
                      blurRadius: 0,
                      offset: Offset(0, depth * (1 - press)),
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.size == GameButtonSize.small
                  ? AppTokens.space4
                  : AppTokens.space6,
            ),
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (widget.icon != null) ...<Widget>[
                  Icon(widget.icon, color: content, size: fontSize + 8),
                  const SizedBox(width: AppTokens.space2),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      fontVariations: const <FontVariation>[
                        FontVariation('wght', 700),
                      ],
                      color: content,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
