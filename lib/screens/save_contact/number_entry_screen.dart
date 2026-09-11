import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/save_contact_provider.dart';
import '../../routing/routes.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/easy_button.dart';
import '../../widgets/easy_number_pad.dart';
import '../../widgets/easy_snackbar.dart';

/// Screen 2 of Save Contact: Phone Number Entry.
/// Supports flexible phone numbers (7–15 digits), 1-tap clipboard paste,
/// tactile circular number pad, and toggle for standard keyboard.
class NumberEntryScreen extends ConsumerStatefulWidget {
  const NumberEntryScreen({super.key});

  @override
  ConsumerState<NumberEntryScreen> createState() => _NumberEntryScreenState();
}

class _NumberEntryScreenState extends ConsumerState<NumberEntryScreen> {
  bool _useSystemKeyboard = false;
  late final TextEditingController _systemController;

  @override
  void initState() {
    super.initState();
    final currentPhone = ref.read(saveContactProvider).phoneNumber;
    _systemController = TextEditingController(text: currentPhone);
  }

  @override
  void dispose() {
    _systemController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      final sanitized = data.text!.replaceAll(RegExp(r'[^0-9+]'), '');
      if (sanitized.isNotEmpty) {
        final notifier = ref.read(saveContactProvider.notifier);
        notifier.clearPhoneNumber();
        for (int i = 0; i < sanitized.length; i++) {
          notifier.addDigit(sanitized[i]);
        }
        _systemController.text = sanitized;
        if (mounted) {
          EasySnackBar.showSuccess(context, 'నంబర్ పేస్ట్ అయింది');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saveContactProvider);
    final notifier = ref.read(saveContactProvider.notifier);
    final localization = AppLocalizations.of(context)!;

    final String phoneNum = state.phoneNumber;
    // Valid phone length: 7 to 15 digits
    final bool isValidLength = phoneNum.length >= 7 && phoneNum.length <= 15;

    return Scaffold(
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
          localization.enterNumber,
          style: AppTypography.appName.copyWith(
            color: AppDesignColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _useSystemKeyboard
                  ? Icons.dialpad_rounded
                  : Icons.keyboard_rounded,
              color: AppDesignColors.primaryDark,
              size: 28.0,
            ),
            tooltip: localization.keyboardToggleTooltip,
            onPressed: () {
              setState(() {
                _useSystemKeyboard = !_useSystemKeyboard;
                if (_useSystemKeyboard) {
                  _systemController.text = phoneNum;
                }
              });
            },
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Phone Readout Display
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_useSystemKeyboard) ...[
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatPhoneDisplay(phoneNum),
                            style: AppTypography.numberDisplay.copyWith(
                              fontSize: 34.0,
                              letterSpacing: 2.0,
                              color: AppDesignColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'నంబర్ ఇవ్వండి',
                              style: AppTypography.secondaryText,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            InkWell(
                              onTap: _pasteFromClipboard,
                              borderRadius: BorderRadius.circular(8.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.content_paste_rounded,
                                      size: 18.0,
                                      color: AppDesignColors.primary,
                                    ),
                                    const SizedBox(width: 4.0),
                                    Text(
                                      localization.pasteFromClipboard,
                                      style: const TextStyle(
                                        color: AppDesignColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.0,
                                        fontFamily: AppTypography.fontFamily,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        TextField(
                          controller: _systemController,
                          keyboardType: TextInputType.phone,
                          autofocus: true,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: AppDesignColors.textPrimary,
                            fontFamily: AppTypography.fontFamily,
                          ),
                          onChanged: (val) {
                            notifier.clearPhoneNumber();
                            for (int i = 0; i < val.length; i++) {
                              notifier.addDigit(val[i]);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'ఫోన్ నంబర్ ఇవ్వండి',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 2. Custom Keypad (when not using system keyboard)
              if (!_useSystemKeyboard)
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
                )
              else
                const Spacer(flex: 5),

              // 3. Continue Next Button
              SizedBox(
                height: AppSpacing.primaryButtonHeight,
                child: isValidLength
                    ? EasyButton(
                        label: '${localization.nextButton} →',
                        color: AppDesignColors.primary,
                        onPressed: () {
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

  String _formatPhoneDisplay(String p) {
    if (p.isEmpty) return '— — — — —  — — — — —';
    if (p.length == 10) {
      return '${p.substring(0, 5)} ${p.substring(5)}';
    }
    return p;
  }
}
