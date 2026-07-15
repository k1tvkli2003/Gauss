import 'package:flutter/material.dart';

abstract final class GaussColors {
  static const voidBlack = Color(0xFF070A0B);
  static const ink = Color(0xFF0E1416);
  static const raised = Color(0xFF151C1F);
  static const parchment = Color(0xFFF3E7C8);
  static const parchmentInk = Color(0xFF282116);
  static const brass = Color(0xFFDCA33A);
  static const brassLight = Color(0xFFF6C96B);
  static const teal = Color(0xFF61B798);
  static const violet = Color(0xFFA878E8);
  static const ice = Color(0xFF72C5DF);
  static const error = Color(0xFFFF6B57);
  static const muted = Color(0xFF98A0A2);
  static const line = Color(0xFF394247);
}

ThemeData buildGaussTheme() {
  const scheme = ColorScheme.dark(
    primary: GaussColors.brass,
    onPrimary: GaussColors.voidBlack,
    secondary: GaussColors.teal,
    onSecondary: GaussColors.voidBlack,
    error: GaussColors.error,
    surface: GaussColors.ink,
    onSurface: Color(0xFFF3EEE2),
    surfaceContainerHighest: GaussColors.raised,
    outline: GaussColors.line,
  );
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: GaussColors.voidBlack,
    fontFamily: 'Vazirmatn',
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xF2111719),
      indicatorColor: Color(0x33DCA33A),
      height: 70,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xF20B0F10),
      indicatorColor: Color(0x33DCA33A),
      selectedIconTheme: IconThemeData(color: GaussColors.brassLight),
      selectedLabelTextStyle: TextStyle(
        color: GaussColors.brassLight,
        fontWeight: FontWeight.w700,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(52, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    cardTheme: CardThemeData(
      color: GaussColors.raised.withValues(alpha: .96),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: GaussColors.line),
      ),
    ),
    dividerTheme: const DividerThemeData(color: GaussColors.line, thickness: 1),
  );
}
