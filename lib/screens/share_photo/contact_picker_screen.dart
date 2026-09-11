import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/contact_model.dart';
import '../../providers/media_provider.dart';
import '../../providers/system_provider.dart';
import '../../routing/routes.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/easy_button.dart';
import '../../widgets/easy_contact_tile.dart';
import '../../widgets/easy_loading.dart';
import '../../widgets/easy_snackbar.dart';

/// Screen 3 of Share Photo: Recipient Contact Picker
/// Enhanced with live text search and voice search for fast, accessible recipient selection.
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
  final TextEditingController _searchController = TextEditingController();
  bool _isVoiceSearching = false;

  @override
  void initState() {
    super.initState();
    // Fresh read on page load
    Future.microtask(() {
      ref.read(sharePhotoProvider.notifier)
        ..setSelectedImagePath(widget.imagePath)
        ..fetchWhatsAppEligibleContacts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Initiates quick voice search for recipient selection.
  Future<void> _toggleVoiceSearch() async {
    final speechService = ref.read(speechServiceProvider);
    final localization = AppLocalizations.of(context)!;

    if (_isVoiceSearching) {
      await speechService.stopListening();
      if (mounted) {
        setState(() => _isVoiceSearching = false);
      }
      return;
    }

    final hasPermission = await speechService.requestMicrophonePermission();
    if (!hasPermission) {
      if (mounted) {
        EasySnackBar.showError(context, localization.permissionMicExplanation);
      }
      return;
    }

    final initialized = await speechService.initialize(
      onStatus: (status) {
        if ((status == 'notListening' || status == 'done') && mounted) {
          setState(() => _isVoiceSearching = false);
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() => _isVoiceSearching = false);
          EasySnackBar.showError(context, err);
        }
      },
    );

    if (!initialized) {
      if (mounted) {
        EasySnackBar.showError(context, localization.generalErrorMessage);
      }
      return;
    }

    if (mounted) {
      setState(() => _isVoiceSearching = true);
    }

    await speechService.startListening(
      onResult: (words, isFinal) {
        if (mounted) {
          _searchController.text = words;
          _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: words.length),
          );
          ref.read(sharePhotoProvider.notifier).search(words);
          if (isFinal) {
            setState(() => _isVoiceSearching = false);
          }
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() => _isVoiceSearching = false);
          EasySnackBar.showError(context, err);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sharePhotoProvider);
    final notifier = ref.read(sharePhotoProvider.notifier);
    final localization = AppLocalizations.of(context)!;
    final hasSearchQuery = state.searchQuery.trim().isNotEmpty;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppDesignColors.surface,
          appBar: AppBar(
            backgroundColor: AppDesignColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: localization.backButton,
              onPressed: () {
                context.pop();
              },
            ),
            title: Text(
              localization.whoToSend,
              style: AppTypography.appName,
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // 1. Search Bar with Live 1-tap Clear and Voice Search
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppDesignColors.surfaceCard,
                            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                            border: Border.all(
                              color: _isVoiceSearching
                                  ? AppDesignColors.error
                                  : (_searchController.text.isNotEmpty
                                      ? AppDesignColors.primary
                                      : AppDesignColors.divider),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8.0,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              notifier.search(val);
                              setState(() {});
                            },
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppTypography.fontFamily,
                              color: AppDesignColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: localization.searchRecipientHint,
                              hintStyle: TextStyle(
                                color: AppDesignColors.textSecondary.withValues(alpha: 0.7),
                                fontSize: 16.0,
                                fontFamily: AppTypography.fontFamily,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppDesignColors.primary,
                                size: 26.0,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.cancel_rounded,
                                        color: AppDesignColors.textSecondary,
                                        size: 22.0,
                                      ),
                                      tooltip: localization.clearText,
                                      onPressed: () {
                                        _searchController.clear();
                                        notifier.search('');
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 14.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Voice Search Mic Button
                      Container(
                        width: 52.0,
                        height: 52.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isVoiceSearching
                              ? AppDesignColors.error
                              : AppDesignColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: (_isVoiceSearching
                                      ? AppDesignColors.error
                                      : AppDesignColors.primary)
                                  .withValues(alpha: 0.35),
                              blurRadius: 8.0,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.heavyImpact();
                              _toggleVoiceSearch();
                            },
                            customBorder: const CircleBorder(),
                            child: Icon(
                              _isVoiceSearching ? Icons.mic : Icons.mic_none_rounded,
                              color: Colors.white,
                              size: 26.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Voice Listening Indicator
                if (_isVoiceSearching)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      localization.voiceSearchListeningPrompt,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: AppDesignColors.error,
                        fontFamily: AppTypography.fontFamily,
                      ),
                    ),
                  ),

                // 2. Recipients List View / Empty State / Not Found State
                Expanded(
                  child: state.isLoading && state.allContacts.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(color: AppDesignColors.primary),
                        )
                      : state.allContacts.isEmpty && !hasSearchQuery
                          ? _buildEmptyState(context)
                          : hasSearchQuery &&
                                  state.eligibleContacts.isEmpty &&
                                  state.similarContacts.isEmpty
                              ? _buildNotFoundRecipientState(context, localization, state.searchQuery)
                              : _buildRecipientsListView(context, localization, state, notifier, hasSearchQuery),
                ),
              ],
            ),
          ),
        ),
        // Modal loading screen locks actions during compress & share routines
        if (state.isLoading && state.selectedImagePath.isNotEmpty && state.selectedContact != null)
          const EasyLoading(
            label: 'వాట్సాప్ తెరుస్తున్నాము...',
          ),
      ],
    );
  }

  /// Builds recipient tiles with primary and similar match separation.
  Widget _buildRecipientsListView(
    BuildContext context,
    AppLocalizations localization,
    SharePhotoState state,
    SharePhotoNotifier notifier,
    bool hasSearchQuery,
  ) {
    final List<Widget> items = [];

    // Exact / Primary matches
    if (state.eligibleContacts.isNotEmpty) {
      if (hasSearchQuery && state.similarContacts.isNotEmpty) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
            child: Text(
              localization.exactMatchesHeader,
              style: AppTypography.sectionHeader.copyWith(
                fontSize: 16.0,
                color: AppDesignColors.textSecondary,
              ),
            ),
          ),
        );
      }

      for (final contact in state.eligibleContacts) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: EasyContactTile(
              contact: contact,
              onTap: () => _handleRecipientSelected(context, notifier, contact),
            ),
          ),
        );
      }
    }

    // Similar matches
    if (hasSearchQuery && state.similarContacts.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppDesignColors.primary,
                size: 18.0,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                state.eligibleContacts.isEmpty
                    ? 'ఖచ్చితమైన కాంటాక్ట్ దొరకలేదు. సారూప్య కాంటాక్ట్స్:'
                    : localization.similarContactsHeader,
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: AppDesignColors.primary,
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
            ],
          ),
        ),
      );

      for (final contact in state.similarContacts) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: EasyContactTile(
              contact: contact,
              onTap: () => _handleRecipientSelected(context, notifier, contact),
            ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      children: items,
    );
  }

  Future<void> _handleRecipientSelected(
    BuildContext context,
    SharePhotoNotifier notifier,
    ContactModel contact,
  ) async {
    notifier.selectRecipient(contact);
    final bool dispatched = await notifier.dispatchWhatsAppShare();

    if (context.mounted) {
      if (dispatched) {
        EasySnackBar.showSuccess(
          context,
          'వాట్సాప్ ద్వారా పంపిస్తున్నాము',
        );
        notifier.resetState();
        context.go(AppRoutes.home);
      } else {
        EasySnackBar.showError(
          context,
          ref.read(sharePhotoProvider).errorMessage.isNotEmpty
              ? ref.read(sharePhotoProvider).errorMessage
              : 'పంపడం కుదరలేదు, వాట్సాప్ ఉందో లేదో సరిచూసుకోండి',
        );
      }
    }
  }

  /// Recipient not found screen with clear search action.
  Widget _buildNotFoundRecipientState(
    BuildContext context,
    AppLocalizations localization,
    String query,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.0,
              height: 80.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppDesignColors.primaryLight,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 44.0,
                color: AppDesignColors.primaryDark,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              localization.noContactFoundTitle,
              style: AppTypography.appName.copyWith(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '"$query" పేరుతో కాంటాక్ట్ లేదు.',
              style: AppTypography.secondaryText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppDesignColors.primary, width: 1.5),
                minimumSize: const Size(200, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              icon: const Icon(Icons.clear_all_rounded, color: AppDesignColors.primaryDark),
              label: Text(
                localization.clearSearchAction,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: AppDesignColors.primaryDark,
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
              onPressed: () {
                _searchController.clear();
                ref.read(sharePhotoProvider.notifier).search('');
                setState(() {});
              },
            ),
          ],
        ),
      ),
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
            'కాంటాక్ట్స్ ఏమీ లేవు',
            style: AppTypography.primaryLabel.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'ముందు పరిచయం సేవ్ చేయండి',
            style: AppTypography.secondaryText,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          EasyButton(
            label: 'కొత్త నంబర్ సేవ్ చేయండి',
            onPressed: () {
              context.go(AppRoutes.saveContact);
            },
          ),
        ],
      ),
    );
  }
}
