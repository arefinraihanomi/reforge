import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Snackbar type variants for Reforge UI feedback.
enum SnackbarType { success, error, info, warning }

/// Utility class for showing consistently-styled snackbars across Reforge.
///
/// Usage:
/// ```dart
/// ReforgeSnackbar.show(context, message: 'Saved!', type: SnackbarType.success);
/// ```
abstract final class ReforgeSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final (bgColor, icon, textColor) = switch (type) {
      SnackbarType.success => (
          ReforgeColors.deepSlate,
          Icons.check_circle_outline_rounded,
          Colors.white,
        ),
      SnackbarType.error => (
          ReforgeColors.danger,
          Icons.error_outline_rounded,
          Colors.white,
        ),
      SnackbarType.warning => (
          ReforgeColors.forgeAccent,
          Icons.warning_amber_rounded,
          Colors.white,
        ),
      SnackbarType.info => (
          ReforgeColors.deepSlate,
          Icons.info_outline_rounded,
          Colors.white,
        ),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: ReforgeTypography.bodySmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          duration: duration,
          elevation: 4,
        ),
      );
  }
}
