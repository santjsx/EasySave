import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/save_contact_provider.dart';
import '../../routing/routes.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/easy_button.dart';

/// Screen 4 of Save Contact: Success notification views.
/// Enforces Rule 15: Timed auto-dismissal back to home after exactly 2500ms.
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

    // Enforce Rule 15: Trigger 2500ms timer to return to Home dashboard
    _dismissTimer = Timer(const Duration(milliseconds: 2500), () {
      _returnToHome();
    });
  }

  @override
  void dispose() {
    // Enforce Rule 15: Cancel timer explicitly on dispose to prevent leaks
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _returnToHome() {
    if (mounted) {
      // Clear wizard registers in Riverpod
      ref.read(saveContactProvider.notifier).resetWizard();
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saveContactProvider);

    return Scaffold(
      backgroundColor: AppDesignColors.successLight, // Warm green success tint
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
              // 1. Success check circle indicator (80dp)
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
              // 2. High visibility success titles
              Text(
                'సేవ్ అయింది!', // "Saved!" in Telugu
                style: AppTypography.successHeading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // 3. Render saved details card
              Text(
                state.recognizedName,
                style: AppTypography.confirmedName.copyWith(
                  color: AppDesignColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatPhoneNumber(state.phoneNumber),
                style: AppTypography.sectionHeader.copyWith(
                  color: AppDesignColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              
              // 4. Manual override home exit button
              EasyButton(
                label: 'హోమ్ కి వెళ్ళు', // "Go to Home" in Telugu
                onPressed: _returnToHome,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPhoneNumber(String raw) {
    if (raw.length != 10) return raw;
    final String partA = raw.substring(0, 5);
    final String partB = raw.substring(5, 10);
    return '+91 $partA $partB';
  }
}
