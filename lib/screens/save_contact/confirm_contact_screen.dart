import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/save_contact_provider.dart';
import '../../routing/routes.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/easy_button.dart';
import '../../widgets/easy_card.dart';
import '../../widgets/easy_loading.dart';
import '../../widgets/easy_snackbar.dart';

/// Screen 3 of Save Contact: Final verification before committing to Android DB.
class ConfirmContactScreen extends ConsumerWidget {
  const ConfirmContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saveContactProvider);
    final notifier = ref.read(saveContactProvider.notifier);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: 'వెనక్కి', // Accessible tooltip
              onPressed: () {
                context.pop();
              },
            ),
            title: Text(
              'సరిచూసుకోండి', // Telugu: "Confirm details"
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
                children: [
                  const Spacer(),
                  // 1. High contrast summary card containing person details
                  EasyCard(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    borderColor: AppDesignColors.primary,
                    borderWidth: 2.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ExcludeSemantics(
                          child: Icon(
                            Icons.account_circle,
                            size: 80.0,
                            color: AppDesignColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          state.recognizedName,
                          style: AppTypography.confirmedName.copyWith(
                            color: AppDesignColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _formatPhoneNumber(state.phoneNumber),
                          style: AppTypography.numberDisplay.copyWith(
                            fontSize: 32.0,
                            color: AppDesignColors.textSecondary,
                            letterSpacing: 2.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // 2. Commit save action button
                  EasyButton(
                    label: 'సేవ్ చేయండి', // Save in Telugu script
                    onPressed: () async {
                      final bool success = await notifier.commitContact();
                      
                      if (context.mounted) {
                        if (success) {
                          // Clean flow: navigate to Success screen
                          context.push(AppRoutes.saveSuccess);
                        } else {
                          // Display specific error message using localized snackbars
                          EasySnackBar.showError(
                            context,
                            state.errorMessage.isNotEmpty
                                ? state.errorMessage
                                : 'సేవ్ చేయడం కుదరలేదు, మళ్ళీ ప్రయత్నించండి',
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        // Overlays modal loading block during async write process
        if (state.isSaving)
          const EasyLoading(
            label: 'సేవ్ చేస్తున్నాము...', // "Saving..." in Telugu
          ),
      ],
    );
  }

  /// Splitting string for high readability: +91 XXXXX XXXXX (or XXXXX XXXXX)
  String _formatPhoneNumber(String raw) {
    if (raw.length != 10) return raw;
    final String partA = raw.substring(0, 5);
    final String partB = raw.substring(5, 10);
    return '+91 $partA $partB';
  }
}
