import 'package:flutter/widgets.dart';

/// Shared responsive breakpoints and helpers.
///
/// Screens size themselves from the space they actually have (via
/// [MediaQuery] / [LayoutBuilder] / these helpers) instead of hard-coded
/// pixels, so nothing ever overflows a 320px phone, a tablet or a landscape
/// window. The values are deliberately conservative: the app must stay usable
/// on the smallest supported phone (320x568) with the largest supported text
/// scale (1.6x).
abstract final class Responsive {
  /// Below this width the smallest phone layouts kick in.
  static const double smallPhoneWidth = 360;

  /// Tablets and up get a centred, width-capped content column.
  static const double tabletWidth = 600;

  /// Large web/desktop windows are treated like a tablet column.
  static const double desktopWidth = 900;

  /// Widest a reading/working column is allowed to grow before it is centred.
  static const double maxContentWidth = 680;

  static Size size(BuildContext context) => MediaQuery.sizeOf(context);

  static double width(BuildContext context) => size(context).width;

  static double height(BuildContext context) => size(context).height;

  static bool isSmallPhone(BuildContext context) =>
      width(context) < smallPhoneWidth;

  static bool isTablet(BuildContext context) => width(context) >= tabletWidth;

  static bool isDesktop(BuildContext context) => width(context) >= desktopWidth;

  /// True when the window is wider than it is tall.
  static bool isLandscape(BuildContext context) {
    final Size s = size(context);
    return s.width > s.height;
  }

  /// Short windows (landscape phones) need vertically compact layouts.
  static bool isShort(BuildContext context) => height(context) < 620;

  /// Standard horizontal screen gutter, scaled by device class.
  static double gutter(BuildContext context) {
    final double w = width(context);
    if (w < smallPhoneWidth) return 12;
    if (w >= tabletWidth) return 32;
    return 20;
  }

  /// How many grid columns of at least [targetWidth] fit in the available
  /// width, clamped between [min] and [max].
  static int columnsFor(
    BoxConstraints constraints, {
    required double targetWidth,
    double spacing = 12,
    int min = 2,
    int max = 6,
  }) {
    final double available = constraints.maxWidth;
    if (!available.isFinite || available <= 0) return min;
    final int count = ((available + spacing) / (targetWidth + spacing)).floor();
    return count.clamp(min, max);
  }

  /// A size that is a fraction of the *shortest* window side, clamped between
  /// [min] and [max]. Used for emoji, tiles and the mascot.
  static double shortestSideFraction(
    BuildContext context, {
    required double fraction,
    double min = 16,
    double max = 200,
  }) {
    final double shortest = size(context).shortestSide;
    return (shortest * fraction).clamp(min, max).toDouble();
  }
}

/// Centres its child and caps its width on tablet/desktop so text and cards
/// never stretch across a whole monitor.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxContentWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
