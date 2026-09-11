import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/call_log_model.dart';
import '../../providers/call_log_provider.dart';
import '../../routing/routes.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../providers/update_provider.dart';
import '../../services/update_service.dart';
import '../../services/call_service.dart';

/// Clean, beautiful, and accessible Home Dashboard of EasySave.
/// Adheres strictly to Hick's Law, Fitts's Law, and WCAG AAA standards.
/// Presents 3 prominent actions and a preview of recent calls.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateProvider.notifier).checkForUpdate(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final callLogsState = ref.watch(callLogProvider);
    final updateState = ref.watch(updateProvider);
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppDesignColors.surface,
      appBar: AppBar(
        backgroundColor: AppDesignColors.surface,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90.0,
        title: Column(
          children: [
            Text(
              localization.appName,
              style: AppTypography.appName.copyWith(
                color: AppDesignColors.primaryDark,
                fontSize: 32.0,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              localization.appTagline,
              style: AppTypography.secondaryText.copyWith(
                color: AppDesignColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              size: 30.0,
              color: AppDesignColors.primaryDark,
            ),
            tooltip: localization.settingsTitle,
            onPressed: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppDesignColors.primary,
          onRefresh: () => ref.read(callLogProvider.notifier).refreshCalls(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 0. Update Downloaded / Downloading Notice Banner
                if (updateState.status == UpdateStatus.downloaded) ...[
                  _buildUpdateDownloadedBanner(context, localization, updateState),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (updateState.status == UpdateStatus.downloading) ...[
                  _buildUpdateDownloadingBanner(context, localization, updateState),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 1. Primary Action Bento Cards
                _buildActionCards(context),

                const SizedBox(height: AppSpacing.xl),

                // 2. Recent Calls Section Header with "View All" Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          color: AppDesignColors.primaryDark,
                          size: 26.0,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          localization.recentCallsTitle,
                          style: AppTypography.sectionHeader.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppDesignColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.recentCalls),
                      child: Row(
                        children: [
                          Text(
                            localization.viewAllCalls,
                            style: const TextStyle(
                              color: AppDesignColors.primaryDark,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppTypography.fontFamily,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14.0,
                            color: AppDesignColors.primaryDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // 3. Recent Calls Preview (Top 4 calls)
                callLogsState.when(
                  data: (logs) => _buildRecentCallsPreview(context, ref, logs),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xxl),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppDesignColors.primary,
                      ),
                    ),
                  ),
                  error: (error, stack) => _buildPermissionNotice(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the 3 core action cards in a calm, balanced, accessible layout.
  Widget _buildActionCards(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Card 1: My Contacts Directory (Full Width Card)
        _buildBentoTile(
          color: AppDesignColors.primaryLight,
          borderColor: AppDesignColors.primary.withValues(alpha: 0.3),
          icon: Icons.contacts_rounded,
          iconColor: AppDesignColors.primaryDark,
          title: localization.viewMyContacts,
          subtitle: localization.viewMyContactsSub,
          onTap: () => context.push(AppRoutes.contactsList),
        ),
        const SizedBox(height: AppSpacing.md),

        // Row of 2 Cards: Save Contact + Share Photo
        Row(
          children: [
            // Card 2: Save New Contact
            Expanded(
              child: _buildSquareActionTile(
                icon: Icons.person_add_alt_1_rounded,
                iconColor: AppDesignColors.primary,
                title: localization.saveContactLabel,
                subtitle: localization.saveContactSub,
                onTap: () => context.push(AppRoutes.saveContact),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Card 3: WhatsApp Photo Share
            Expanded(
              child: _buildSquareActionTile(
                icon: Icons.chat_bubble_rounded,
                iconColor: AppDesignColors.whatsapp,
                title: localization.sharePhotoLabel,
                subtitle: localization.sharePhotoSub,
                onTap: () => context.push(AppRoutes.sharePhoto),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoTile({
    required Color color,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 94.0,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 40.0),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.sectionHeader.copyWith(
                          color: AppDesignColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.secondaryText.copyWith(
                          color: AppDesignColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: iconColor,
                  size: 20.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSquareActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 120.0,
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppDesignColors.divider, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor, size: 36.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppDesignColors.textPrimary,
                        fontSize: 17.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTypography.fontFamily,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppDesignColors.textSecondary,
                        fontSize: 14.0,
                        fontFamily: AppTypography.fontFamily,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Displays the top 4 most recent calls.
  Widget _buildRecentCallsPreview(
    BuildContext context,
    WidgetRef ref,
    List<CallLogEntry> logs,
  ) {
    final localization = AppLocalizations.of(context)!;

    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppDesignColors.surfaceCard,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppDesignColors.divider, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppDesignColors.primaryLight,
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 26.0,
                color: AppDesignColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.noCallLogs,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: AppDesignColors.textPrimary,
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    localization.noRecentCallsSub,
                    style: AppTypography.secondaryText.copyWith(fontSize: 13.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final previewLogs = logs.take(4).toList();

    return Column(
      children: previewLogs.map((entry) {
        return _buildCallTile(context, ref, entry);
      }).toList(),
    );
  }

  Widget _buildCallTile(
    BuildContext context,
    WidgetRef ref,
    CallLogEntry entry,
  ) {
    final localization = AppLocalizations.of(context)!;

    String formatPhone(String p) {
      final clean = p.replaceAll(RegExp(r'\s+'), '');
      if (clean.isEmpty) {
        return localization.unknownNumber;
      }
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

    final String callTypeLabel;
    switch (entry.callType) {
      case CallEntryType.incoming:
        callTypeLabel = localization.incomingCall;
        break;
      case CallEntryType.outgoing:
        callTypeLabel = localization.outgoingCall;
        break;
      case CallEntryType.missed:
        callTypeLabel = localization.missedCall;
        break;
      case CallEntryType.rejected:
        callTypeLabel = localization.rejectedCall;
        break;
    }

    final String displayTitle = entry.isSavedContact
        ? (entry.contactName.isNotEmpty
            ? entry.contactName
            : formatPhone(entry.phoneNumber))
        : formatPhone(entry.phoneNumber);

    final String titleText = entry.callCount > 1
        ? '$displayTitle (${entry.callCount})'
        : displayTitle;

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppDesignColors.divider, width: 1.5),
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
          onTap: () => ref.read(callServiceProvider).makeCall(context, entry.phoneNumber),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24.0,
                  backgroundColor: entry.avatarColor,
                  child: Text(
                    entry.isSavedContact && entry.contactName.isNotEmpty
                        ? entry.contactName.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 20.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Caller Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!entry.isSavedContact)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            titleText,
                            style: const TextStyle(
                              fontSize: 17.0,
                              fontWeight: FontWeight.bold,
                              color: AppDesignColors.textPrimary,
                              fontFamily: AppTypography.fontFamily,
                            ),
                            maxLines: 1,
                            softWrap: false,
                          ),
                        )
                      else
                        Text(
                          titleText,
                          style: const TextStyle(
                            fontSize: 17.0,
                            fontWeight: FontWeight.bold,
                            color: AppDesignColors.textPrimary,
                            fontFamily: AppTypography.fontFamily,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2.0),
                      Row(
                        children: [
                          Icon(entry.typeIcon, size: 14.0, color: entry.typeColor),
                          const SizedBox(width: 4.0),
                          Text(
                            callTypeLabel,
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: entry.typeColor,
                              fontFamily: AppTypography.fontFamily,
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          Expanded(
                            child: Text(
                              entry.telugifiedTime,
                              style: const TextStyle(
                                fontSize: 12.0,
                                color: AppDesignColors.textSecondary,
                                fontFamily: AppTypography.fontFamily,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Actions: 1-Click Direct Call & Quick Save for unsaved
                if (entry.isSavedContact)
                  IconButton(
                    icon: const Icon(
                      Icons.phone_in_talk_rounded,
                      color: AppDesignColors.success,
                      size: 24.0,
                    ),
                    tooltip: localization.callButtonTooltip,
                    onPressed: () => ref.read(callServiceProvider).makeCall(context, entry.phoneNumber),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          color: AppDesignColors.primary,
                          size: 22.0,
                        ),
                        tooltip: localization.saveCallText,
                        onPressed: () {
                          context.push(
                            '${AppRoutes.quickSave}?phone=${Uri.encodeComponent(entry.phoneNumber)}',
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.phone_in_talk_rounded,
                          color: AppDesignColors.success,
                          size: 24.0,
                        ),
                        tooltip: localization.callButtonTooltip,
                        onPressed: () => ref.read(callServiceProvider).makeCall(context, entry.phoneNumber),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionNotice(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppDesignColors.divider, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.phone_locked_rounded,
            color: AppDesignColors.primaryDark,
            size: 44.0,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            localization.callLogPermissionExplanation,
            style: AppTypography.bodyText.copyWith(
              color: AppDesignColors.textSecondary,
              fontSize: 16.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(160, 48),
            ),
            onPressed: () {
              ref.read(callLogProvider.notifier).requestPermissionAndFetch();
            },
            child: Text(localization.grantPermission),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateDownloadedBanner(
    BuildContext context,
    AppLocalizations localization,
    UpdateState updateState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppDesignColors.successLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppDesignColors.success,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppDesignColors.success.withValues(alpha: 0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppDesignColors.success,
                size: 26.0,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  updateState.isGitHubSource
                      ? localization.readyToInstallUpdate
                      : localization.updateDownloaded,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: AppDesignColors.textPrimary,
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignColors.success,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            icon: Icon(
              updateState.isGitHubSource
                  ? Icons.system_update_rounded
                  : Icons.restart_alt_rounded,
              size: 22.0,
            ),
            label: Text(
              updateState.isGitHubSource
                  ? localization.installNowAction
                  : localization.restartToUpdate,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                fontFamily: AppTypography.fontFamily,
              ),
            ),
            onPressed: () {
              ref.read(updateProvider.notifier).completeFlexibleUpdate();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateDownloadingBanner(
    BuildContext context,
    AppLocalizations localization,
    UpdateState updateState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppDesignColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppDesignColors.primary,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppDesignColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  updateState.isGitHubSource && updateState.downloadProgress > 0
                      ? localization.downloadingUpdateWithProgress(
                          (updateState.downloadProgress * 100).toInt(),
                        )
                      : localization.downloadingUpdate,
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: AppDesignColors.primaryDark,
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: updateState.downloadProgress > 0 ? updateState.downloadProgress : null,
            backgroundColor: Colors.white,
            color: AppDesignColors.primary,
            minHeight: 6.0,
            borderRadius: BorderRadius.circular(3.0),
          ),
        ],
      ),
    );
  }
}
