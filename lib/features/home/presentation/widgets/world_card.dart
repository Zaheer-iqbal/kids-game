import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../domain/adventure_world.dart';
import 'level_node.dart';

/// Outcome shown for one level on the map.
class LevelState {
  const LevelState({required this.stars, required this.locked});

  final int stars;
  final bool locked;
}

/// One world: a gradient banner (tap to open the explorer) with its levels
/// strung along a winding dashed path below it.
class WorldCard extends StatelessWidget {
  const WorldCard({
    super.key,
    required this.world,
    required this.progressLabel,
    required this.levels,
    required this.onOpenWorld,
    required this.onLevelTap,
    this.rowHeight = 96,
  });

  final AdventureWorld world;
  final String progressLabel;

  /// One entry per level, in map order.
  final List<LevelState> levels;
  final VoidCallback onOpenWorld;
  final ValueChanged<int> onLevelTap;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int firstOpen = levels.indexWhere((LevelState level) => !level.locked);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[world.color, world.colorEnd],
        ),
        borderRadius: BorderRadius.circular(AppTokens.radiusXL),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: world.color.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ------------------------------------------------------ banner
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenWorld,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 62,
                      height: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 2),
                      ),
                      child: Text(world.emoji, style: const TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            world.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            progressLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: world.color,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // -------------------------------------------------- level path
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = constraints.maxWidth;
              final double height = levels.length * rowHeight + 16;
              final List<Offset> points = List<Offset>.generate(
                levels.length,
                (int i) {
                  final double xT = 0.5 + 0.26 * math.sin(i * math.pi / 2);
                  return Offset(
                    (width * xT).clamp(52.0, width - 52.0),
                    16 + i * rowHeight + rowHeight / 2 - 8,
                  );
                },
              );

              return SizedBox(
                height: height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _MapPathPainter(points),
                        ),
                      ),
                    ),
                    for (int i = 0; i < levels.length; i++)
                      Positioned(
                        left: points[i].dx - 44,
                        top: points[i].dy - 44,
                        child: LevelNode(
                          key: ValueKey<String>(
                            '${world.id.storageKey}-level-$i',
                          ),
                          level: i + 1,
                          color: world.color,
                          stars: levels[i].stars,
                          locked: levels[i].locked,
                          isCurrent: i == firstOpen,
                          onTap: () => onLevelTap(i),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

/// Dashed winding line connecting the level nodes, drawn in code.
class _MapPathPainter extends CustomPainter {
  const _MapPathPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final Offset previous = points[i - 1];
      final Offset current = points[i];
      final double midY = (previous.dy + current.dy) / 2;
      path.cubicTo(
        previous.dx,
        midY,
        current.dx,
        midY,
        current.dx,
        current.dy,
      );
    }

    final Paint shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, shadow);

    final Paint dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + 14),
          dash,
        );
        distance += 26;
      }
    }
  }

  @override
  bool shouldRepaint(_MapPathPainter oldDelegate) =>
      oldDelegate.points.length != points.length ||
      !_samePoints(oldDelegate.points, points);

  bool _samePoints(List<Offset> a, List<Offset> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Small white pill used on the map for totals (stars, best scores).
class MapStatPill extends StatelessWidget {
  const MapStatPill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.gold),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
