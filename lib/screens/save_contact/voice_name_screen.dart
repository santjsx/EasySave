import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/save_contact_provider.dart';
import '../../routing/routes.dart';
import '../../services/speech_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/easy_button.dart';
import '../../widgets/easy_card.dart';
import '../../widgets/easy_microphone_button.dart';

/// Screen 1 of Save Contact: Voice Name Entry.
/// Guides the user to tap the pulsing microphone and speak the name in natural daily Telugu.
class VoiceNameScreen extends ConsumerWidget {
  const VoiceNameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saveContactProvider);
    final notifier = ref.read(saveContactProvider.notifier);
    final localization = AppLocalizations.of(context)!;

    // Dynamic state evaluation
    final bool isListening = state.speechState == SpeechState.listening;
    final bool hasResult = state.speechState == SpeechState.result && state.recognizedName.isNotEmpty;
    final bool hasError = state.speechState == SpeechState.error;

    return Scaffold(
      backgroundColor: AppDesignColors.surface,
      appBar: AppBar(
        backgroundColor: AppDesignColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: localization.backButton,
          onPressed: () {
            notifier.resetWizard();
            context.pop();
          },
        ),
        title: Text(
          localization.speakName,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Main Microphone Pulser Area
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EasyMicrophoneButton(
                        isListening: isListening,
                        onTap: () {
                          if (isListening) {
                            notifier.stopListeningName();
                          } else {
                            notifier.startListeningName();
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Instruction label changes reactively
                      Text(
                        isListening
                            ? localization.listeningLabel
                            : localization.pressMicPrompt,
                        style: AppTypography.primaryLabel.copyWith(
                          color: isListening
                              ? AppDesignColors.success
                              : AppDesignColors.textPrimary,
                          fontSize: 24.0,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Live speech recognition feedback
                      if (isListening && state.recognizedName.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: AppDesignColors.primaryLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(
                              color: AppDesignColors.primary.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                localization.hearingLabel,
                                style: AppTypography.secondaryText.copyWith(
                                  color: AppDesignColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.0,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                state.recognizedName,
                                style: AppTypography.confirmedName.copyWith(
                                  color: AppDesignColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Recognized result card displays once captured successfully
              if (hasResult)
                EasyCard(
                  borderColor: AppDesignColors.primary,
                  borderWidth: 2.0,
                  child: Column(
                    children: [
                      Text(
                        state.recognizedName,
                        style: AppTypography.confirmedName.copyWith(
                          color: AppDesignColors.textPrimary,
                          fontSize: 30.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        localization.isCorrectQuestion,
                        style: AppTypography.sectionHeader.copyWith(
                          color: AppDesignColors.textSecondary,
                          fontSize: 20.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: EasyButton(
                              label: localization.yesButton,
                              color: AppDesignColors.primary,
                              onPressed: () {
                                context.push(AppRoutes.numberEntry);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: EasyButton(
                              label: localization.tryAgainButton,
                              variant: EasyButtonVariant.outlined,
                              onPressed: () {
                                notifier.resetVoiceName();
                                notifier.startListeningName();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Error notification feedback card
              if (hasError) ...[
                EasyCard(
                  backgroundColor: AppDesignColors.errorLight,
                  borderColor: AppDesignColors.error,
                  child: Row(
                    children: [
                      const ExcludeSemantics(
                        child: Icon(Icons.warning_amber_rounded, color: AppDesignColors.error, size: 36),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          state.errorMessage.isNotEmpty
                              ? state.errorMessage
                              : localization.speechNotRecognized,
                          style: AppTypography.bodyText.copyWith(
                            color: AppDesignColors.error,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              const Spacer(),

              // Fallback Keyboard Entry trigger
              TextButton(
                onPressed: () => _showManualKeyboardEntry(context, ref),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, AppSpacing.minTouchTarget),
                ),
                child: Text(
                  localization.typeWithKeyboard,
                  style: AppTypography.secondaryText.copyWith(
                    decoration: TextDecoration.underline,
                    color: AppDesignColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualKeyboardEntry(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ManualNameDialog(
          onConfirm: (typedName) {
            ref.read(saveContactProvider.notifier).setManualName(typedName);
            context.push(AppRoutes.numberEntry);
          },
        );
      },
    );
  }
}

class _ManualNameDialog extends StatefulWidget {
  final Function(String typedName) onConfirm;

  const _ManualNameDialog({required this.onConfirm});

  @override
  State<_ManualNameDialog> createState() => _ManualNameDialogState();
}

class _ManualNameDialogState extends State<_ManualNameDialog> {
  late final TextEditingController _nameTextController;

  @override
  void initState() {
    super.initState();
    _nameTextController = TextEditingController();
  }

  @override
  void dispose() {
    _nameTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: AppDesignColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: const BorderSide(color: AppDesignColors.divider, width: 1.5),
      ),
      title: Text(
        localization.editNameLabel,
        style: AppTypography.sectionHeader.copyWith(
          fontWeight: FontWeight.bold,
          color: AppDesignColors.textPrimary,
        ),
      ),
      content: TextField(
        controller: _nameTextController,
        autofocus: true,
        style: const TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          fontFamily: AppTypography.fontFamily,
        ),
        decoration: InputDecoration(
          hintText: localization.invalidNameError,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            localization.cancelButton,
            style: const TextStyle(
              fontSize: 18.0,
              color: AppDesignColors.textSecondary,
              fontFamily: AppTypography.fontFamily,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppDesignColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onPressed: () {
            final name = _nameTextController.text.trim();
            if (name.isNotEmpty) {
              Navigator.of(context).pop();
              widget.onConfirm(name);
            }
          },
          child: Text(
            localization.nextButton,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              fontFamily: AppTypography.fontFamily,
            ),
          ),
        ),
      ],
    );
  }
}
