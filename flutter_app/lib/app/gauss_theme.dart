import 'package:flutter/material.dart';

abstract final class GaussColors {
  static const abyss = Color(0xFF03090B);
  static const voidBlack = Color(0xFF050B0D);
  static const deepInk = Color(0xFF07151C);
  static const ink = Color(0xFF0B1417);
  static const raised = Color(0xFF121E21);
  static const panelHigh = Color(0xFF19282C);
  static const parchment = Color(0xFFF2E4C3);
  static const ivory = Color(0xFFF6ECD6);
  static const parchmentInk = Color(0xFF261E12);
  static const brassDeep = Color(0xFF75501F);
  static const brass = Color(0xFFC79238);
  static const brassLight = Color(0xFFF0C36A);
  static const signal = Color(0xFF62AE9C);
  static const signalBright = Color(0xFF8BD7C0);
  static const teal = signal;
  static const violet = Color(0xFFAA83D5);
  static const ice = Color(0xFF77BFD1);
  static const error = Color(0xFFFF7564);
  static const warning = Color(0xFFE6A84C);
  static const muted = Color(0xFF9FA9A8);
  static const fog = Color(0xFF7F8A8A);
  static const line = Color(0xFF344448);
  static const hairline = Color(0xFF243337);
}

abstract final class GaussRadii {
  static const small = 10.0;
  static const medium = 16.0;
  static const large = 24.0;
  static const pill = 999.0;
}

ThemeData buildGaussTheme() {
  const scheme = ColorScheme.dark(
    primary: GaussColors.brassLight,
    onPrimary: GaussColors.abyss,
    primaryContainer: GaussColors.brassDeep,
    onPrimaryContainer: GaussColors.ivory,
    secondary: GaussColors.signal,
    onSecondary: GaussColors.abyss,
    error: GaussColors.error,
    surface: GaussColors.ink,
    onSurface: GaussColors.ivory,
    surfaceContainerHighest: GaussColors.panelHigh,
    outline: GaussColors.line,
    outlineVariant: GaussColors.hairline,
    shadow: Colors.black,
  );
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: GaussColors.voidBlack,
    fontFamily: 'Manrope',
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
  );
  final text = base.textTheme.apply(
    fontFamily: 'Manrope',
    fontFamilyFallback: const ['Vazirmatn'],
    bodyColor: GaussColors.ivory,
    displayColor: GaussColors.ivory,
  );
  return base.copyWith(
    textTheme: text.copyWith(
      displayLarge: text.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
        height: 1.04,
      ),
      displaySmall: text.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -.7,
        height: 1.08,
      ),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -.35,
        height: 1.12,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -.2,
        height: 1.16,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: text.labelLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: .15,
      ),
      labelSmall: text.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: .55,
      ),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.55),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.48),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: GaussColors.ink.withValues(alpha: .97),
      indicatorColor: GaussColors.brass.withValues(alpha: .13),
      height: 72,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? GaussColors.brassLight
              : GaussColors.fog,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: GaussColors.ink,
      indicatorColor: Color(0x243C947F),
      selectedIconTheme: IconThemeData(color: GaussColors.brassLight),
      unselectedIconTheme: IconThemeData(color: GaussColors.fog),
      selectedLabelTextStyle: TextStyle(
        color: GaussColors.brassLight,
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: GaussColors.fog,
        fontWeight: FontWeight.w600,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: GaussColors.abyss,
        backgroundColor: GaussColors.brassLight,
        disabledBackgroundColor: GaussColors.line,
        disabledForegroundColor: GaussColors.fog,
        minimumSize: const Size(54, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GaussRadii.medium),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: GaussColors.ivory,
        side: const BorderSide(color: GaussColors.line),
        minimumSize: const Size(54, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GaussRadii.medium),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: GaussColors.brassLight,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    cardTheme: CardThemeData(
      color: GaussColors.raised.withValues(alpha: .97),
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GaussRadii.large),
        side: const BorderSide(color: GaussColors.line),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: GaussColors.raised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GaussRadii.large),
        side: const BorderSide(color: GaussColors.line),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: GaussColors.raised,
      modalBackgroundColor: GaussColors.raised,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: GaussColors.brass,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GaussColors.deepInk.withValues(alpha: .78),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GaussRadii.medium),
        borderSide: const BorderSide(color: GaussColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GaussRadii.medium),
        borderSide: const BorderSide(color: GaussColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GaussRadii.medium),
        borderSide: const BorderSide(color: GaussColors.brassLight, width: 1.5),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: GaussColors.signal,
      linearTrackColor: GaussColors.hairline,
    ),
    dividerTheme: const DividerThemeData(
      color: GaussColors.hairline,
      thickness: 1,
    ),
    iconTheme: const IconThemeData(color: GaussColors.ivory),
    focusColor: GaussColors.brassLight.withValues(alpha: .24),
    hoverColor: GaussColors.brassLight.withValues(alpha: .08),
  );
}
