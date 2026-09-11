import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/contact_model.dart';
import '../../providers/contacts_list_provider.dart';
import '../../providers/system_provider.dart';
import '../../routing/routes.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/easy_snackbar.dart';
import '../../services/call_service.dart';

/// Clean, high-performance Contacts Directory screen for EasySave.
/// Provides Telugu alphabetical collation, live search, voice search,
/// fuzzy/similar contact discovery, and dedicated Contact Details/Form routing.
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isVoiceSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Toggles voice search using speech recognition with silence watchdog auto-commit.
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
          ref.read(contactsListProvider.notifier).search(words);
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
    final contactsState = ref.watch(contactsListProvider);
    final localization = AppLocalizations.of(context)!;
    final hasSearchQuery = contactsState.searchQuery.trim().isNotEmpty;

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
          localization.viewMyContacts,
          style: AppTypography.appName.copyWith(
            color: AppDesignColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              color: AppDesignColors.primary,
              size: 32.0,
            ),
            tooltip: localization.saveContactLabel,
            onPressed: () => context.push(AppRoutes.contactForm),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
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
                          ref.read(contactsListProvider.notifier).search(val);
                          setState(() {});
                        },
                        style: const TextStyle(
                          fontSize: 19.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: AppTypography.fontFamily,
                          color: AppDesignColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: localization.searchContactsHint,
                          hintStyle: TextStyle(
                            color: AppDesignColors.textSecondary.withValues(alpha: 0.7),
                            fontSize: 17.0,
                            fontFamily: AppTypography.fontFamily,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppDesignColors.primary,
                            size: 28.0,
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
                                    ref.read(contactsListProvider.notifier).search('');
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 16.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Tactile Voice Search Mic Button
                  Container(
                    width: 54.0,
                    height: 54.0,
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
                          blurRadius: 10.0,
                          offset: const Offset(0, 4),
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
                          size: 28.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Real-time Voice Search Listening Banner
            if (_isVoiceSearching)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10.0,
                      height: 10.0,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppDesignColors.error,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      localization.voiceSearchListeningPrompt,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppDesignColors.error,
                        fontFamily: AppTypography.fontFamily,
                      ),
                    ),
                  ],
                ),
              ),

            // 2. Contacts List View / Empty State / Not Found State
            Expanded(
              child: contactsState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppDesignColors.primary,
                        strokeWidth: 4.0,
                      ),
                    )
                  : contactsState.errorMessage.isNotEmpty
                      ? _buildErrorPlaceholder(contactsState.errorMessage)
                      : contactsState.contacts.isEmpty && !hasSearchQuery
                          ? _buildEmptyAddressBookPlaceholder(context, localization)
                          : hasSearchQuery &&
                                  contactsState.filteredContacts.isEmpty &&
                                  contactsState.similarContacts.isEmpty
                              ? _buildNotFoundScreen(context, localization, contactsState.searchQuery)
                              : RefreshIndicator(
                                  color: AppDesignColors.primary,
                                  onRefresh: () => ref
                                      .read(contactsListProvider.notifier)
                                      .fetchContacts(),
                                  child: _buildContactsListView(
                                    context,
                                    localization,
                                    contactsState,
                                    hasSearchQuery,
                                  ),
                                ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the contacts list items including primary matches and similar contact recommendations.
  Widget _buildContactsListView(
    BuildContext context,
    AppLocalizations localization,
    ContactsListState state,
    bool hasSearchQuery,
  ) {
    final List<Widget> items = [];

    // Exact / Primary matches section
    if (state.filteredContacts.isNotEmpty) {
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

      for (final contact in state.filteredContacts) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildContactTile(context, contact),
          ),
        );
      }
    }

    // Similar / Fuzzy matches section
    if (hasSearchQuery && state.similarContacts.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppDesignColors.primary,
                size: 20.0,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                state.filteredContacts.isEmpty
                    ? localization.noExactMatchesPrefix
                    : localization.similarContactsHeader,
                style: const TextStyle(
                  fontSize: 16.0,
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
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildContactTile(context, contact, isSimilar: true),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      children: items,
    );
  }

  /// Builds an accessible, tactile contact list tile that navigates to dedicated ContactDetailsScreen.
  Widget _buildContactTile(
    BuildContext context,
    ContactModel contact, {
    bool isSimilar = false,
  }) {
    final localization = AppLocalizations.of(context)!;

    String formatPhone(String p) {
      final clean = p.replaceAll(RegExp(r'\s+'), '');
      if (clean.startsWith('+91') && clean.length == 13) {
        return '+91 ${clean.substring(3, 8)} ${clean.substring(8)}';
      }
      if (clean.startsWith('0') && clean.length == 11) {
        return '${clean.substring(0, 5)} ${clean.substring(5)}';
      }
      if (clean.length == 10) {
        return '${clean.substring(0, 5)} ${clean.substring(5)}';
      }
      return p;
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 76.0),
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: isSimilar
              ? AppDesignColors.primary.withValues(alpha: 0.4)
              : AppDesignColors.divider,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push(
              AppRoutes.contactDetails,
              extra: contact,
            );
          },
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                // Avatar with initial letter
                CircleAvatar(
                  radius: 28.0,
                  backgroundColor: contact.avatarColor,
                  child: Text(
                    contact.name.isNotEmpty
                        ? contact.name.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 24.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Name and Phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contact.name,
                              style: const TextStyle(
                                color: AppDesignColors.textPrimary,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppTypography.fontFamily,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSimilar)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppDesignColors.primaryLight,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                localization.similarBadge,
                                style: const TextStyle(
                                   fontSize: 11.0,
                                   fontWeight: FontWeight.bold,
                                   color: AppDesignColors.primary,
                                   fontFamily: AppTypography.fontFamily,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        formatPhone(contact.phone),
                        style: const TextStyle(
                          color: AppDesignColors.textSecondary,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppTypography.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),

                // 1-Click Direct Call Action Button (Tactile Green)
                Tooltip(
                  message: localization.callButtonTooltip,
                  child: Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: AppDesignColors.successLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppDesignColors.success.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          ref.read(callServiceProvider).makeCall(context, contact.phone);
                        },
                        child: const Icon(
                          Icons.phone_in_talk_rounded,
                          color: AppDesignColors.success,
                          size: 24.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Industry-grade empathetic Contact Not Found screen with suggestions and 1-tap actions.
  Widget _buildNotFoundScreen(
    BuildContext context,
    AppLocalizations localization,
    String query,
  ) {
    final bool isPhoneQuery = RegExp(r'^\+?[\d\s-]+$').hasMatch(query.trim()) &&
        query.replaceAll(RegExp(r'\D'), '').length >= 6;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Search Off Illustration Badge
          Center(
            child: Container(
              width: 96.0,
              height: 96.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppDesignColors.primaryLight,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 52.0,
                color: AppDesignColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Primary Not Found Headline
          Text(
            localization.noContactFoundTitle,
            style: AppTypography.appName.copyWith(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: AppDesignColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),

          // User query explanation
          Text(
            '"$query" పేరుతో లేదా నంబర్‌తో కాంటాక్ట్ లేదు.',
            style: AppTypography.bodyText.copyWith(
              fontSize: 17.0,
              color: AppDesignColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Helpful Tips Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppDesignColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppDesignColors.divider, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppDesignColors.primaryDark,
                      size: 22.0,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      localization.searchTipsTitle,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppDesignColors.textPrimary,
                        fontFamily: AppTypography.fontFamily,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        localization.searchTip1,
                        style: const TextStyle(
                          fontSize: 15.0,
                          color: AppDesignColors.textSecondary,
                          fontFamily: AppTypography.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        localization.searchTip2,
                        style: const TextStyle(
                          fontSize: 15.0,
                          color: AppDesignColors.textSecondary,
                          fontFamily: AppTypography.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Action 1: Save As New Contact with pre-filled query
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.person_add_rounded, size: 24.0),
            label: Text(
              localization.saveAsNewContactAction,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                fontFamily: AppTypography.fontFamily,
              ),
            ),
            onPressed: () {
              if (isPhoneQuery) {
                context.push(
                  '${AppRoutes.contactForm}?phone=${Uri.encodeComponent(query.trim())}',
                );
              } else {
                context.push(
                  '${AppRoutes.contactForm}?name=${Uri.encodeComponent(query.trim())}',
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Action 2: Clear Search Filter
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppDesignColors.divider, width: 1.5),
              minimumSize: const Size(double.infinity, 50.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
            ),
            icon: const Icon(Icons.clear_all_rounded, color: AppDesignColors.textPrimary, size: 22.0),
            label: Text(
              localization.clearSearchAction,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: AppDesignColors.textPrimary,
                fontFamily: AppTypography.fontFamily,
              ),
            ),
            onPressed: () {
              _searchController.clear();
              ref.read(contactsListProvider.notifier).search('');
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppDesignColors.error,
              size: 54.0,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.sectionHeader.copyWith(
                fontWeight: FontWeight.bold,
                color: AppDesignColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () =>
                  ref.read(contactsListProvider.notifier).fetchContacts(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesignColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 52),
              ),
              child: const Text('మళ్ళీ ప్రయత్నించండి'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAddressBookPlaceholder(
    BuildContext context,
    AppLocalizations localization,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88.0,
              height: 88.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppDesignColors.primaryLight,
              ),
              child: const Icon(
                Icons.contact_phone_rounded,
                size: 48.0,
                color: AppDesignColors.primaryDark,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'కాంటాక్ట్స్ ఏమీ లేవు',
              style: AppTypography.sectionHeader.copyWith(
                fontWeight: FontWeight.bold,
                color: AppDesignColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              localization.noContactsSub,
              style: AppTypography.secondaryText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesignColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              icon: const Icon(Icons.person_add_rounded),
              label: Text(localization.saveContactLabel),
              onPressed: () => context.push(AppRoutes.contactForm),
            ),
          ],
        ),
      ),
    );
  }
}
