import 'package:flutter/material.dart';
abstract final class AppTheme {
  static const accent = Color(0xFFD7FF3F);
  static const background = Color(0xFF090A0B);
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(primary: accent, onPrimary: background, surface: Color(0xFF111315)),
    useMaterial3: true,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 48))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(minimumSize: const Size(48, 48))),
    navigationBarTheme: const NavigationBarThemeData(backgroundColor: Color(0xFF0D0F10), indicatorColor: Color(0x332DFF3F)),
    cardTheme: const CardThemeData(color: Color(0xFF111315), margin: EdgeInsets.zero),
  );
}
