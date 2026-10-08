import 'package:flutter/material.dart';

/// Warm, saturated, modern kids palette with semantic tokens.
abstract final class AppColors {
  // Background gradient colors
  static const Color bgTop = Color(0xFF1E1B4B); // deep indigo
  static const Color bgBottom = Color(0xFF312E81); // deep purple
  static const Color bgGradientEnd = Color(0xFF3730A3);
  
  // Surface colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF8FAFC);
  
  // Text colors
  static const Color ink = Color(0xFF0F172A);
  static const Color inkBright = Color(0xFFFFFFFF);
  static const Color inkMuted = Color(0xFF475569);
  static const Color inkSoft = Color(0xFF64748B);
  
  // Accent colors - modern kids palette
  static const Color primary = Color(0xFF3B82F6); // sky blue
  static const Color secondary = Color(0xFFF59E0B); // sunny yellow
  static const Color accentCoral = Color(0xFFFB7185); // coral
  static const Color accentMint = Color(0xFF34D399); // mint
  static const Color accentPurple = Color(0xFFA78BFA); // purple
  static const Color accentPink = Color(0xFFEC4899); // pink
  static const Color accentOrange = Color(0xFFFB923C); // orange
  
  // Status colors
  static const Color gold = Color(0xFFFBBF24);
  static const Color quiz = Color(0xFFFB7185);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color locked = Color(0xFF9CA3AF);
  
  // Legacy compatibility
  static const Color background = Color(0xFF1E1B4B);

  /// One vivid pastel per letter (indexed A-Z).
  static const List<Color> letterPalette = <Color>[
    Color(0xFFFFB199), Color(0xFFFF9E7D), Color(0xFFFF8960), Color(0xFFF26D6D),
    Color(0xFFFF7594), Color(0xFFF778B9), Color(0xFFE28FE0), Color(0xFFB993F0),
    Color(0xFF8F95F0), Color(0xFF5FA8E6), Color(0xFF70C1E8), Color(0xFF6FC8C9),
    Color(0xFF78D6B6), Color(0xFF8FD694), Color(0xFF92D177), Color(0xFFB8CC6B),
    Color(0xFFE0C868), Color(0xFFFFC15C), Color(0xFFFFA94D), Color(0xFFFF9A3B),
    Color(0xFFF08A5B), Color(0xFFE5A16F), Color(0xFFD2A77B), Color(0xFFC9B79C),
    Color(0xFFAFB2D6), Color(0xFFB39DD6),
  ];

  static Color forLetter(String letter) {
    final index = letter.toUpperCase().codeUnitAt(0) - 65;
    return letterPalette[index.clamp(0, letterPalette.length - 1)];
  }
}