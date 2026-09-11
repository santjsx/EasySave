import 'dart:async';
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

/// Screen 4 of Save Contact: Success notification views.
/// Features high-contrast checkmark and auto-dismissal back to home after 2500ms.
class SaveContactSuccessScreen extends ConsumerStatefulWidget {
  const SaveContactSuccessScreen({super.key});

  @override
  ConsumerState<SaveContactSuccessScreen> createState() => _SaveContactSuccessScreenState();
}

class _SaveContactSuccessScreenState extends ConsumerState<SaveContactSuccessScreen> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(const Duration(milliseconds: 2500), () {
      _returnToHome();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _returnToHome() {
    if (mounted) {
      ref.read(saveContactProvider.notifier).resetWizard();
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saveContactProvider);
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppDesignColors.successLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // 1. Success check circle indicator
              Container(
                width: 120.0,
                height: 120.0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const ExcludeSemantics(
                  child: Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 96.0,
                      color: AppDesignColors.success,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 2. High visibility success title
              Text(
                localization.savedSuccess,
                style: AppTypography.successHeading.copyWith(
                  fontSize: 34.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. Render saved details
              Text(
                state.recognizedName,
                style: AppTypography.confirmedName.copyWith(
                  color: AppDesignColors.textPrimary,
                  fontSize: 30.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatPhoneNumber(state.phoneNumber),
                style: AppTypography.sectionHeader.copyWith(
                  color: AppDesignColors.textSecondary,
                  fontSize: 22.0,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // 4. Manual override home exit button
              EasyButton(
                label: localization.goHome,
                color: AppDesignColors.success,
                onPressed: _returnToHome,
              ),
            ],
          ),
        ),
      ),
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
