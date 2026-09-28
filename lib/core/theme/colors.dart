import 'package:flutter/material.dart';

/// Semantic design tokens for Reforge.
///
/// Reforge adheres to an "Industrial Precision & Calm Engineering Craft" aesthetic.
/// Note: The application strictly utilizes a single, polished Light Theme.
abstract final class ReforgeColors {
  // --- Core Surfaces & Backgrounds ---
  /// Main application background - Soft warm surface (off-white cream)
  static const Color warmSurface = Color(0xFFFBF9F5);

  /// Standard card & container background
  static const Color cardSurface = Color(0xFFFFFFFF);

  /// Slightly elevated or inset container background
  static const Color elevatedSurface = Color(0xFFF7F3EE);

  // --- Content & Typography ---
  /// Primary text color (Graphite)
  static const Color graphite = Color(0xFF111827);

  /// Secondary text & metadata
  static const Color muted = Color(0xFF64748B);

  /// Placeholder, disabled, or very subtle text
  static const Color subtle = Color(0xFF94A3B8);

  // --- Deep Slate Surfaces (Bottom Nav, Dark Feature Cards, Avatar) ---
  /// Deep slate surface for navigation and contrast containers
  static const Color deepSlate = Color(0xFF172033);

  /// Inactive icon & label tint inside dark containers
  static const Color deepSlateMuted = Color(0xFF8B9CB8);

  /// Border for elements inside deep slate surfaces
  static const Color deepSlateBorder = Color(0xFF26334D);

  // --- Brand / Forge Accent ---
  /// Primary brand accent (Warm Forge Bronze/Amber)
  static const Color forgeAccent = Color(0xFFB45309);

  /// Darker shade for active/pressed forge buttons
  static const Color forgeAccentDark = Color(0xFF92400E);

  /// Lighter shade for highlights & progress tracks
  static const Color forgeAccentLight = Color(0xFFD97706);

  /// Translucent tint for forge accent badge backgrounds
  static const Color forgeAccentBg = Color(0xFFFEF3C7);

  // --- Borders & Dividers ---
  /// Default card & element outline
  static const Color border = Color(0xFFE5E7EB);

  /// Subtle divider lines
  static const Color borderSubtle = Color(0xFFF1F5F9);

  // --- Semantic Status Tints (Badges, Pills, Chips) ---
  /// Green status (Active, New, What Stays, Completed)
  static const Color success = Color(0xFF15803D);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  /// Amber status (Exploring, Active Sprint, Stage Pills)
  static const Color warning = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningBorder = Color(0xFFFDE68A);

  /// Red/Danger status (Abandon, Failure, Removed)
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  /// Category tag tint (Dev Tools, Architecture, Security)
  static const Color category = Color(0xFF4338CA);
  static const Color categoryBg = Color(0xFFEEF2FF);
  static const Color categoryBorder = Color(0xFFC7D2FE);

  // --- Code & Callout Tints ---
  /// Code snippet badge background
  static const Color codeBg = Color(0xFFF3F4F6);
  static const Color codeText = Color(0xFF9A3412);

  /// Callout / Quote box background
  static const Color quoteBg = Color(0xFFFFFBEB);
  static const Color quoteBorder = Color(0xFFFDE68A);
}
