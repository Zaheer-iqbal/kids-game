import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/delight_settings.dart';

/// The app's whole motion vocabulary.
///
/// This file is the **only** place that hand-rolls animation curves. Every
/// screen asks for one of these named styles instead of building its own
/// `AnimationController`, which keeps the feel consistent (and the tests
/// predictable) across the app.
///
/// The names match the classic `flutter_easy_animations` vocabulary
/// (`fadeInUp`, `bounceIn`, `tada`, `jello`, `headShake`, `pulse`,
/// `heartBeat`, `wobble`, `zoomIn`, `zoomOut`, `rubberBand`).
///
/// ### Why an in-house helper?
/// `flutter_easy_animations` 1.0.0 needs Flutter 3.47 / Dart 3.13 and this
/// project is pinned to an older toolchain. Rather than force an SDK upgrade
/// the same effect names are implemented here with a plain
/// `AnimationController` + `Transform`, so a later swap to the package is a
/// one-file change.
enum MotionStyle {
  /// Slides up while fading in. The default entrance.
  fadeInUp,

  /// Scales in with a playful overshoot. Stars, badges, first paint.
  bounceIn,

  /// A quick celebratory "ta-da" wiggle. Correct answers, solved puzzles.
  tada,

  /// A soft jelly wobble, warmer and looser than [tada].
  jello,

  /// A short, soft horizontal head-shake. Gentle wrong-answer feedback.
  headShake,

  /// A slow, friendly breathing scale, looping. Draws the eye without noise.
  pulse,

  /// A doubled "lub-dub" scale, looping. The streak flame.
  heartBeat,

  /// A light damped wobble. Locked tiles and unavailable levels.
  wobble,

  /// Pops in from small. Dialogs and result cards.
  zoomIn,

  /// Settles in from slightly large. Dialogs and result cards.
  zoomOut,

  /// A squash-and-stretch rubber band. The logo's eyes.
  rubberBand;

  /// Whether this style is meant to run forever (attention / ambience).
  bool get repeats =>
      this == MotionStyle.pulse || this == MotionStyle.heartBeat;

  /// A sensible one-shot length. Repeat styles loop at this cadence.
  Duration get duration => switch (this) {
        MotionStyle.fadeInUp => const Duration(milliseconds: 520),
        MotionStyle.bounceIn => const Duration(milliseconds: 620),
        MotionStyle.tada => const Duration(milliseconds: 800),
        MotionStyle.jello => const Duration(milliseconds: 820),
        MotionStyle.headShake => const Duration(milliseconds: 420),
        MotionStyle.pulse => const Duration(milliseconds: 1400),
        MotionStyle.heartBeat => const Duration(milliseconds: 1400),
        MotionStyle.wobble => const Duration(milliseconds: 720),
        MotionStyle.zoomIn => const Duration(milliseconds: 300),
        MotionStyle.zoomOut => const Duration(milliseconds: 320),
        MotionStyle.rubberBand => const Duration(milliseconds: 780),
      };
}

/// The named presets every screen should reach for, grouped by intent.
///
/// Screens depend on the *intent* ("the reward star", "a gentle wrong"), never
/// on a raw style, so the whole app's feel can be retuned from this file.
abstract final class MotionPresets {
  /// List/grid items arriving on screen, staggered.
  static const MotionStyle entrance = MotionStyle.fadeInUp;

  /// Stars and badges being earned.
  static const MotionStyle rewardStar = MotionStyle.bounceIn;

  /// The daily streak flame.
  static const MotionStyle rewardStreak = MotionStyle.heartBeat;

  /// A correct answer or a solved puzzle.
  static const MotionStyle celebrate = MotionStyle.tada;

  /// A softer celebration for secondary moments.
  static const MotionStyle celebrateSoft = MotionStyle.jello;

  /// Wrong answers: soft, short, never harsh and never red.
  static const MotionStyle gentleWrong = MotionStyle.headShake;

  /// The single thing we want tapped next (Go button, current level).
  static const MotionStyle attention = MotionStyle.pulse;

  /// Locked tiles and levels.
  static const MotionStyle locked = MotionStyle.wobble;

  /// A dialog or result screen popping in.
  static const MotionStyle dialogIn = MotionStyle.zoomIn;

  /// A dialog or result screen settling away.
  static const MotionStyle dialogOut = MotionStyle.zoomOut;

  /// The logo's eyes.
  static const MotionStyle eyes = MotionStyle.rubberBand;
}

/// Applies the transform for [style] at progress [t] (0..1).
///
/// Kept as a pure top-level function so it is trivially unit-testable and so
/// every widget shares exactly one implementation.
Widget applyMotionTransform(MotionStyle style, double t, Widget child) {
  final double v = t.clamp(0.0, 1.0);
  switch (style) {
    case MotionStyle.fadeInUp:
      final double e = Curves.easeOutCubic.transform(v);
      return Opacity(
        opacity: e,
        child: Transform.translate(offset: Offset(0, 30 * (1 - e)), child: child),
      );
    case MotionStyle.bounceIn:
      final double e = Curves.easeOutBack.transform(v);
      return Opacity(
        opacity: (v * 2).clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.2 + 0.8 * e, child: child),
      );
    case MotionStyle.tada:
      final double angle = math.sin(v * math.pi * 4) * 0.07 * (1 - v);
      final double scale = 1 + 0.10 * math.sin(math.pi * v);
      return Transform.rotate(
        angle: angle,
        child: Transform.scale(scale: scale, child: child),
      );
    case MotionStyle.jello:
      final double angle = math.sin(v * math.pi * 6) * 0.12 * (1 - v);
      return Transform.rotate(angle: angle, child: child);
    case MotionStyle.headShake:
      final double dx = math.sin(v * math.pi * 4) * 9 * (1 - v);
      return Transform.translate(offset: Offset(dx, 0), child: child);
    case MotionStyle.pulse:
      final double s = 1 + 0.06 * (0.5 - 0.5 * math.cos(v * 2 * math.pi));
      return Transform.scale(scale: s, child: child);
    case MotionStyle.heartBeat:
      final double b = 0.10 * math.exp(-_sq((v - 0.12) / 0.06)) +
          0.07 * math.exp(-_sq((v - 0.32) / 0.07));
      return Transform.scale(scale: 1 + b, child: child);
    case MotionStyle.wobble:
      final double angle = math.sin(v * math.pi * 4) * 0.12 * (1 - v);
      final double dx = math.sin(v * math.pi * 4) * 5 * (1 - v);
      return Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.rotate(angle: angle, child: child),
      );
    case MotionStyle.zoomIn:
      final double e = Curves.easeOutBack.transform(v);
      return Opacity(
        opacity: v,
        child: Transform.scale(scale: 0.6 + 0.4 * e, child: child),
      );
    case MotionStyle.zoomOut:
      final double e = Curves.easeOutCubic.transform(v);
      return Opacity(
        opacity: v,
        child: Transform.scale(scale: 1.15 - 0.15 * e, child: child),
      );
    case MotionStyle.rubberBand:
      final double w = math.sin(v * math.pi * 2) * (1 - v);
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          1 + 0.28 * w,
          1 - 0.22 * w,
          1,
        ),
        child: child,
      );
  }
}

double _sq(double x) => x * x;

/// Publishes a single [AnimationController] to a whole group of children so a
/// list or grid pays for **one** ticker, not one per item.
class MotionStagger extends StatefulWidget {
  const MotionStagger({
    super.key,
    required this.child,
    this.itemCount = 8,
    this.step = const Duration(milliseconds: 70),
    this.itemDuration = const Duration(milliseconds: 560),
    this.tail = const Duration(milliseconds: 80),
  });

  final Widget child;

  /// How many staggered items the group will show; sets the total duration.
  final int itemCount;

  /// Delay between consecutive items (60-80ms keeps it lively, not slow).
  final Duration step;

  /// How long a single item's entrance takes.
  final Duration itemDuration;

  /// A little slack after the last item so it fully settles.
  final Duration tail;

  Duration get total => Duration(
        microseconds: itemDuration.inMicroseconds +
            step.inMicroseconds * (itemCount - 1).clamp(0, 1000) +
            tail.inMicroseconds,
      );

  @override
  State<MotionStagger> createState() => _MotionStaggerState();
}

class _MotionStaggerState extends State<MotionStagger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.total,
  );

  bool _started = false;
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = _motionReduced(context);
    if (_started) {
      // A settings flip mid-entrance: halt the shared ticker. The children
      // already render their reduced fallback, so this only saves frames.
      if (_reduce) _controller.stop();
      return;
    }
    _started = true;
    if (_reduce) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MotionGroupScope(
      controller: _controller,
      total: widget.total,
      step: widget.step,
      itemDuration: widget.itemDuration,
      child: widget.child,
    );
  }
}

/// Read by [AppMotion] to join the group's single controller.
class _MotionGroupScope extends InheritedWidget {
  const _MotionGroupScope({
    required this.controller,
    required this.total,
    required this.step,
    required this.itemDuration,
    required super.child,
  });

  final AnimationController controller;
  final Duration total;
  final Duration step;
  final Duration itemDuration;

  static _MotionGroupScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MotionGroupScope>();

  @override
  bool updateShouldNotify(_MotionGroupScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Wraps a single child in one named motion.
///
/// * With no ancestor [MotionStagger] it owns its own controller (one per
///   standalone element).
/// * Inside a [MotionStagger] it borrows the group's controller and only
///   claims a slice of it via [index], so a whole list runs on one ticker.
/// * When motion is reduced (parent switch or the system flag) it degrades to
///   a short fade, or nothing for looping styles.
class AppMotion extends StatefulWidget {
  const AppMotion({
    super.key,
    required this.child,
    this.style = MotionStyle.fadeInUp,
    this.index = 0,
    this.controller,
    this.duration,
    this.delay = Duration.zero,
    this.begin,
    this.end,
    this.autoStart = true,
  });

  final Widget child;
  final MotionStyle style;

  /// Position in a staggered group; ignored when [begin] is given.
  final int index;

  /// An external (shared) controller. When provided this widget never creates
  /// or disposes a ticker.
  final AnimationController? controller;

  final Duration? duration;

  /// A one-shot delay before this element starts (standalone use).
  final Duration delay;

  /// Explicit slice bounds within the driving controller, 0..1.
  final double? begin;
  final double? end;
  final bool autoStart;

  @override
  State<AppMotion> createState() => _AppMotionState();
}

class _AppMotionState extends State<AppMotion>
    with SingleTickerProviderStateMixin {
  AnimationController? _owned;
  bool _started = false;
  bool _reduce = false;

  @override
  void initState() {
    super.initState();
    // The controller is created lazily in [didChangeDependencies], because only
    // there can we see whether an ancestor [MotionStagger] will lend us its
    // controller. Creating one here would allocate a ticker per list item,
    // defeating the whole point of the shared group controller.
  }

  void _ensureOwned() {
    if (_owned != null) return;
    final Duration base = widget.duration ?? widget.style.duration;
    _owned = AnimationController(
      vsync: this,
      duration: widget.delay + base,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = _motionReduced(context);

    final _MotionGroupScope? group = _MotionGroupScope.maybeOf(context);
    // Inside a group, borrow its controller for non-repeating styles.
    final bool useGroup =
        widget.controller == null && group != null && !widget.style.repeats;
    if (!useGroup && widget.controller == null) {
      _ensureOwned();
    }

    if (_started) {
      _syncPlayback(group);
      return;
    }
    _started = true;
    if (_reduce) {
      // Pin the controller: one-shots sit on their settled frame, looping
      // styles at rest. Safe here because this widget's builder has not mounted
      // yet, so nothing is listening. Subsequent flips go through
      // [_syncPlayback], which defers for exactly this reason.
      _controllerFor(group)?.value = widget.style.repeats ? 0 : 1;
    } else if (widget.autoStart) {
      _play(group);
    }
  }

  AnimationController? _controllerFor(_MotionGroupScope? group) {
    if (widget.controller != null) return widget.controller;
    final bool useGroup =
        group != null && !widget.style.repeats;
    return useGroup ? group.controller : _owned;
  }

  void _play(_MotionGroupScope? group) {
    final AnimationController? c = _controllerFor(group);
    if (c == null) return;
    if (widget.style.repeats) {
      if (!c.isAnimating) c.repeat();
    } else {
      c.forward();
    }
  }

  void _syncPlayback(_MotionGroupScope? group) {
    final AnimationController? c = _controllerFor(group);
    if (c == null) return;
    final bool reduced = _reduce;
    final bool autoStart = widget.autoStart;
    final bool repeats = widget.style.repeats;
    // This runs from [didChangeDependencies], i.e. during the build phase.
    // Mutating the controller here would notify an already-mounted
    // AnimatedBuilder mid-build ("markNeedsBuild called during build"), so we
    // defer the change by one frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (reduced) {
        c.stop();
        c.value = repeats ? 0 : 1;
      } else if (autoStart && !c.isAnimating) {
        // Restart cleanly so a toggle back on replays from the top.
        if (repeats) {
          c.repeat();
        } else {
          c.forward(from: 0);
        }
      }
    });
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _MotionGroupScope? group = _MotionGroupScope.maybeOf(context);
    final AnimationController? controller = _controllerFor(group);

    if (controller == null) return widget.child;

    final bool useGroup = widget.controller == null &&
        group != null &&
        !widget.style.repeats;

    // Reduced motion: a short fade only (looping styles stay perfectly still).
    if (_reduce) {
      if (widget.style.repeats) return widget.child;
      return _ReducedFade(child: widget.child);
    }

    double begin = 0;
    double end = 1;
    if (widget.begin != null || widget.end != null) {
      begin = widget.begin ?? 0;
      end = widget.end ?? 1;
    } else if (useGroup) {
      final double totalUs = group.total.inMicroseconds.toDouble();
      begin = (group.step.inMicroseconds * widget.index) / totalUs;
      end = (group.step.inMicroseconds * widget.index +
              group.itemDuration.inMicroseconds) /
          totalUs;
    } else if (_owned != null && widget.delay > Duration.zero) {
      final double totalUs = _owned!.duration!.inMicroseconds.toDouble();
      begin = widget.delay.inMicroseconds / totalUs;
    }
    begin = begin.clamp(0.0, 1.0);
    end = end.clamp(begin, 1.0);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          final double raw = controller.value;
          final double t = end > begin
              ? ((raw - begin) / (end - begin)).clamp(0.0, 1.0)
              : raw;
          return applyMotionTransform(widget.style, t, child!);
        },
        child: widget.child,
      ),
    );
  }
}

/// A 200ms opacity fade used when "reduce motion" is on: no movement, no
/// scaling, just content appearing gently.
class _ReducedFade extends StatelessWidget {
  const _ReducedFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (BuildContext context, double value, Widget? child) =>
          Opacity(opacity: value, child: child),
      child: child,
    );
  }
}

/// True when motion should be reduced: the parent switch in settings or the
/// operating system's "reduce motion" accessibility flag.
bool _motionReduced(BuildContext context) {
  final DelightSettings settings = DelightSettings.of(context);
  final bool system =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return settings.reduceMotion || system || !settings.animationsEnabled;
}
