import 'package:flutter/material.dart';

/// Material 3 theme for Class Activity Manager. Català locale; dd/MM/yyyy.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const forestGreen = Color(0xFF1B5E20);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: forestGreen,
      brightness: Brightness.light,
    ).copyWith(
      primary: forestGreen,
      surface: const Color(0xFFF1F4F1),
      background: const Color(0xFFF1F4F1),
      surfaceVariant: const Color(0xFFE1E7E1),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      fontFamily: null,
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1B5E20),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: null,
    );
  }
}
