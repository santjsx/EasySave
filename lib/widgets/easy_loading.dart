import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// A premium, centered accessibility loader screen overlay.
/// Prevents touch interactions during async processes (permissions, WhatsApp handoff).
class EasyLoading extends StatelessWidget {
  final String label;

  const EasyLoading({
    super.key,
    this.label = 'వింటున్నాము...', // Default in Telugu script
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppDesignColors.textPrimary.withOpacity(0.4), // Tint screen
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Container(
            decoration: BoxDecoration(
              color: AppDesignColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 24.0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 64.0,
                  height: 64.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 5.0,
                    valueColor: AlwaysStoppedAnimation<Color>(AppDesignColors.primary),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  label,
                  style: AppTypography.sectionHeader.copyWith(
                    color: AppDesignColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
