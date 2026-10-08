import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'delight_settings.dart';
import 'sparkle_burst.dart';

/// Adds a small pop, a slight random tilt and an occasional sparkle burst to
/// any tap target — used by the letter and number cards.
///
/// Performance notes:
/// * one [AnimationController] per card, created lazily and disposed with the
///   card, and it only ticks for ~half a second after a tap;
/// * the pop and tilt are applied with [Transform]s around a `child` that is
///   built once, so an animation frame never rebuilds the card subtree;
/// * the whole thing sits in a [RepaintBoundary] so a burst repaints one layer
///   instead of the surrounding grid.
class TapDelight extends StatefulWidget {
  const TapDelight({
    super.key,
    required this.onTap,
    required this.child,
    this.sparkleChance = 0.2,
    this.random,
  });

  final VoidCallback onTap;
  final Widget child;

  /// Probability that a tap also fires a sparkle burst (about 1 in 5).
  final double sparkleChance;

  /// Injectable for deterministic tests; a fresh [math.Random] is used when
  /// null.
  final math.Random? random;

  @override
  State<TapDelight> createState() => _TapDelightState();
}

class _TapDelightState extends State<TapDelight>
    with SingleTickerProviderStateMixin {
  static const Duration _popDuration = Duration(milliseconds: 520);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _popDuration,
  );

  late final math.Random _random = widget.random ?? math.Random();

  /// Overshoot then settle: quick and springy, like a toy being pressed.
  late final Animation<double> _pop = TweenSequence<double>(<TweenSequenceItem<double>>[
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 1, end: 1.16)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 1.16, end: 0.94)
          .chain(CurveTween(curve: Curves.easeInOut)),
      weight: 25,
    ),
    TweenSequenceItem<double>(
      tween: Tween<double>(begin: 0.94, end: 1)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 45,
    ),
  ]).animate(_controller);

  /// Signed radians for this tap; refreshed on every tap so cards do not all
  /// lean the same way.
  double _tilt = 0;

  int _sparkleSeed = 0;
  bool _sparkleVisible = false;
  bool _pressed = false;

  bool get _animationsEnabled => DelightSettings.of(context).animationsEnabled;

  void _handleTap() {
    final bool animate = _animationsEnabled;
    if (animate) {
      _tilt = (_random.nextBool() ? 1 : -1) *
          (0.05 + _random.nextDouble() * 0.05);
      _controller.forward(from: 0);
      final bool sparkle = DelightSettings.of(context).sparklesEnabled &&
          _random.nextDouble() < widget.sparkleChance;
      if (sparkle) {
        // A new seed replays the burst, so a card can sparkle on every lucky
        // tap instead of only the first time it is pressed.
        setState(() {
          _sparkleVisible = true;
          _sparkleSeed++;
        });
      }
    }
    widget.onTap();
  }

  /// Lean out, snap back, straighten — a quick playful wobble.
  double _tiltAt(double t) {
    if (t <= 0) return 0;
    if (t < 0.3) return _tilt * (t / 0.3);
    if (t < 0.6) return _tilt * (1 - 2 * (t - 0.3) / 0.3);
    if (t < 0.8) return -_tilt * 0.35 * (1 - (t - 0.6) / 0.2);
    return 0;
  }

  void _setPressed(bool value) {
    if (!_animationsEnabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget card = widget.child;

    if (_sparkleVisible) {
      card = Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          card,
          Positioned.fill(
            child: SparkleBurst(seed: _sparkleSeed),
          ),
        ],
      );
    }

    Widget result = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pop,
        child: card,
        builder: (BuildContext context, Widget? child) {
          return Transform.rotate(
            angle: _tiltAt(_controller.value),
            alignment: Alignment.bottomCenter,
            child: Transform.scale(scale: _pop.value, child: child),
          );
        },
      ),
    );

    if (_animationsEnabled) {
      result = AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: result,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _handleTap,
      child: result,
    );
  }
}
