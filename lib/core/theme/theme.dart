import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

/// Reforge Application Theme configuration.
///
/// Reforge strictly enforces a high-trust, minimalist Light Theme inspired by
/// technical documentation and engineering craft. Dark mode is intentionally omitted.
abstract final class ReforgeTheme {
  /// Primary Light Theme configuration.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: ReforgeTypography.fontFamily,
      scaffoldBackgroundColor: ReforgeColors.warmSurface,

      // --- Color Scheme ---
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: ReforgeColors.forgeAccent,
        onPrimary: Colors.white,
        primaryContainer: ReforgeColors.warningBg,
        onPrimaryContainer: ReforgeColors.forgeAccentDark,
        secondary: ReforgeColors.deepSlate,
        onSecondary: Colors.white,
        secondaryContainer: ReforgeColors.categoryBg,
        onSecondaryContainer: ReforgeColors.category,
        surface: ReforgeColors.cardSurface,
        onSurface: ReforgeColors.graphite,
        error: ReforgeColors.danger,
        onError: Colors.white,
        outline: ReforgeColors.border,
        outlineVariant: ReforgeColors.borderSubtle,
      ),

      // --- AppBar Theme ---
      appBarTheme: const AppBarTheme(
        backgroundColor: ReforgeColors.warmSurface,
        foregroundColor: ReforgeColors.graphite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: ReforgeTypography.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: ReforgeColors.graphite,
        ),
        iconTheme: IconThemeData(
          color: ReforgeColors.graphite,
          size: 22,
        ),
      ),

      // --- Card Theme ---
      cardTheme: CardThemeData(
        color: ReforgeColors.cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(
            color: ReforgeColors.border,
            width: 1,
          ),
        ),
      ),

      // --- Button Themes ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ReforgeColors.forgeAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: ReforgeTypography.buttonPrimary,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ReforgeColors.graphite,
          backgroundColor: ReforgeColors.cardSurface,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: const BorderSide(
            color: ReforgeColors.border,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: ReforgeTypography.bodyMedium,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ReforgeColors.forgeAccent,
          textStyle: ReforgeTypography.buttonSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),

      // --- Input & Form Decoration ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ReforgeColors.cardSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: ReforgeTypography.body.copyWith(
          color: ReforgeColors.subtle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ReforgeColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ReforgeColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ReforgeColors.forgeAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ReforgeColors.danger, width: 1),
        ),
      ),

      // --- Divider Theme ---
      dividerTheme: const DividerThemeData(
        color: ReforgeColors.border,
        thickness: 1,
        space: 1,
      ),

      // --- Text Theme Base Mapping ---
      textTheme: const TextTheme(
        headlineLarge: ReforgeTypography.screenTitle,
        headlineMedium: ReforgeTypography.greeting,
        titleLarge: ReforgeTypography.sectionTitle,
        titleMedium: ReforgeTypography.cardTitle,
        titleSmall: ReforgeTypography.subTitle,
        bodyLarge: ReforgeTypography.bodyMedium,
        bodyMedium: ReforgeTypography.body,
        bodySmall: ReforgeTypography.bodySmall,
        labelLarge: ReforgeTypography.buttonPrimary,
        labelMedium: ReforgeTypography.chip,
        labelSmall: ReforgeTypography.badge,
      ),
    );
  }
}
