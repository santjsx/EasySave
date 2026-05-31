import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

enum EasyButtonVariant {
  filled,
  outlined,
}

/// A highly tactile, elderly-friendly button.
/// Enforces a comfortable 72dp height and large 24sp Noto Sans Telugu text.
/// Includes native haptic feedback and screen reader Semantics support.
class EasyButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final EasyButtonVariant variant;
  final IconData? icon;

  const EasyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = EasyButtonVariant.filled,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: AppSpacing.primaryButtonHeight, // Locked at 72.0 dp height
        child: variant == EasyButtonVariant.filled
            ? ElevatedButton(
                onPressed: _handlePress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppDesignColors.surfaceMuted,
                  disabledForegroundColor: AppDesignColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: _buildChild(Colors.white),
              )
            : OutlinedButton(
                onPressed: _handlePress,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppDesignColors.textPrimary,
                  backgroundColor: Colors.transparent,
                  side: BorderSide(
                    color: isEnabled ? AppDesignColors.primary : AppDesignColors.divider,
                    width: 2.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: _buildChild(AppDesignColors.textPrimary),
              ),
      ),
    );
  }

  /// Triggers a light haptic vibration before invoking callback (helps tactile confirmation)
  void _handlePress() {
    if (onPressed == null) return;
    HapticFeedback.mediumImpact();
    onPressed!();
  }

  Widget _buildChild(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 32.0,
            color: textColor,
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTypography.buttonText.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
