import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'easy_button.dart';

/// A production-ready accessible dialog overlay.
/// Enforces simplified vertical layouts, large typography, and primary actions.
class EasyDialog extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;
  final Color iconColor;
  
  /// Label for the primary positive action (e.g. Yes / Save)
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;

  /// Optional label for secondary cancel actions (e.g. Try Again / Back)
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const EasyDialog({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.iconColor = AppDesignColors.primary,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 64.0,
                color: iconColor,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              title,
              style: AppTypography.primaryLabel.copyWith(
                color: AppDesignColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              content,
              style: AppTypography.bodyText.copyWith(
                color: AppDesignColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            Column(
              children: [
                EasyButton(
                  label: primaryActionLabel,
                  onPressed: onPrimaryAction,
                ),
                if (secondaryActionLabel != null && onSecondaryAction != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  EasyButton(
                    label: secondaryActionLabel!,
                    onPressed: onSecondaryAction,
                    variant: EasyButtonVariant.outlined,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Factory helper to trigger this dialogue in the active view context.
  static void show(
    BuildContext context, {
    required String title,
    required String content,
    IconData? icon,
    Color iconColor = AppDesignColors.primary,
    required String primaryActionLabel,
    required VoidCallback onPrimaryAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // Enforce explicit taps on buttons to dismiss
      builder: (BuildContext context) {
        return EasyDialog(
          title: title,
          content: content,
          icon: icon,
          iconColor: iconColor,
          primaryActionLabel: primaryActionLabel,
          onPrimaryAction: onPrimaryAction,
          secondaryActionLabel: secondaryActionLabel,
          onSecondaryAction: onSecondaryAction,
        );
      },
    );
  }
}
