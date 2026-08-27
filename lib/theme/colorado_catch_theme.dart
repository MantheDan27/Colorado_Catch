import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/species_rarity.dart';

/// Palette from the "Colorado Catch, redesigned" Claude Design mockup
/// (paper-atlas visual language) — see the project's design doc for the
/// full rationale. Centralized here so every screen pulls the same colors
/// instead of re-declaring hex values.
class AppColors {
  AppColors._();

  static const forest = Color(0xFF0F3D33); // primary — buttons, FAB, dark surfaces
  static const ink = Color(0xFF101A17); // near-black — headings, high-emphasis text
  static const amber = Color(0xFFE4A13B); // accent — points/coins, highlights
  static const cream = Color(0xFFF6F3ED); // default screen background
  static const paper = Color(0xFFEFE7D6); // map/atlas background
  static const muted = Color(0xFF6A7873); // secondary text
  static const mutedDark = Color(0xFF3C4B45); // body copy on light backgrounds

  // Rarity tier colors (see RarityTier in species_rarity.dart).
  static const tierCommon = muted;
  static const tierUncommon = Color(0xFF2E7D6E);
  static const tierRare = Color(0xFFB45B3E);
  static const tierLegendary = Color(0xFF8A5AA8);

  // Water-feature swatches, matching the map legend.
  static const river = Color(0xFF7FA8AE);
  static const lake = Color(0xFF9BC0C4);
  static const lakeBorder = Color(0xFF6E969B);
}

/// Maps a rarity tier to its display color — used on species chips, tier
/// pills, and the points banner wherever a catch's rarity is shown.
Color tierColor(RarityTier tier) {
  switch (tier) {
    case RarityTier.common:
      return AppColors.tierCommon;
    case RarityTier.uncommon:
      return AppColors.tierUncommon;
    case RarityTier.rare:
      return AppColors.tierRare;
    case RarityTier.legendary:
      return AppColors.tierLegendary;
  }
}

ThemeData buildColoradoCatchTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  final bodyFont = GoogleFonts.familjenGroteskTextTheme(base.textTheme);
  final headingFont = GoogleFonts.instrumentSerif();

  final textTheme = bodyFont.copyWith(
    displayLarge: headingFont.copyWith(fontSize: 57, color: AppColors.ink),
    displayMedium: headingFont.copyWith(fontSize: 45, color: AppColors.ink),
    displaySmall: headingFont.copyWith(fontSize: 34, color: AppColors.ink),
    headlineLarge: headingFont.copyWith(fontSize: 32, color: AppColors.ink),
    headlineMedium: headingFont.copyWith(fontSize: 28, color: AppColors.ink),
    headlineSmall: headingFont.copyWith(fontSize: 24, color: AppColors.ink),
    titleLarge: bodyFont.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: AppColors.ink),
    titleMedium: bodyFont.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.ink),
    bodyLarge: bodyFont.bodyLarge?.copyWith(color: AppColors.mutedDark),
    bodyMedium: bodyFont.bodyMedium?.copyWith(color: AppColors.mutedDark),
    bodySmall: bodyFont.bodySmall?.copyWith(color: AppColors.muted),
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.forest,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.forest,
    onPrimary: AppColors.cream,
    secondary: AppColors.amber,
    onSecondary: AppColors.ink,
    surface: AppColors.cream,
    onSurface: AppColors.ink,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      titleTextStyle: headingFont.copyWith(fontSize: 24, color: AppColors.ink),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.forest,
        foregroundColor: AppColors.cream,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: bodyFont.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: Color(0x33101A17)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.forest,
      foregroundColor: AppColors.cream,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.forest.withValues(alpha: 0.08),
      labelStyle: bodyFont.labelLarge?.copyWith(color: AppColors.forest),
    ),
  );
}
