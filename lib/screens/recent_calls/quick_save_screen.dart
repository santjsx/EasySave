import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/quick_save_provider.dart';
import '../../services/speech_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/easy_button.dart';
import '../../widgets/easy_card.dart';
import '../../widgets/easy_microphone_button.dart';
import '../../widgets/easy_snackbar.dart';

/// Screen 2 of Recent Calls Flow: Quick Voice-Save Screen.
/// Displays a massive microphone for Telugu voice contact saving from call log entries.
class QuickSaveScreen extends ConsumerWidget {
  final String phoneNumber;

  const QuickSaveScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quickSaveProvider(phoneNumber));
    final notifier = ref.read(quickSaveProvider(phoneNumber).notifier);

    // Dynamic state checks
    final bool isListening = state.speechState == SpeechState.listening;
    final bool hasResult = state.speechState == SpeechState.result && state.recognizedName.isNotEmpty;
    final bool hasError = state.speechState == SpeechState.error;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'వెనక్కి',
          onPressed: () => context.pop(),
        ),
        title: Text(
          'కాల్ సేవ్ చేయండి', // Telugu: "Save Call"
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
              // Display the raw phone number in massive text at the top
              Text(
                phoneNumber,
                style: AppTypography.appName.copyWith(
                  color: AppDesignColors.primaryDark,
                  fontSize: 34.0,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'ఈ నంబర్‌కు పేరు ఇవ్వండి', // Telugu: "Give a name to this number"
                style: AppTypography.secondaryText.copyWith(
                  color: AppDesignColors.textSecondary,
                  fontSize: 18.0,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.lg),

              // PULSING MICROPHONE AREA
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
                      Text(
                        isListening
                            ? 'వింటున్నాము...' // Telugu: "Listening..."
                            : 'పై బటన్ నొక్కి పేరు చెప్పండి', // Telugu: "Tap mic and say name"
                        style: AppTypography.primaryLabel.copyWith(
                          color: isListening ? AppDesignColors.success : AppDesignColors.textPrimary,
                          fontSize: 24.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Speech recognition result card
              if (hasResult) ...[
                EasyCard(
                  borderColor: AppDesignColors.primary,
                  borderWidth: 2.5,
                  child: Column(
                    children: [
                      Text(
                        state.recognizedName,
                        style: AppTypography.confirmedName.copyWith(
                          color: AppDesignColors.textPrimary,
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'ఇది కరెక్టేనా?', // Telugu: "Is this correct?"
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
                              label: 'సేవ్ చేయండి', // Save in Telugu
                              onPressed: state.isSaving
                                  ? null
                                  : () async {
                                      final bool ok = await notifier.commitContact();
                                      if (ok && context.mounted) {
                                        EasySnackBar.showSuccess(context, 'నంబర్ సేవ్ అయింది'); // Contact saved
                                        context.pop(); // Returns directly to call log
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: EasyButton(
                              label: 'మళ్లీ చెప్పు', // Say again in Telugu
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
                const SizedBox(height: AppSpacing.lg),
              ],

              // Error messages feedback card
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
                onPressed: () => _showManualKeyboardEntry(context, ref, notifier),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, AppSpacing.minTouchTarget),
                ),
                child: Text(
                  'కీబోర్డ్ తో టైప్ చేయండి', // "Type with keyboard" in Telugu
                  style: AppTypography.secondaryText.copyWith(
                    decoration: TextDecoration.underline,
                    color: AppDesignColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Launches fallback dialogue and triggers direct contact persist upon keyboard entry confirm.
  void _showManualKeyboardEntry(BuildContext context, WidgetRef ref, QuickSaveNotifier notifier) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _ManualNameDialog(
          onConfirm: (typedName) async {
            notifier.setManualName(typedName);
            final bool ok = await notifier.commitContact();
            if (ok && context.mounted) {
              EasySnackBar.showSuccess(context, 'నంబర్ సేవ్ అయింది'); // Contact saved
              context.pop(); // Close dialog or navigate back
            }
          },
        );
      },
    );
  }
}

/// Private stateful manual entry dialogue to cleanly secure TextEditingController lifecycle.
class _ManualNameDialog extends StatefulWidget {
  final Function(String typedName) onConfirm;

  const _ManualNameDialog({required this.onConfirm});

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
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'పేరు టైప్ చేయండి', // Telugu: "Type the name"
        style: AppTypography.sectionHeader.copyWith(fontSize: 22.0),
      ),
      content: TextField(
        controller: _textController,
        autofocus: true,
        style: AppTypography.bodyText.copyWith(fontSize: 18.0),
        decoration: InputDecoration(
          hintText: 'రవి కుమార్',
          hintStyle: AppTypography.hintText.copyWith(fontSize: 18.0),
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
            'వెనక్కి',
            style: AppTypography.secondaryText.copyWith(fontSize: 18.0),
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
            'సరే',
            style: AppTypography.buttonText.copyWith(fontSize: 20),
          ),
        ),
      ],
    );
  }
}
