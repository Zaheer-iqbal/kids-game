import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'delight_settings.dart';

/// One-shot staggered entrance: fades, slides and scales a child in when it
/// first appears, delayed by `index` so grids and lists cascade.
///
/// When the kid turns animations off in settings the widget renders fully
/// visible immediately (no waiting on a timer).
class StaggerEntrance extends StatefulWidget {
  const StaggerEntrance({
    super.key,
    required this.index,
    required this.child,
    this.from = const Offset(0, 0.25),
    this.scaleFrom = 0.92,
  });

  final int index;
  final Widget child;
  final Offset from;
  final double scaleFrom;

  @override
  State<StaggerEntrance> createState() => _StaggerEntranceState();
}

class _StaggerEntranceState extends State<StaggerEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppTokens.entranceDuration,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeInCubic,
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!DelightSettings.of(context).animationsEnabled) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(AppTokens.staggerStep * widget.index, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (BuildContext context, Widget? child) {
          final double t = _curve.value;
          return Transform.translate(
            offset: Offset.lerp(
              Offset(widget.from.dx * 40, widget.from.dy * 40),
              Offset.zero,
              t,
            )!,
            child: Transform.scale(
              scale: widget.scaleFrom + (1 - widget.scaleFrom) * t,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Wraps a list of children and staggers them by their position.
class StaggeredList extends StatelessWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.spacing = AppTokens.space4,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.scrollDirection = Axis.vertical,
  });

  final List<Widget> children;
  final double spacing;
  final EdgeInsets? padding;
  final CrossAxisAlignment crossAxisAlignment;
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(
          scrollDirection == Axis.vertical
              ? SizedBox(height: spacing)
              : SizedBox(width: spacing),
        );
      }
      items.add(StaggerEntrance(index: i, child: children[i]));
    }

    if (scrollDirection == Axis.vertical) {
      return ListView(
        padding: padding,
        scrollDirection: scrollDirection,
        children: items,
      );
    }
    return SingleChildScrollView(
      scrollDirection: scrollDirection,
      padding: padding,
      child: IntrinsicWidth(
        child: Column(crossAxisAlignment: crossAxisAlignment, children: items),
      ),
    );
  }
}
