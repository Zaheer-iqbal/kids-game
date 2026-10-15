import 'dart:async';

import 'package:flutter/material.dart';

import '../mascot/mascot_mood.dart';
import 'delight_settings.dart';
import 'mascot_painter.dart';
import 'mascot_speech_bubble.dart';

/// Speech-bubble placement relative to the owl.
enum MascotBubbleLayout {
  /// Bubble sits on top of the owl — for centred spots like the celebration
  /// overlay.
  above,

  /// Bubble sits to the left of the owl — for a mascot pinned to the right edge
  /// of the screen.
  leading,
}

/// The app mascot, drawn entirely in code (no image assets).
///
/// Animation rules, on purpose:
/// * exactly **one** [AnimationController] per widget (a
///   [SingleTickerProviderStateMixin]), disposed in [dispose], which is what
///   keeps the "a ticker was started but never stopped" error away even with
///   dozens of cards on screen;
/// * the owl is a single [CustomPaint] whose painter listens to that controller
///   directly, so an animation frame repaints one layer and never rebuilds a
///   widget;
/// * a [RepaintBoundary] keeps the mascot's own repaints off its neighbours.
///
/// The controller is a time source, not a state machine: it repeats slowly for
/// the idle breathing/blinking loop and runs once for a reaction. When
/// animations are switched off in the parent settings screen the controller is
/// parked and the owl simply holds a still, friendly pose.
///
/// A finished reaction fires [onSettle], which is how the mascot returns to
/// idle. Deriving that from the animation instead of a `Timer` matters: a timer
/// would outlive the widget, and a pending timer fails every widget test that
/// ends while the mascot is still talking.
class MascotWidget extends StatefulWidget {
  const MascotWidget({
    super.key,
    required this.mood,
    this.size = 120,
    this.message,
    this.reactionToken = 0,
    this.giggleToken = 0,
    this.talking = false,
    this.palette = MascotPalette.owl,
    this.bubbleLayout = MascotBubbleLayout.above,
    this.bubbleMaxWidth = 230,
    this.onTap,
    this.onSettle,
  });

  final MascotMood mood;

  /// Width and height of the drawn owl in logical pixels.
  final double size;

  /// Line for the speech bubble; `null` hides it.
  final String? message;

  /// Changing this value replays the reaction, even when the mood is the same
  /// one the owl is already showing (tapping two letters in a row).
  final int reactionToken;

  /// Changing this value plays a giggle wiggle without changing the mood.
  final int giggleToken;

  /// When true the owl flaps its beak and wings as if speaking. Purely visual:
  /// the caller decides when the sound starts and stops.
  final bool talking;

  final MascotPalette palette;
  final MascotBubbleLayout bubbleLayout;
  final double bubbleMaxWidth;

  /// Tapping the owl (giggle) — usually wired to `MascotCubit.giggle()`.
  final VoidCallback? onTap;

  /// Fired once a reaction or giggle has played out — usually wired to
  /// `MascotCubit.idle()`. Left null, the owl just goes back to breathing.
  final VoidCallback? onSettle;

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget>
    with SingleTickerProviderStateMixin {
  static const Duration _reactionDuration = Duration(milliseconds: 2000);
  static const Duration _giggleDuration = Duration(milliseconds: 900);

  /// A still, pleasant pose used when animations are off.
  static const double _staticPose = 0.3;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _reactionDuration,
  )..addStatusListener(_handleStatus);

  bool _reacting = false;
  bool _giggling = false;
  bool _animationsEnabled = true;

  /// Only used when animations are off, where no controller runs to drive the
  /// return to idle. Cancelled in [dispose] so it can never outlive the owl.
  Timer? _settleTimer;

  /// Set once the owl has decided how to enter: breathing, or finishing a
  /// reaction that was already showing.
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool enabled = DelightSettings.of(context).animationsEnabled;
    if (enabled != _animationsEnabled) {
      _animationsEnabled = enabled;
      _applyAnimationPreference();
    }
    if (!_started) {
      _started = true;
      if (widget.mood != MascotMood.idle) {
        // Mounted while a reaction was still showing (route popped and opened
        // again, for example): finish it so the owl settles instead of freezing
        // mid-pose. No notify needed — this runs before the first build.
        _playReaction(notify: false);
      }
    }
  }

  @override
  void didUpdateWidget(MascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.giggleToken != widget.giggleToken) {
      _playGiggle();
    } else if (oldWidget.reactionToken != widget.reactionToken) {
      if (widget.mood == MascotMood.idle) {
        _startIdle();
      } else {
        _playReaction();
      }
    } else if (oldWidget.mood != widget.mood) {
      if (widget.mood == MascotMood.idle) {
        _startIdle();
      } else {
        _playReaction();
      }
    }
  }

  void _applyAnimationPreference() {
    _settleTimer?.cancel();
    _settleTimer = null;
    if (_animationsEnabled) {
      if (_reacting) {
        _controller.forward(from: 0);
      } else if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _reacting = false;
      _giggling = false;
      _controller
        ..stop()
        ..value = _staticPose;
    }
  }

  void _startIdle({bool notify = true}) {
    _settleTimer?.cancel();
    _settleTimer = null;
    void clearFlags() {
      _reacting = false;
      _giggling = false;
    }

    if (notify && mounted) {
      setState(clearFlags);
    } else {
      clearFlags();
    }
    if (_animationsEnabled) {
      _controller.repeat();
    }
  }

  void _playReaction({bool notify = true}) {
    _settleTimer?.cancel();
    _settleTimer = null;
    if (!_animationsEnabled) {
      // Still pose, but the bubble must not stick around forever.
      _settleLater();
      return;
    }
    void setFlags() {
      _reacting = true;
      _giggling = false;
    }

    if (notify && mounted) {
      setState(setFlags);
    } else {
      setFlags();
    }
    _controller
      ..duration = _reactionDuration
      ..forward(from: 0);
  }

  void _playGiggle() {
    _settleTimer?.cancel();
    _settleTimer = null;
    if (!_animationsEnabled) {
      _settleLater();
      return;
    }
    if (mounted) {
      setState(() {
        _giggling = true;
        _reacting = false;
      });
    }
    _controller
      ..duration = _giggleDuration
      ..forward(from: 0);
  }

  /// Fallback for the animations-off path, where no controller ticks to tell us
  /// the reaction is over.
  void _settleLater() {
    final VoidCallback? onSettle = widget.onSettle;
    if (onSettle == null) return;
    _settleTimer = Timer(
      widget.mood == MascotMood.idle ? _giggleDuration : _reactionDuration,
      onSettle,
    );
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    // Only a one-shot reaction is worth settling; the breathing loop also ends
    // a cycle at 1.0, and that must not count as "the owl finished reacting".
    final bool wasOneShot = _reacting || _giggling;
    if (mounted) {
      setState(() {
        _reacting = false;
        _giggling = false;
      });
    }
    if (_animationsEnabled) {
      // Back to the gentle breathing loop with the mood's resting face.
      _controller.repeat();
    }
    if (wasOneShot) widget.onSettle?.call();
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget owl = RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Semantics(
          button: widget.onTap != null,
          label: 'Pip the owl mascot. Tap to make it giggle.',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: CustomPaint(
              painter: MascotPainter(
                animation: _controller,
                mood: widget.mood,
                reacting: _reacting,
                giggling: _giggling,
                talking: widget.talking,
                palette: widget.palette,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    final String? message = widget.message;
    if (message == null || message.isEmpty) {
      return owl;
    }

    final Widget bubble = MascotSpeechBubble(
      message: message,
      maxWidth: widget.bubbleMaxWidth,
    );

    return switch (widget.bubbleLayout) {
      MascotBubbleLayout.above => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            bubble,
            const SizedBox(height: 6),
            owl,
          ],
        ),
      MascotBubbleLayout.leading => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Flexible(child: bubble),
            const SizedBox(width: 8),
            owl,
          ],
        ),
    };
  }
}
