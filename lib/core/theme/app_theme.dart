import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'design_tokens.dart';

/// Design-system theme: bundled "Fredoka" for display/headings, "Nunito" for
/// body text, plus a system emoji fallback so emoji render identically on
/// every device (Noto Color Emoji on Android/Linux/Windows, Apple Color Emoji
/// on iOS/macOS).
///
/// The app ships a **single light theme**. Every component family (scaffold,
/// app bar, card, sheet, dialog, navigation bar, chip, button, text field) is
/// themed explicitly so a widget can never fall back to a platform default
/// that uses black or an inverted (dark-mode) surface.
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

  /// Dark status/navigation bar icons on the light app surfaces.
  static const SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: AppColors.outlineSoft,
  );

  /// Global text scale is honoured across the full 0.85x-1.6x range. The lower
  /// bound keeps tiny system scales legible; the upper bound stops a runaway
  /// accessibility scale from shredding a friendly card. Every screen is laid
  /// out to survive 1.6x without overflowing.
  static TextScaler clampTextScaler(TextScaler scaler) {
    final double scale = scaler.scale(1).clamp(0.85, 1.6);
    return TextScaler.linear(scale);
  }

  static ThemeData get light {
    final ColorScheme scheme = const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.pastelSky,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.pastelSun,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.accentCoral,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.pastelCoral,
      onTertiaryContainer: AppColors.ink,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: Color(0xFFFFE8D6),
      onErrorContainer: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: AppColors.surfaceDim,
      surfaceContainer: AppColors.surfaceSoft,
      surfaceContainerHigh: Color(0xFFEDF2F9),
      surfaceContainerHighest: AppColors.outlineSoft,
      outline: AppColors.inkSoft,
      outlineVariant: AppColors.outlineSoft,
      shadow: Color(0xFF26324D),
      scrim: Color(0x6626324D),
      inverseSurface: AppColors.ink,
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFF93C5FD),
      surfaceTint: Colors.transparent,
    );

    final TextTheme textTheme = TextTheme(
      displayLarge: _display(52, color: AppColors.ink, tracking: -1),
      displayMedium: _display(44, color: AppColors.ink, tracking: -0.8),
      displaySmall: _display(36, color: AppColors.ink, tracking: -0.6),
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
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: bodyFont,
      fontFamilyFallback: emojiFallback,
      scaffoldBackgroundColor: AppColors.bgTop,
      canvasColor: AppColors.surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.ink),
      primaryIconTheme: const IconThemeData(color: AppColors.ink),
      splashFactory: NoSplash.splashFactory,
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineSoft,
        thickness: 1.4,
        space: 1.4,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        iconTheme: const IconThemeData(color: AppColors.ink),
        actionsIconTheme: const IconThemeData(color: AppColors.ink),
        titleTextStyle: textTheme.headlineSmall,
        systemOverlayStyle: overlayStyle,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x1A26324D),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          side: const BorderSide(color: AppColors.outlineSoft, width: 1.4),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        modalBarrierColor: const Color(0x6626324D),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.sheetRadius,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusXL),
          side: const BorderSide(color: AppColors.outlineSoft, width: 1.4),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.pastelSky,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.inkSoft,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (Set<WidgetState> states) => _body(
            12,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.inkMuted,
            weight: FontWeight.w800,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.inkSoft,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.pastelSky,
        disabledColor: AppColors.locked,
        side: const BorderSide(color: AppColors.outlineSoft, width: 1.4),
        labelStyle: textTheme.labelMedium,
        secondaryLabelStyle: textTheme.labelMedium,
        shape: const StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.locked,
          disabledForegroundColor: AppColors.surface,
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
          textStyle: textTheme.labelLarge?.copyWith(color: AppColors.primary),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(AppTokens.minTapTarget, AppTokens.minTapTarget),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppColors.outlineSoft, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppColors.outlineSoft, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.4),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? AppColors.accentMint
              : AppColors.locked,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? AppColors.accentMint
              : AppColors.inkSoft,
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
        circularTrackColor: AppColors.outlineSoft,
        linearTrackColor: AppColors.outlineSoft,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: textTheme.bodyLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.ink,
        textColor: AppColors.ink,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.outlineSoft,
        thumbColor: AppColors.primary,
      ),
    );
  }

  /// The huge, outlined "sticker" style used for letters and numbers shown
  /// big on screen (meet-the-letter, level nodes, etc.).
  static TextStyle glyphStyle(
    double size, {
    Color color = AppColors.ink,
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
          color: (outline ?? const Color(0xFF26324D)).withValues(alpha: 0.35),
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