import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
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
    final localization = AppLocalizations.of(context)!;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppDesignColors.surface,
          appBar: AppBar(
            backgroundColor: AppDesignColors.surface,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: localization.backButton,
              onPressed: () => context.pop(),
            ),
            title: Text(
              localization.confirmLabel,
              style: AppTypography.appName.copyWith(
                color: AppDesignColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
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
                            fontSize: 30.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _formatPhoneNumber(state.phoneNumber),
                          style: AppTypography.numberDisplay.copyWith(
                            fontSize: 26.0,
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
                    label: localization.saveButton,
                    color: AppDesignColors.primary,
                    onPressed: () async {
                      final bool success = await notifier.commitContact();

                      if (context.mounted) {
                        if (success) {
                          context.push(AppRoutes.saveSuccess);
                        } else {
                          EasySnackBar.showError(
                            context,
                            state.errorMessage.isNotEmpty
                                ? state.errorMessage
                                : localization.generalErrorMessage,
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
            label: 'సేవ్ చేస్తున్నాము...',
          ),
      ],
    );
  }

  String _formatPhoneNumber(String raw) {
    if (raw.length == 10) {
      final String partA = raw.substring(0, 5);
      final String partB = raw.substring(5, 10);
      return '+91 $partA $partB';
    }
    return raw;
  }
}
