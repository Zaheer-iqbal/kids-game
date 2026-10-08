import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'design_tokens.dart';

/// Design-system theme: bundled "Fredoka" for display/headings, "Nunito" for
/// body text, plus a system emoji fallback so emoji render identically on
/// every device (Noto Color Emoji on Android/Linux/Windows, Apple Color Emoji
/// on iOS/macOS).
abstract final class AppTheme {
  static const String headingFont = 'Fredoka';
  static const String bodyFont = 'Nunito';

  /// Tried in order after the primary font when a glyph is missing.
  static const List<String> emojiFallback = <String>[
    'Noto Color Emoji',
    'Apple Color Emoji',
    'Segoe UI Emoji',
    'Segoe UI Symbol',
  ];

  /// Global text scale is honoured up to 1.3x; beyond that kids screens start
  /// to overflow, so the value is capped instead of clipped mid-glyph.
  static TextScaler clampTextScaler(TextScaler scaler) {
    final double scale = scaler.scale(1).clamp(0.85, 1.3);
    return TextScaler.linear(scale);
  }

  static ThemeData get light {
    final ColorScheme scheme = const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.ink,
      tertiary: AppColors.accentCoral,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      outline: AppColors.inkSoft,
      outlineVariant: Color(0xFFE2E8F0),
      shadow: Color(0xFF0F172A),
      scrim: Color(0x66000000),
      inverseSurface: AppColors.inkBright,
      onInverseSurface: AppColors.ink,
      inversePrimary: AppColors.accentPurple,
    );

    final TextTheme textTheme = TextTheme(
      displayLarge: _display(52, color: AppColors.inkBright, tracking: -1),
      displayMedium: _display(44, color: AppColors.inkBright, tracking: -0.8),
      displaySmall: _display(36, color: AppColors.inkBright, tracking: -0.6),
      headlineLarge: _display(32, color: AppColors.ink),
      headlineMedium: _display(28, color: AppColors.ink),
      headlineSmall: _display(24, color: AppColors.ink),
      titleLarge: _body(22, color: AppColors.ink, weight: FontWeight.w800),
      titleMedium: _body(18, color: AppColors.ink, weight: FontWeight.w800),
      titleSmall: _body(16, color: AppColors.ink, weight: FontWeight.w700),
      bodyLarge: _body(17, color: AppColors.ink, weight: FontWeight.w600),
      bodyMedium: _body(15, color: AppColors.ink, weight: FontWeight.w600),
      bodySmall: _body(13, color: AppColors.inkMuted, weight: FontWeight.w600),
      labelLarge: _display(20, color: Colors.white, tracking: 0.2),
      labelMedium: _body(14, color: AppColors.ink, weight: FontWeight.w800),
      labelSmall: _body(12, color: AppColors.inkMuted, weight: FontWeight.w700),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: bodyFont,
      fontFamilyFallback: emojiFallback,
      scaffoldBackgroundColor: AppColors.bgTop,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space6,
            vertical: AppTokens.space4,
          ),
          minimumSize: const Size(AppTokens.minTapTarget, AppTokens.minTapTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusPill)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space6,
            vertical: AppTokens.space4,
          ),
          minimumSize: const Size(AppTokens.minTapTarget, AppTokens.minTapTarget),
          side: const BorderSide(color: AppColors.primary, width: 2.5),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusPill)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(AppTokens.minTapTarget, AppTokens.minTapTarget),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(AppTokens.minTapTarget, AppTokens.minTapTarget),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? AppColors.accentMint
              : const Color(0xFFCBD5E1),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
        textStyle: textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: Color(0xFFE2E8F0),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
      ),
    );
  }

  /// The huge, outlined "sticker" style used for letters and numbers shown
  /// big on screen (meet-the-letter, level nodes, etc.).
  static TextStyle glyphStyle(
    double size, {
    Color color = Colors.white,
    Color? outline,
  }) {
    return TextStyle(
      fontFamily: headingFont,
      fontFamilyFallback: emojiFallback,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.0,
      color: color,
      fontVariations: const <FontVariation>[FontVariation('wght', 700)],
      shadows: <Shadow>[
        Shadow(
          color: (outline ?? const Color(0xFF0F172A)).withValues(alpha: 0.35),
          blurRadius: size * 0.06,
          offset: Offset(0, size * 0.035),
        ),
      ],
    );
  }

  static TextStyle _display(
    double size, {
    Color color = AppColors.ink,
    double tracking = 0,
    double height = 1.06,
  }) {
    return TextStyle(
      fontFamily: headingFont,
      fontFamilyFallback: emojiFallback,
      fontSize: size,
      fontWeight: FontWeight.w700,
      fontVariations: const <FontVariation>[FontVariation('wght', 700)],
      color: color,
      height: height,
      letterSpacing: tracking,
    );
  }

  static TextStyle _body(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w600,
    double height = 1.35,
  }) {
    return TextStyle(
      fontFamily: bodyFont,
      fontFamilyFallback: emojiFallback,
      fontSize: size,
      fontWeight: weight,
      fontVariations: <FontVariation>[
        FontVariation('wght', weight.value.toDouble()),
      ],
      color: color,
      height: height,
    );
  }
}
