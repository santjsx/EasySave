import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/media_provider.dart';
import '../../routing/routes.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/easy_button.dart';
import '../../widgets/easy_contact_tile.dart';
import '../../widgets/easy_loading.dart';
import '../../widgets/easy_snackbar.dart';

/// Screen 3 of Share Photo: Recipient Contact Picker
/// Lists Telugu contacts using the high-contrast 72dp lists items.
class ContactPickerScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const ContactPickerScreen({
    super.key,
    required this.imagePath,
  });

  @override
  ConsumerState<ContactPickerScreen> createState() => _ContactPickerScreenState();
}

class _ContactPickerScreenState extends ConsumerState<ContactPickerScreen> {
  @override
  void initState() {
    super.initState();
    // Enforce Rule 11: Fresh read on page load
    Future.microtask(() {
      ref.read(sharePhotoProvider.notifier)
        ..setSelectedImagePath(widget.imagePath)
        ..fetchWhatsAppEligibleContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sharePhotoProvider);
    final notifier = ref.read(sharePhotoProvider.notifier);

    final bool isEmpty = state.eligibleContacts.isEmpty;

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
              'ఎవరికి పంపించాలి?', // Telugu: "Who to send to?"
              style: AppTypography.appName,
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: state.isLoading && state.eligibleContacts.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : isEmpty
                      ? _buildEmptyState(context)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ఎవరికి పంపించాలో ఎంచుకోండి:', // Telugu: "Select who to send to:"
                              style: AppTypography.sectionHeader.copyWith(
                                color: AppDesignColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            // Virtualized list builder representing fresh native rows
                            Expanded(
                              child: ListView.builder(
                                itemCount: state.eligibleContacts.length,
                                itemBuilder: (context, index) {
                                  final contact = state.eligibleContacts[index];
                                  return EasyContactTile(
                                    contact: contact,
                                    onTap: () async {
                                      // 1. Bind target recipient
                                      notifier.selectRecipient(contact);

                                      // 2. Perform direct WhatsApp intent share
                                      final bool dispatched = await notifier.dispatchWhatsAppShare();

                                      if (context.mounted) {
                                        if (dispatched) {
                                          EasySnackBar.showSuccess(
                                            context,
                                            'వాట్సాప్ ద్వారా పంపిస్తున్నాము', // "Sending via WhatsApp" in Telugu
                                          );
                                          // Clear media stack and return back to Home dashboard
                                          notifier.resetState();
                                          context.go(AppRoutes.home);
                                        } else {
                                          // Trigger specific warning snackbar if packages are missing
                                          EasySnackBar.showError(
                                            context,
                                            state.errorMessage.isNotEmpty
                                                ? state.errorMessage
                                                : 'పంపడం కుదరలేదు, వాట్సాప్ ఉందో లేదో సరిచూసుకోండి',
                                          );
                                        }
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
        // Modal loading screen locks actions during compress & share routines
        if (state.isLoading && state.selectedImagePath.isNotEmpty && state.selectedContact != null)
          const EasyLoading(
            label: 'వాట్సాప్ తెరుస్తున్నాము...', // "Opening WhatsApp..." in Telugu
          ),
      ],
    );
  }

  /// Illustrated empty state shown when address book holds zero profiles
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ExcludeSemantics(
            child: Icon(
              Icons.people_outline_rounded,
              size: 80.0,
              color: AppDesignColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'కాంటాక్ట్స్ ఏమీ లేవు', // "Contacts not found" in Telugu
            style: AppTypography.primaryLabel.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'ముందు పరిచయం సేవ్ చేయండి', // "Save a contact first" in Telugu
            style: AppTypography.secondaryText,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          EasyButton(
            label: 'కొత్త నంబర్ సేవ్ చేయండి', // Telugu button label
            onPressed: () {
              // Redirect directly to the voice-first Save Contact flow
              context.go(AppRoutes.saveContact);
            },
          ),
        ],
      ),
    );
  }
}
