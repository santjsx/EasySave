import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// A premium, highly accessible text field tailored for elderly and Telugu-first users.
/// Features:
/// - 1-tap clear button (`X`) when text is present.
/// - Built-in optional voice-input microphone trigger.
/// - Built-in optional clipboard paste shortcut.
/// - Ample vertical padding and line height to avoid clipping Telugu diacritics.
/// - WCAG AAA contrast ratios.
class EasyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType keyboardType;
  final bool isListening;
  final VoidCallback? onVoiceTap;
  final VoidCallback? onPasteTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? errorText;
  final bool autofocus;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;

  const EasyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.isListening = false,
    this.onVoiceTap,
    this.onPasteTap,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
    this.autofocus = false,
    this.focusNode,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Clear, prominent field label
        Text(
          label,
          style: AppTypography.primaryLabel.copyWith(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: AppDesignColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // 2. Input Box with Action Buttons
        Container(
          decoration: BoxDecoration(
            color: AppDesignColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            border: Border.all(
              color: errorText != null
                  ? AppDesignColors.error
                  : AppDesignColors.divider,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8.0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Text Entry Field
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  autofocus: autofocus,
                  inputFormatters: inputFormatters,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  scrollPadding: const EdgeInsets.all(80.0),
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w600,
                    color: AppDesignColors.textPrimary,
                    fontFamily: AppTypography.fontFamily,
                    height: 1.3,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontSize: 18.0,
                      color: AppDesignColors.textSecondary.withValues(alpha: 0.7),
                      fontFamily: AppTypography.fontFamily,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 18.0,
                    ),
                  ),
                ),
              ),

              // 1-Tap Clear Button
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(
                      Icons.cancel_rounded,
                      color: AppDesignColors.textSecondary,
                      size: 24.0,
                    ),
                    tooltip: 'తుడిచివేయి',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      controller.clear();
                      if (onChanged != null) {
                        onChanged!('');
                      }
                    },
                  );
                },
              ),

              // Optional 1-Tap Paste Button
              if (onPasteTap != null)
                IconButton(
                  icon: const Icon(
                    Icons.content_paste_rounded,
                    color: AppDesignColors.primary,
                    size: 26.0,
                  ),
                  tooltip: 'పేస్ట్ చేయండి',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onPasteTap!();
                  },
                ),

              // Optional 1-Tap Voice Input Mic Button
              if (onVoiceTap != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening
                          ? AppDesignColors.error
                          : AppDesignColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (isListening
                                  ? AppDesignColors.error
                                  : AppDesignColors.primary)
                              .withValues(alpha: 0.3),
                          blurRadius: 8.0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          onVoiceTap!();
                        },
                        customBorder: const CircleBorder(),
                        child: Icon(
                          isListening ? Icons.mic : Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 26.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 3. Error text notification
        if (errorText != null && errorText!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 18.0,
                  color: AppDesignColors.error,
                ),
                const SizedBox(width: 4.0),
                Expanded(
                  child: Text(
                    errorText!,
                    style: const TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: AppDesignColors.error,
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
