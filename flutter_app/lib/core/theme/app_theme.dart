import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const accent = Color(0xFFD7FF3F);
  static const background = Color(0xFF070908);
  static const panel = Color(0xFF111511);
  static const panelRaised = Color(0xFF161B16);

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      onPrimary: background,
      surface: panel,
      surfaceContainer: panelRaised,
    ),
    useMaterial3: true,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: InkSparkle.splashFactory,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        side: const BorderSide(color: Color(0x2EFFFFFF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48), textStyle: const TextStyle(fontWeight: FontWeight.w700)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xF20A0D0A),
      indicatorColor: Color(0x2ED7FF3F),
      elevation: 0,
      height: 72,
    ),
    cardTheme: CardThemeData(
      color: panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0x18FFFFFF)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accent,
      linearTrackColor: Color(0xFF222822),
    ),
    dividerTheme: const DividerThemeData(color: Color(0x14FFFFFF)),
  );
}
