import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light({Color seed = Colors.blue}) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,

      inputDecorationTheme: _inputTheme(scheme),
      filledButtonTheme: _filledButtonTheme(scheme),
      textButtonTheme: _textButtonTheme(scheme),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
    );
  }

  static ThemeData dark({Color seed = Colors.blue}) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,

      inputDecorationTheme: _inputTheme(scheme),
      filledButtonTheme: _filledButtonTheme(scheme),
      textButtonTheme: _textButtonTheme(scheme),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
    );
  }

  static InputDecorationTheme _inputTheme(ColorScheme scheme) {
    return InputDecorationTheme(
      filled: true,
      // ✅ light/dark auto: surfaceVariant là nền input hợp lý
      fillColor: scheme.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(ColorScheme scheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        // ✅ tự theo theme
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(ColorScheme scheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
