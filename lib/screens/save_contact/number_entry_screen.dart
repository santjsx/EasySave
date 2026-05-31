import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/save_contact_provider.dart';
import '../../routing/routes.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/easy_button.dart';
import '../../widgets/easy_number_pad.dart';

/// Screen 2 of Save Contact: Phone Number Dialer
/// Enforces manual entry using the letter-free circular numeric keypad (Tactile 72dp buttons).
class NumberEntryScreen extends ConsumerWidget {
  const NumberEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saveContactProvider);
    final notifier = ref.read(saveContactProvider.notifier);

    final String phoneNum = state.phoneNumber;
    final bool isCompleted = phoneNum.length == 10;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'వెనక్కి', // Accessible tooltip
          onPressed: () {
            context.pop();
          },
        ),
        title: Text(
          'నంబర్ ఎంటర్ చేయి', // Telugu: "Enter Phone Number"
          style: AppTypography.appName,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.md),
              
              // 1. Phone digits formatted blanks readout (high visual clarity)
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatPhoneNumberReadout(phoneNum),
                        style: AppTypography.numberDisplay.copyWith(
                          color: AppDesignColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '10 అంకెల నంబర్ ఎంటర్ చేయండి', // "Enter 10-digit number" in Telugu
                        style: AppTypography.secondaryText,
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Custom isolated circular keypad (Rule 16: circular digits only)
              Expanded(
                flex: 7,
                child: Center(
                  child: EasyNumberPad(
                    onDigitTap: (digit) {
                      notifier.addDigit(digit);
                    },
                    onBackspaceTap: () {
                      notifier.removeLastDigit();
                    },
                    onClearTap: () {
                      notifier.clearPhoneNumber();
                    },
                  ),
                ),
              ),

              // 3. Conditional continue button (Appears once 10 digits are complete)
              SizedBox(
                height: AppSpacing.primaryButtonHeight,
                child: isCompleted
                    ? EasyButton(
                        label: 'తర్వాత →', // Next in Telugu
                        onPressed: () {
                          // Navigate to Confirm Details View
                          context.push(AppRoutes.confirmContact);
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Visual representation formatting phone characters, replacing missing slots with high-contrast dashes
  String _formatPhoneNumberReadout(String phoneNum) {
    final List<String> characters = List.generate(10, (index) {
      if (index < phoneNum.length) {
        return phoneNum[index];
      }
      return '—'; // Clean typography dash
    });
    
    // Split into readable parts: 5 digits - space - 5 digits
    final String partA = characters.sublist(0, 5).join('');
    final String partB = characters.sublist(5, 10).join('');
    
    return '$partA $partB';
  }
}
