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

/// Clean, high-performance Contacts Directory screen for EasySave.
/// Provides Telugu alphabetical collation, instant search, voice search,
/// and direct navigation to dedicated Contact Details and Contact Form screens.
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

  /// Initiates quick voice search using speech recognition.
  Future<void> _startVoiceSearch() async {
    final speechService = ref.read(speechServiceProvider);
    final localization = AppLocalizations.of(context)!;

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
            // 1. Search Bar with 1-tap Clear and Voice Search
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
                          color: AppDesignColors.divider,
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
                              .withValues(alpha: 0.3),
                          blurRadius: 8.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          _startVoiceSearch();
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

            if (_isVoiceSearching)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
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

            // 2. Contacts List View
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
                      : contactsState.filteredContacts.isEmpty
                          ? _buildEmptyPlaceholder()
                          : RefreshIndicator(
                              color: AppDesignColors.primary,
                              onRefresh: () => ref
                                  .read(contactsListProvider.notifier)
                                  .fetchContacts(),
                              child: ListView.separated(
                                itemCount: contactsState.filteredContacts.length,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8.0),
                                itemBuilder: (context, index) {
                                  final ContactModel contact =
                                      contactsState.filteredContacts[index];
                                  return _buildContactTile(context, contact);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an accessible, tactile contact list tile that navigates to dedicated ContactDetailsScreen.
  Widget _buildContactTile(BuildContext context, ContactModel contact) {
    String formatPhone(String p) {
      final clean = p.replaceAll(RegExp(r'\s+'), '');
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
          color: AppDesignColors.divider,
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
            // Navigate directly to dedicated Contact Details screen
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
                      Text(
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

                // Trailing chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppDesignColors.textSecondary,
                  size: 28.0,
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.contacts_outlined,
              size: 72.0,
              color: AppDesignColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'కాంటాక్ట్స్ ఏమీ లేవు',
              style: AppTypography.sectionHeader.copyWith(
                color: AppDesignColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'కొత్త నంబర్ సేవ్ చేసుకోవడానికి పైన ఉన్న + బటన్ నొక్కండి',
              style: AppTypography.secondaryText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
