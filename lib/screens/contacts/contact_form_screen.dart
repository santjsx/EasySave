import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/contact_model.dart';
import '../../providers/contacts_list_provider.dart';
import '../../providers/system_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/easy_button.dart';
import '../../widgets/easy_snackbar.dart';
import '../../widgets/easy_text_field.dart';

/// Dedicated full screen for creating or editing contact details.
/// Replaces cramped nested alert dialogs with a calm, focused form.
class ContactFormScreen extends ConsumerStatefulWidget {
  final ContactModel? contactToEdit;
  final String? initialPhone;

  const ContactFormScreen({
    super.key,
    this.contactToEdit,
    this.initialPhone,
  });

  @override
  ConsumerState<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends ConsumerState<ContactFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  bool _isListening = false;
  bool _isSaving = false;
  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.contactToEdit?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.contactToEdit?.phone ?? widget.initialPhone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Toggles speech recognition directly into the name field.
  Future<void> _toggleVoiceInput() async {
    final speechService = ref.read(speechServiceProvider);

    if (_isListening) {
      await speechService.stopListening();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    final hasPermission = await speechService.requestMicrophonePermission();
    if (!hasPermission) {
      if (mounted) {
        EasySnackBar.showError(
          context,
          AppLocalizations.of(context)!.permissionMicExplanation,
        );
      }
      return;
    }

    final initialized = await speechService.initialize(
      onStatus: (status) {
        if ((status == 'notListening' || status == 'done') && mounted) {
          setState(() => _isListening = false);
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() => _isListening = false);
          EasySnackBar.showError(context, err);
        }
      },
    );

    if (!initialized) {
      if (mounted) {
        EasySnackBar.showError(
          context,
          AppLocalizations.of(context)!.generalErrorMessage,
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isListening = true;
        _nameError = null;
      });
    }

    await speechService.startListening(
      onResult: (words, isFinal) {
        if (mounted) {
          setState(() {
            _nameController.text = words;
            _nameController.selection = TextSelection.fromPosition(
              TextPosition(offset: words.length),
            );
            if (isFinal) {
              _isListening = false;
            }
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() => _isListening = false);
          EasySnackBar.showError(context, err);
        }
      },
    );
  }

  /// 1-tap clipboard paste directly into the phone field.
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      final sanitized = data.text!.replaceAll(RegExp(r'[^0-9+]'), '');
      if (sanitized.isNotEmpty) {
        setState(() {
          _phoneController.text = sanitized;
          _phoneController.selection = TextSelection.fromPosition(
            TextPosition(offset: sanitized.length),
          );
          _phoneError = null;
        });
        if (mounted) {
          EasySnackBar.showSuccess(context, 'నంబర్ పేస్ట్ అయింది');
        }
      }
    }
  }

  /// Validates and saves or updates the contact.
  Future<void> _handleSave() async {
    final localization = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim().replaceAll(RegExp(r'[\s-]'), '');

    setState(() {
      _nameError = name.isEmpty ? localization.invalidNameError : null;
      _phoneError = phone.length < 7 ? localization.invalidPhoneError : null;
    });

    if (_nameError != null || _phoneError != null) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.contactToEdit != null) {
        // Edit flow
        final success = await ref
            .read(contactsListProvider.notifier)
            .updateContact(widget.contactToEdit!.id, name, phone);

        if (mounted) {
          setState(() => _isSaving = false);
          if (success) {
            EasySnackBar.showSuccess(context, localization.contactUpdatedSuccess);
            context.pop(); // Return to details screen or previous
          } else {
            EasySnackBar.showError(context, localization.generalErrorMessage);
          }
        }
      } else {
        // New contact flow
        final contactsService = ref.read(contactsServiceProvider);
        final success = await contactsService.saveContact(name, phone);
        await ref.read(contactsListProvider.notifier).fetchContacts();

        if (mounted) {
          setState(() => _isSaving = false);
          if (success) {
            EasySnackBar.showSuccess(context, localization.contactSavedToast);
            context.pop();
          } else {
            EasySnackBar.showError(context, localization.generalErrorMessage);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        EasySnackBar.showError(context, localization.generalErrorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final isEditing = widget.contactToEdit != null;

    return Scaffold(
      backgroundColor: AppDesignColors.surface,
      appBar: AppBar(
        backgroundColor: AppDesignColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppDesignColors.textPrimary,
            size: 28.0,
          ),
          tooltip: localization.backButton,
          onPressed: () {
            if (_isListening) {
              ref.read(speechServiceProvider).stopListening();
            }
            context.pop();
          },
        ),
        title: Text(
          isEditing ? localization.editContactTitle : localization.addContactTitle,
          style: AppTypography.appName.copyWith(
            color: AppDesignColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),

              // 1. Name Input Field with 1-Tap Voice Microphone
              EasyTextField(
                controller: _nameController,
                label: localization.editNameLabel,
                hintText: 'పేరు చెప్పండి లేదా టైప్ చేయండి...',
                isListening: _isListening,
                onVoiceTap: _toggleVoiceInput,
                errorText: _nameError,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),

              if (_isListening) ...[
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    localization.listeningLabel,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: AppDesignColors.primary,
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              // 2. Phone Input Field with 1-Tap Clipboard Paste
              EasyTextField(
                controller: _phoneController,
                label: localization.editPhoneLabel,
                hintText: 'ఉదాహరణ: 9876543210',
                keyboardType: TextInputType.phone,
                onPasteTap: _pasteFromClipboard,
                errorText: _phoneError,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d+\s-]')),
                ],
                onChanged: (_) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // 3. Save Button
              EasyButton(
                label: _isSaving ? 'సేవ్ అవుతోంది...' : localization.saveButton,
                icon: Icons.check_circle_rounded,
                color: AppDesignColors.primary,
                onPressed: _isSaving ? null : _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
