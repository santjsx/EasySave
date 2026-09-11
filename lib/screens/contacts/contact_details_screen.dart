import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/contact_model.dart';
import '../../providers/contacts_list_provider.dart';
import '../../routing/routes.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/easy_button.dart';
import '../../widgets/easy_snackbar.dart';

/// Dedicated full screen for viewing a single contact's details and operations.
/// Eliminates cluttered bottom sheets and nested dialogs.
class ContactDetailsScreen extends ConsumerWidget {
  final ContactModel contact;

  const ContactDetailsScreen({
    super.key,
    required this.contact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context)!;

    String formatPhone(String p) {
      final clean = p.replaceAll(RegExp(r'\s+'), '');
      if (clean.length == 10) {
        return '${clean.substring(0, 5)} ${clean.substring(5)}';
      } else if (clean.length == 13 && clean.startsWith('+91')) {
        return '+91 ${clean.substring(3, 8)} ${clean.substring(8)}';
      } else if (clean.length == 12 && clean.startsWith('91')) {
        return '+91 ${clean.substring(2, 7)} ${clean.substring(7)}';
      }
      return p;
    }

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
          onPressed: () => context.pop(),
        ),
        title: Text(
          localization.contactDetailsTitle,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.md),

              // 1. Hero Avatar & Information Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxl,
                ),
                decoration: BoxDecoration(
                  color: AppDesignColors.surfaceCard,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                    color: AppDesignColors.divider,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48.0,
                      backgroundColor: contact.avatarColor,
                      child: Text(
                        contact.name.isNotEmpty
                            ? contact.name.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 42.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTypography.fontFamily,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      contact.name,
                      style: AppTypography.confirmedName.copyWith(
                        fontSize: 28.0,
                        color: AppDesignColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      formatPhone(contact.phone),
                      style: AppTypography.numberDisplay.copyWith(
                        fontSize: 22.0,
                        letterSpacing: 1.5,
                        color: AppDesignColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // 2. Primary Action 1: Direct Call (Large Green Button)
              EasyButton(
                label: localization.callNowButton,
                icon: Icons.phone_in_talk_rounded,
                color: AppDesignColors.success,
                onPressed: () => _makePhoneCall(context),
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Primary Action 2: WhatsApp Chat (Large WhatsApp Teal Button)
              EasyButton(
                label: localization.whatsappChatButton,
                icon: Icons.chat_bubble_rounded,
                color: AppDesignColors.whatsapp,
                onPressed: () => _openWhatsAppChat(context),
              ),
              const SizedBox(height: AppSpacing.md),

              // 4. Action 3: Edit Details (Large Warm Amber Button)
              EasyButton(
                label: localization.editContactTitle,
                icon: Icons.edit_note_rounded,
                color: AppDesignColors.primary,
                onPressed: () {
                  context.push(
                    AppRoutes.contactForm,
                    extra: contact,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // 5. Action 4: Delete Contact (Accessible Red Outlined Button)
              EasyButton(
                label: localization.deleteButton,
                icon: Icons.delete_outline_rounded,
                variant: EasyButtonVariant.outlined,
                onPressed: () => _showDeleteConfirmation(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Triggers direct calling via native method channel or url_launcher fallback.
  Future<void> _makePhoneCall(BuildContext context) async {
    final localization = AppLocalizations.of(context)!;
    final status = await Permission.phone.request();
    if (status.isGranted) {
      const platform = MethodChannel('com.ammananna.app/direct_call');
      try {
        await platform.invokeMethod('makeCall', {
          'phoneNumber': contact.phone,
        });
      } catch (_) {
        final Uri phoneUri = Uri(scheme: 'tel', path: contact.phone);
        try {
          await launchUrl(phoneUri);
        } catch (_) {
          if (context.mounted) {
            EasySnackBar.showError(context, localization.callFailed);
          }
        }
      }
    } else {
      if (context.mounted) {
        EasySnackBar.showError(context, localization.callPermissionNeeded);
      }
    }
  }

  /// Direct WhatsApp chat intent opening.
  Future<void> _openWhatsAppChat(BuildContext context) async {
    final localization = AppLocalizations.of(context)!;
    final cleanDigits = contact.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final internationalPhone = cleanDigits.length == 10 ? '91$cleanDigits' : cleanDigits;

    final Uri whatsappUrl = Uri.parse('https://wa.me/$internationalPhone');
    try {
      final launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        EasySnackBar.showError(context, localization.whatsappNotInstalled);
      }
    } catch (_) {
      if (context.mounted) {
        EasySnackBar.showError(context, localization.whatsappNotInstalled);
      }
    }
  }

  /// Double confirmation dialog for safe deletion in natural daily Telugu.
  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppDesignColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: const BorderSide(color: AppDesignColors.divider, width: 1.5),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppDesignColors.error,
                size: 32.0,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                localization.deleteConfirmTitle,
                style: AppTypography.sectionHeader.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppDesignColors.error,
                ),
              ),
            ],
          ),
          content: Text(
            localization.deleteConfirmMessage,
            style: AppTypography.bodyText.copyWith(
              color: AppDesignColors.textPrimary,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.all(AppSpacing.lg),
          actions: [
            Wrap(
              spacing: 12.0,
              runSpacing: 10.0,
              alignment: WrapAlignment.end,
              children: [
                // Cancel
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(90, 48),
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    localization.cancelButton,
                    style: AppTypography.bodyText.copyWith(
                      color: AppDesignColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Delete
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppDesignColors.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    final success = await ref
                        .read(contactsListProvider.notifier)
                        .deleteContact(contact.id);

                    if (context.mounted) {
                      if (success) {
                        EasySnackBar.showSuccess(
                          context,
                          localization.contactDeletedSuccess,
                        );
                        context.pop(); // Return to Contacts List
                      } else {
                        EasySnackBar.showError(
                          context,
                          localization.generalErrorMessage,
                        );
                      }
                    }
                  },
                  child: Text(
                    localization.deleteButton,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
