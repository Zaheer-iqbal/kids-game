import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A single stop on a world's winding path: a chunky circle with the level
/// number (or a lock), a press animation and up to three stars underneath.
class LevelNode extends StatefulWidget {
  const LevelNode({
    super.key,
    required this.level,
    required this.color,
    required this.stars,
    required this.locked,
    required this.onTap,
    required this.isCurrent,
  });

  final int level;

  /// Face color of an unlocked, not-yet-completed level.
  final Color color;

  /// Stars already earned (0-3).
  final int stars;
  final bool locked;
  final VoidCallback? onTap;

  /// The next level to play - it gently bobs to invite a tap.
  final bool isCurrent;

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isCurrent && !widget.locked) {
      _bob.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !widget.locked) {
      if (!_bob.isAnimating) _bob.repeat(reverse: true);
    } else if (_bob.isAnimating) {
      _bob.stop();
      _bob.value = 0;
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool done = widget.stars > 0;
    final Color face = widget.locked
        ? const Color(0xFFE2E8F0)
        : done
            ? AppColors.gold
            : widget.color;
    final Color ink = widget.locked
        ? const Color(0xFF94A3B8)
        : done
            ? const Color(0xFF7C2D12)
            : Colors.white;

    return Semantics(
      button: true,
      label: widget.locked ? 'Level ${widget.level}, locked' : 'Level ${widget.level}',
      child: GestureDetector(
        onTap: widget.locked ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: _bob,
          builder: (BuildContext context, Widget? child) {
            return Transform.translate(
              offset: Offset(0, -4 * _bob.value),
              child: child,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: face,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: widget.locked
                    ? Icon(Icons.lock_rounded, color: ink, size: 28)
                    : Text(
                        '${widget.level}',
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          fontVariations: const <FontVariation>[
                            FontVariation('wght', 700),
                          ],
                          color: ink,
                          height: 1,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List<Widget>.generate(3, (int i) {
                  return Icon(
                    i < widget.stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 15,
                    color: i < widget.stars
                        ? AppColors.gold
                        : Colors.white.withValues(alpha: 0.7),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
