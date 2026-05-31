import 'package:flutter/material.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

/// Complete production-grade ThemeData compilation for EasyConnect.
/// Combines Color, Typography, and Spacing systems into a cohesive Material 3 design system.
/// Optimizes Dialogs, Snackbars, and Buttons for maximum physical and cognitive accessibility.
class AppDesignTheme {
  AppDesignTheme._(); // Prevent instantiation

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppDesignColors.primary,
        primary: AppDesignColors.primary,
        onPrimary: Colors.white,
        secondary: AppDesignColors.primaryDark,
        onSecondary: Colors.white,
        surface: AppDesignColors.surface,
        onSurface: AppDesignColors.textPrimary,
        error: AppDesignColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppDesignColors.surface,
      dividerColor: AppDesignColors.divider,
      fontFamily: AppTypography.fontFamily,

      // -------------------------------------------------------------
      // AppBar Design System (Centered titles, large readable icons)
      // -------------------------------------------------------------
      appBarTheme: const AppBarTheme(
        backgroundColor: AppDesignColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: AppDesignColors.textPrimary,
          size: 32.0, // High visibility accessible navigation arrows
        ),
      ),

      // -------------------------------------------------------------
      // Card Design System (Rounded rectangle container)
      // -------------------------------------------------------------
      cardTheme: const CardThemeData(
        color: AppDesignColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.cardRadius),
            topRight: Radius.circular(AppSpacing.cardRadius),
            bottomLeft: Radius.circular(AppSpacing.cardRadius),
            bottomRight: Radius.circular(AppSpacing.cardRadius),
          ),
          side: BorderSide(
            color: AppDesignColors.divider,
            width: 1.5,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // -------------------------------------------------------------
      // Button Design System (Rule 4: Enforces 72dp heights and large text)
      // -------------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDesignColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppSpacing.primaryButtonHeight), // Comfortable 72dp height
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTypography.buttonText,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDesignColors.textPrimary,
          backgroundColor: Colors.transparent,
          side: const BorderSide(
            color: AppDesignColors.primary,
            width: 2.0,
          ),
          minimumSize: const Size(double.infinity, AppSpacing.primaryButtonHeight), // Comfortable 72dp height
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: AppTypography.buttonText.copyWith(
            color: AppDesignColors.textPrimary,
          ),
        ),
      ),

      // -------------------------------------------------------------
      // Dialog Design System (Centered overlays, large actions, high-contrast)
      // -------------------------------------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: AppDesignColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(
            color: AppDesignColors.divider,
            width: 2.0,
          ),
        ),
        titleTextStyle: AppTypography.primaryLabel.copyWith(
          color: AppDesignColors.textPrimary,
        ),
        contentTextStyle: AppTypography.bodyText.copyWith(
          color: AppDesignColors.textSecondary,
        ),
        actionsPadding: const EdgeInsets.all(AppSpacing.lg),
      ),

      // -------------------------------------------------------------
      // Snackbar Design System (Terracotta or sage overlays, 20sp readable labels)
      // -------------------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppDesignColors.textPrimary, // High contrast background
        contentTextStyle: AppTypography.bodyText.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // -------------------------------------------------------------
      // List Tile Design System (Double target heights, bold separators)
      // -------------------------------------------------------------
      listTileTheme: ListTileThemeData(
        contentPadding: AppSpacing.listTilePadding,
        minVerticalPadding: AppSpacing.md,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        tileColor: Colors.transparent,
      ),

      // -------------------------------------------------------------
      // Progress Indicator Theme
      // -------------------------------------------------------------
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppDesignColors.primary,
        linearTrackColor: AppDesignColors.primaryLight,
      ),
    );
  }

  // -------------------------------------------------------------
  // Custom Reusable Accessibility Overlays (Snackbar and Alerts templates)
  // -------------------------------------------------------------

  /// Helper to trigger a highly readable success dialog in Telugu.
  static void showSuccessAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: AppDesignColors.success,
            size: 64.0,
          ),
          title: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.confirmedName.copyWith(
              color: AppDesignColors.success,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesignColors.success,
              ),
              child: const Text('హోమ్ కి వెళ్ళు'), // Go Home in Telugu
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Helper to trigger a high contrast warning Snackbar in Telugu.
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppDesignColors.error,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 32.0,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyText.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
