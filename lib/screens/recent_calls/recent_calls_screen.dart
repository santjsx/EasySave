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
import '../../services/call_service.dart';

/// Full Dedicated Screen for System Call Logs.
/// Features All vs Missed Call filter chips, 1-tap direct dialing,
/// and instant Quick-Save for unsaved callers.
class RecentCallsScreen extends ConsumerStatefulWidget {
  const RecentCallsScreen({super.key});

  @override
  ConsumerState<RecentCallsScreen> createState() => _RecentCallsScreenState();
}

class _RecentCallsScreenState extends ConsumerState<RecentCallsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Missed

  @override
  Widget build(BuildContext context) {
    final callLogsState = ref.watch(callLogProvider);
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
          localization.recentCallsTitle,
          style: AppTypography.appName.copyWith(
            color: AppDesignColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Filter Chips (All vs Missed)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: localization.allCalls,
                    isSelected: _selectedFilterIndex == 0,
                    icon: Icons.call_rounded,
                    onTap: () => setState(() => _selectedFilterIndex = 0),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildFilterChip(
                    label: localization.missedCalls,
                    isSelected: _selectedFilterIndex == 1,
                    icon: Icons.phone_missed_rounded,
                    selectedColor: AppDesignColors.error,
                    onTap: () => setState(() => _selectedFilterIndex = 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // 2. Call Logs List
            Expanded(
              child: RefreshIndicator(
                color: AppDesignColors.primary,
                onRefresh: () =>
                    ref.read(callLogProvider.notifier).refreshCalls(),
                child: callLogsState.when(
                  data: (logs) {
                    final filtered = _selectedFilterIndex == 0
                        ? logs
                        : logs
                            .where((l) =>
                                l.callType == CallEntryType.missed ||
                                l.callType == CallEntryType.rejected)
                            .toList();

                    if (filtered.isEmpty) {
                      return _buildEmptyPlaceholder();
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8.0),
                      itemBuilder: (context, index) {
                        return _buildCallTile(filtered[index]);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppDesignColors.primary,
                      strokeWidth: 4.0,
                    ),
                  ),
                  error: (err, stack) => _buildPermissionError(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    Color? selectedColor,
    required VoidCallback onTap,
  }) {
    final activeColor = selectedColor ?? AppDesignColors.primaryDark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            height: 48.0,
            decoration: BoxDecoration(
              color: isSelected ? activeColor : AppDesignColors.surfaceCard,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isSelected ? activeColor : AppDesignColors.divider,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.25),
                        blurRadius: 8.0,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20.0,
                  color: isSelected ? Colors.white : AppDesignColors.textSecondary,
                ),
                const SizedBox(width: 6.0),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTypography.fontFamily,
                    color:
                        isSelected ? Colors.white : AppDesignColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallTile(CallLogEntry entry) {
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
              vertical: 12.0,
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 26.0,
                  backgroundColor: entry.avatarColor,
                  child: Text(
                    entry.isSavedContact && entry.contactName.isNotEmpty
                        ? entry.contactName.substring(0, 1).toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 22.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Caller info
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
                              fontSize: 18.0,
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
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: AppDesignColors.textPrimary,
                            fontFamily: AppTypography.fontFamily,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 3.0),
                      Row(
                        children: [
                          Icon(entry.typeIcon, size: 15.0, color: entry.typeColor),
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

                // Trailing actions:
                // Saved contacts get 1-Click Call button.
                // Unsaved contacts get BOTH Quick Save and 1-Click Call buttons.
                if (entry.isSavedContact)
                  Tooltip(
                    message: localization.callButtonTooltip,
                    child: Container(
                      width: 44.0,
                      height: 44.0,
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
                          onTap: () => ref.read(callServiceProvider).makeCall(context, entry.phoneNumber),
                          child: const Icon(
                            Icons.phone_in_talk_rounded,
                            color: AppDesignColors.success,
                            size: 22.0,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quick Save Button (Warm Amber)
                      Tooltip(
                        message: localization.saveCallText,
                        child: Container(
                          width: 38.0,
                          height: 38.0,
                          decoration: BoxDecoration(
                            color: AppDesignColors.primaryLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppDesignColors.primary.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                context.push(
                                  '${AppRoutes.quickSave}?phone=${Uri.encodeComponent(entry.phoneNumber)}',
                                );
                              },
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: AppDesignColors.primaryDark,
                                size: 19.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // 1-Click Direct Call Button (Green)
                      Tooltip(
                        message: localization.callButtonTooltip,
                        child: Container(
                          width: 44.0,
                          height: 44.0,
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
                              onTap: () => ref.read(callServiceProvider).makeCall(context, entry.phoneNumber),
                              child: const Icon(
                                Icons.phone_in_talk_rounded,
                                color: AppDesignColors.success,
                                size: 22.0,
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildEmptyPlaceholder() {
    final localization = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84.0,
              height: 84.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppDesignColors.primaryLight,
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 44.0,
                color: AppDesignColors.primaryDark,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              localization.noCallLogs,
              style: AppTypography.sectionHeader.copyWith(
                fontWeight: FontWeight.bold,
                color: AppDesignColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              localization.noRecentCallsSub,
              style: AppTypography.secondaryText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesignColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              icon: const Icon(Icons.contacts_rounded, size: 20.0),
              label: Text(
                localization.viewContactsAction,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
              onPressed: () => context.push(AppRoutes.contactsList),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionError() {
    final localization = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.phone_locked_rounded,
              color: AppDesignColors.error,
              size: 56.0,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              localization.permissionRequired,
              style: AppTypography.sectionHeader.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              localization.callLogPermissionExplanation,
              style: AppTypography.bodyText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesignColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 52),
              ),
              onPressed: () {
                ref.read(callLogProvider.notifier).requestPermissionAndFetch();
              },
              child: Text(localization.grantPermission),
            ),
          ],
        ),
      ),
    );
  }
}
