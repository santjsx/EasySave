import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// A premium, highly visible layout card.
/// Provides a clear visual border and high-contrast interior layout.
/// Supports ink ripples and haptic sensations when [onTap] is specified.
class EasyCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const EasyCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor = AppDesignColors.surfaceCard,
    this.borderColor = AppDesignColors.divider,
    this.borderWidth = 1.5,
    this.borderRadius = AppSpacing.cardRadius,
    this.padding = AppSpacing.cardPadding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isClickable = onTap != null;

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(
        color: borderColor,
        width: borderWidth,
      ),
    );

    return Semantics(
      container: true,
      button: isClickable,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppDesignColors.textPrimary.withValues(alpha: 0.04),
              blurRadius: 16.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Card(
          shape: cardShape,
          color: backgroundColor,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: isClickable
              ? InkWell(
                  onTap: _handleTap,
                  splashColor: AppDesignColors.primaryLight.withValues(alpha: 0.5),
                  highlightColor: AppDesignColors.primaryLight.withValues(alpha: 0.3),
                  child: Padding(
                    padding: padding,
                    child: child,
                  ),
                )
              : Padding(
                  padding: padding,
                  child: child,
                ),
        ),
      ),
    );
  }

  void _handleTap() {
    if (onTap == null) return;
    HapticFeedback.lightImpact();
    onTap!();
  }
}
