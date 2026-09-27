import 'package:flutter/material.dart';
import 'colors.dart';

/// Typography definitions for Reforge.
///
/// Reforge utilizes the Inter typeface with strict sizing and line-height constraints
/// designed for high readability, context preservation, and engineering aesthetics.
abstract final class ReforgeTypography {
  static const String fontFamily = 'Inter';

  // --- Display & Hero Styles ---
  /// Large hero greeting (e.g., "Good evening, Arefin")
  static const TextStyle greeting = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.2,
    color: ReforgeColors.graphite,
  );

  /// Main screen title (e.g., "Ideas Vault", "Reforge / V2")
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.3,
    color: ReforgeColors.graphite,
  );

  // --- Section & Card Titles ---
  /// Section headers (e.g., "Active Project", "Recent Ideas", "What We Learned")
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: -0.2,
    color: ReforgeColors.graphite,
  );

  /// Card headlines (e.g., "Sublayer: SQLite Diff Engine for Git Branches")
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.15,
    color: ReforgeColors.graphite,
  );

  /// Sub-section or item title
  static const TextStyle subTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: ReforgeColors.graphite,
  );

  // --- Body Styles ---
  /// Standard descriptive text
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: ReforgeColors.muted,
  );

  /// Emphasized body text
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: ReforgeColors.graphite,
  );

  /// Compact body text for secondary cards or footnotes
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: ReforgeColors.muted,
  );

  /// Compact caption text for helper labels and descriptions
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: ReforgeColors.muted,
  );

  // --- Metrics & Numbers ---
  /// Large prominent metric numbers (e.g., "14", "3", "68%")
  static const TextStyle statNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
    color: ReforgeColors.graphite,
  );

  /// Metric labels beneath numbers (e.g., "Ideas Captured", "Active Builds")
  static const TextStyle statLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: ReforgeColors.muted,
  );

  // --- Badges, Chips & Meta ---
  /// Pill badges and status indicators (e.g., "Exploring", "STAGE 01", "Dev Tools")
  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.2,
  );

  /// Category tag chip label
  static const TextStyle chip = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.25,
  );

  /// Small metadata with timestamps (e.g., "Captured Oct 24, 2024", "Updated 2h ago")
  static const TextStyle meta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
    color: ReforgeColors.muted,
  );

  /// Uppercase section overline tracking (e.g., "QUICK WORKSHOP ACTIONS", "ACTIVE SPRINT")
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    height: 1.2,
    color: ReforgeColors.muted,
  );

  // --- Button & Action Text ---
  /// Primary CTA button label (e.g., "Capture Idea", "Continue Building")
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: Colors.white,
  );

  /// Secondary action button or text link
  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: ReforgeColors.forgeAccent,
  );

  // --- Monospace / Code ---
  /// Technical references, schemas, and CLI commands
  static const TextStyle code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: ReforgeColors.codeText,
  );

  /// Callout quote text (e.g. Post-Mortem golden lesson)
  static const TextStyle quote = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    height: 1.45,
    color: ReforgeColors.forgeAccentDark,
  );
}
