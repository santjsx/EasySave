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
import '../../widgets/easy_snackbar.dart';

/// Screen 1 of Save Contact: Voice Name Entry
/// Guides the user to tap the pulsing microphone and speak the name in Telugu.
class VoiceNameScreen extends ConsumerWidget {
  const VoiceNameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(saveContactProvider);
    final notifier = ref.read(saveContactProvider.notifier);

    // Dynamic state evaluation
    final bool isListening = state.speechState == SpeechState.listening;
    final bool hasResult = state.speechState == SpeechState.result && state.recognizedName.isNotEmpty;
    final bool hasError = state.speechState == SpeechState.error;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'వెనక్కి', // Accessible tooltip
          onPressed: () {
            notifier.resetWizard();
            context.pop();
          },
        ),
        title: Text(
          'పేరు చెప్పండి', // Telugu: "Speak the Name"
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
                            ? 'వింటున్నాము...' // "Listening..." in Telugu
                            : 'పై బటన్ నొక్కి పేరు చెప్పండి', // "Tap mic and say name" in Telugu
                        style: AppTypography.primaryLabel.copyWith(
                          color: isListening ? AppDesignColors.success : AppDesignColors.textPrimary,
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
                            color: AppDesignColors.primaryLight.withValues(alpha: 0.4),
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
                                AppLocalizations.of(context)!.hearingLabel,
                                style: AppTypography.secondaryText.copyWith(
                                  color: AppDesignColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                state.recognizedName,
                                style: AppTypography.confirmedName.copyWith(
                                  color: AppDesignColors.primaryDark,
                                  fontWeight: FontWeight.bold,
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
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'ఇది కరెక్టేనా?', // Telugu: "Is this correct?"
                        style: AppTypography.sectionHeader.copyWith(
                          color: AppDesignColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: EasyButton(
                              label: 'అవును', // Yes in Telugu
                              onPressed: () {
                                // Navigate to Dialer Keypad Screen
                                context.push(AppRoutes.numberEntry);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: EasyButton(
                              label: 'మళ్ళీ చెప్పండి', // Retry in Telugu
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
                          state.errorMessage.isNotEmpty ? state.errorMessage : 'అర్థం కాలేదు, మళ్ళీ చెప్పండి',
                          style: AppTypography.bodyText.copyWith(color: AppDesignColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              const Spacer(),
              // Fallback Keyboard Entry trigger (satisfies PRD fallbacks)
              TextButton(
                onPressed: () => _showManualKeyboardEntry(context, ref),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, AppSpacing.minTouchTarget),
                ),
                child: Text(
                  'కీబోర్డ్ తో టైప్ చేయండి', // "Type with keyboard" in Telugu
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

  /// Launches a custom text entry dialog allowing Telugu keyboard input (Fallback)
  void _showManualKeyboardEntry(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ManualNameDialog(
          onConfirm: (typedName) {
            ref.read(saveContactProvider.notifier).setManualName(typedName);
            // Pushes direct to dialer screen
            context.push(AppRoutes.numberEntry);
          },
        );
      },
    );
  }
}

/// Private stateful widget to securely manage TextEditingController's lifecycle and prevent memory leaks.
class _ManualNameDialog extends StatefulWidget {
  final Function(String typedName) onConfirm;

  const _ManualNameDialog({
    required this.onConfirm,
  });

  @override
  State<_ManualNameDialog> createState() => _ManualNameDialogState();
}

class _ManualNameDialogState extends State<_ManualNameDialog> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose(); // Securely dispose controller to prevent leaks!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'పేరు టైప్ చేయండి', // Telugu: "Type the name"
        style: AppTypography.sectionHeader,
      ),
      content: TextField(
        controller: _textController,
        autofocus: true,
        style: AppTypography.bodyText,
        decoration: InputDecoration(
          hintText: 'రవి కుమార్', // Example in Telugu script
          hintStyle: AppTypography.hintText,
          fillColor: AppDesignColors.surfaceMuted,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            borderSide: BorderSide.none,
          ),
        ),
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'వెనక్కి', // Back in Telugu
            style: AppTypography.secondaryText,
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(120, 56),
            backgroundColor: AppDesignColors.primary,
          ),
          onPressed: () {
            final typedName = _textController.text.trim();
            if (typedName.isNotEmpty) {
              Navigator.of(context).pop();
              widget.onConfirm(typedName);
            } else {
              EasySnackBar.showError(context, 'సరైన పేరు ఇవ్వండి');
            }
          },
          child: Text(
            'సరే', // OK in Telugu
            style: AppTypography.buttonText.copyWith(fontSize: 20),
          ),
        ),
      ],
    );
  }
}
