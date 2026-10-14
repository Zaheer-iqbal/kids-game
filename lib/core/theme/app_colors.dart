import 'package:flutter/material.dart';

/// The one light kids palette. Every surface is white or a warm pastel, every
/// piece of text is dark navy, and every saturated color used behind white
/// text is dark enough to clear a 4.5:1 contrast ratio.
///
/// There is no dark variant on purpose: the app is light-only, so a phone set
/// to dark mode can never flip a background to black or a caption to
/// white-on-white.
abstract final class AppColors {
  // ----------------------------------------------------------- backgrounds
  /// Sky at the top of the code-drawn landscape.
  static const Color bgTop = Color(0xFFEAF6FF);

  /// Warm cream just above the hills.
  static const Color bgBottom = Color(0xFFFFF8E7);

  /// Golden cream at the very bottom.
  static const Color bgGradientEnd = Color(0xFFFFF1D6);

  /// Solid page background used by content-heavy screens.
  static const Color background = Color(0xFFFFF8E7);

  // --------------------------------------------------------------- surfaces
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFFFFDF7);

  /// Very light neutral wash for pills, chips and inert tiles.
  static const Color surfaceSoft = Color(0xFFF3F6FB);

  // ------------------------------------------------------------------- text
  /// Primary text on light surfaces (dark navy, never pure black).
  static const Color ink = Color(0xFF26324D);

  /// Kept for historical call sites: on the light theme "bright" is the dark
  /// navy used where the old dark theme painted white text.
  static const Color inkBright = Color(0xFF26324D);

  /// Secondary text - still clears 4.5:1 on white and on every pastel.
  static const Color inkMuted = Color(0xFF46536F);

  /// Tertiary text and inactive icons.
  static const Color inkSoft = Color(0xFF5B6884);

  // ---------------------------------------------------------------- borders
  static const Color outlineSoft = Color(0xFFE2E8F0);
  static const Color cardBorder = Color(0xFFEFDFCF);

  // ---------------------------------------------------------------- accents
  /// Sky-blue primary. 5.2:1 under white text.
  static const Color primary = Color(0xFF2563EB);

  /// Deep amber used behind white text (5.0:1). For amber *text* on a light
  /// background use [goldInk].
  static const Color secondary = Color(0xFFB45309);

  /// Coral - drawn as a warm burnt orange so white text stays readable and no
  /// answer is ever marked in red.
  static const Color accentCoral = Color(0xFFC2410C);

  /// Mint green, dark enough for white text (5.0:1).
  static const Color accentMint = Color(0xFF15803D);

  static const Color accentPurple = Color(0xFF6D28D9);
  static const Color accentPink = Color(0xFFBE185D);
  static const Color accentOrange = Color(0xFFC2410C);

  /// Deep sky used by the "123" theme.
  static const Color accentSky = Color(0xFF0369A1);

  // ----------------------------------------------------------------- pastels
  /// Soft washes used as illustration and card backgrounds; all pair with
  /// [ink] at well above 4.5:1.
  static const Color pastelSky = Color(0xFFE3F2FF);
  static const Color pastelMint = Color(0xFFE2F7EB);
  static const Color pastelSun = Color(0xFFFFF3D6);
  static const Color pastelCoral = Color(0xFFFFE9E1);
  static const Color pastelPurple = Color(0xFFF0EAFE);

  /// Locked / disabled surfaces.
  static const Color locked = Color(0xFFC9CED8);

  /// Silhouettes for the shadow-match puzzle (dark gray, never black).
  static const Color silhouette = Color(0xFF3A3F55);

  // ----------------------------------------------------------------- status
  /// Gold used for stars and trophies (icon fills, never small text).
  static const Color gold = Color(0xFFFBBF24);

  /// Readable amber for text sitting on a pale gold pill.
  static const Color goldInk = Color(0xFFB45309);

  /// Quiz accent - a warm orange, deliberately not red.
  static const Color quiz = Color(0xFFC2410C);

  /// Success green for chimes, borders and "great job" text.
  static const Color success = Color(0xFF15803D);

  /// Warning / gentle wrong-answer accent (orange, never red).
  static const Color warning = Color(0xFFC2410C);

  /// Errors are shown warmly; the token keeps a non-red hue on purpose.
  static const Color error = Color(0xFFC2410C);

  /// One vivid pastel per letter (indexed A-Z). Used for letter tiles,
  /// confetti and illustration accents - all with white or navy ink.
  static const List<Color> letterPalette = <Color>[
    Color(0xFFE8763A), Color(0xFFE86A4A), Color(0xFFD95F3B), Color(0xFFC2410C),
    Color(0xFFBE185D), Color(0xFFC2185B), Color(0xFFA21CAF), Color(0xFF6D28D9),
    Color(0xFF4F46E5), Color(0xFF2563EB), Color(0xFF0284C7), Color(0xFF0E7490),
    Color(0xFF0F766E), Color(0xFF15803D), Color(0xFF4D7C0F), Color(0xFF65A30D),
    Color(0xFFA16207), Color(0xFFB45309), Color(0xFFC2410C), Color(0xFFD97706),
    Color(0xFFB45309), Color(0xFFA16207), Color(0xFF8D6E63), Color(0xFF6D4C41),
    Color(0xFF5B6884), Color(0xFF6D28D9),
  ];

  static Color forLetter(String letter) {
    final index = letter.toUpperCase().codeUnitAt(0) - 65;
    return letterPalette[index.clamp(0, letterPalette.length - 1)];
  }
}