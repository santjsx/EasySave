import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Highly tactile, elderly-friendly numeric keypad for EasyConnect.
/// Enforces circular buttons exactly 72dp in size (Rule 16).
/// Excludes QWERTY letters to prevent cognitive overload.
/// Features: 0-9 digits, Backspace/Delete, and Clear All (🗑) actions.
class EasyNumberPad extends StatelessWidget {
  final Function(String digit) onDigitTap;
  final VoidCallback onBackspaceTap;
  final VoidCallback onClearTap;

  static const Map<String, String> _teluguDigits = {
    '1': 'అంకె ఒకటి',
    '2': 'అంకె రెండు',
    '3': 'అంకె మూడు',
    '4': 'అంకె నాలుగు',
    '5': 'అంకె ఐదు',
    '6': 'అంకె ఆరు',
    '7': 'అంకె ఏడు',
    '8': 'అంకె ఎనిమిది',
    '9': 'అంకె తొమ్మిది',
    '0': 'అంకె సున్నా',
  };

  const EasyNumberPad({
    super.key,
    required this.onDigitTap,
    required this.onBackspaceTap,
    required this.onClearTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        const SizedBox(height: AppSpacing.md),
        _buildRow(['4', '5', '6']),
        const SizedBox(height: AppSpacing.md),
        _buildRow(['7', '8', '9']),
        const SizedBox(height: AppSpacing.md),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) => _buildDigitButton(digit)).toList(),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildClearButton(),
        _buildDigitButton('0'),
        _buildBackspaceButton(),
      ],
    );
  }

  /// Builds numeric digit buttons (72dp circular, high contrast)
  Widget _buildDigitButton(String digit) {
    final String semanticLabel = _teluguDigits[digit] ?? digit;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        width: AppSpacing.keypadButtonSize, // 72.0 dp (Rule 16)
        height: AppSpacing.keypadButtonSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Material(
          color: AppDesignColors.surfaceMuted,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact(); // Native light tap ripple haptics
              onDigitTap(digit);
            },
            splashColor: AppDesignColors.primaryLight,
            highlightColor: AppDesignColors.primaryLight.withValues(alpha: 0.5),
            child: Center(
              child: Text(
                digit,
                style: AppTypography.keypadDigit.copyWith(
                  color: AppDesignColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds Backspace/Delete button (Rule 16)
  Widget _buildBackspaceButton() {
    return Semantics(
      button: true,
      label: 'ఒక్క అంకె వెనక్కి తుడిచివేయి', // Detailed backspace description in Telugu
      child: Container(
        width: AppSpacing.keypadButtonSize,
        height: AppSpacing.keypadButtonSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Material(
          color: AppDesignColors.surfaceMuted,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact(); // Stronger haptics for deletes
              onBackspaceTap();
            },
            splashColor: AppDesignColors.primaryLight,
            highlightColor: AppDesignColors.primaryLight.withValues(alpha: 0.5),
            child: const Center(
              child: Icon(
                Icons.backspace_outlined,
                size: 32.0,
                color: AppDesignColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds Clear All button (Wipes entire dialing buffer)
  Widget _buildClearButton() {
    return Semantics(
      button: true,
      label: 'మొత్తం తుడిచివేయి', // Clear All in Telugu script
      child: Container(
        width: AppSpacing.keypadButtonSize,
        height: AppSpacing.keypadButtonSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Material(
          color: AppDesignColors.surfaceMuted,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.heavyImpact(); // Strongest vibration for full deletes
              onClearTap();
            },
            splashColor: AppDesignColors.primaryLight,
            highlightColor: AppDesignColors.primaryLight.withValues(alpha: 0.5),
            child: const Center(
              child: Icon(
                Icons.delete_forever_outlined, // Highly recognizable sweeping action icon
                size: 36.0,
                color: AppDesignColors.error, // Semantic warning color (Terracotta Brick)
              ),
            ),
          ),
        ),
      ),
    );
  }
}
