import 'package:flutter/material.dart';

/// One place for every shape, spacing, motion and elevation constant the app
/// uses, so screens never invent their own numbers.
///
/// Spacing follows an 8pt grid (4pt allowed for tight icon nudges), corners
/// are big and soft (24-32) and buttons carry a thick "3D pill" bottom shadow
/// that shrinks when pressed.
abstract final class AppTokens {
  // ---------------------------------------------------------------- spacing
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;
  static const double space7 = 40;
  static const double space8 = 48;

  /// Screen gutter used by every page.
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: space4);

  // ----------------------------------------------------------------- shapes
  static const double radiusSmall = 16;
  static const double radiusMedium = 24;
  static const double radiusLarge = 28;
  static const double radiusXL = 32;
  static const double radiusPill = 999;

  static BorderRadius cardRadius = BorderRadius.circular(radiusLarge);
  static BorderRadius sheetRadius =
      const BorderRadius.vertical(top: Radius.circular(radiusXL));

  // --------------------------------------------------------------- controls
  /// Minimum hit target for every tappable control (accessibility).
  static const double minTapTarget = 56;
  static const double buttonHeight = 64;
  static const double buttonDepth = 8;

  // ----------------------------------------------------------------- motion
  static const Duration pressDuration = Duration(milliseconds: 110);
  static const Duration springDuration = Duration(milliseconds: 520);
  static const Duration entranceDuration = Duration(milliseconds: 620);
  static const Duration staggerStep = Duration(milliseconds: 70);
  static const Duration screenFade = Duration(milliseconds: 340);

  static const Curve springOut = Curves.easeOutBack;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve easeOutCubic = Curves.easeOutCubic;

  // ------------------------------------------------------------- elevation
  static List<BoxShadow> softShadow({double blur = 16, double dy = 6}) {
    return <BoxShadow>[
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.16),
        blurRadius: blur,
        offset: Offset(0, dy),
      ),
    ];
  }

  /// The thick, saturated shadow under a 3D pill button.
  static List<BoxShadow> pillShadow(Color color, {double depth = buttonDepth}) {
    return <BoxShadow>[
      BoxShadow(
        color: color,
        blurRadius: 0,
        offset: Offset(0, depth),
      ),
    ];
  }
}
