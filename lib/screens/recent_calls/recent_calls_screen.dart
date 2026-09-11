import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/call_log_model.dart';
import '../../providers/call_log_provider.dart';
import '../../routing/routes.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

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
          onTap: () => _dialDirect(entry.phoneNumber),
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
                  radius: 28.0,
                  backgroundColor: entry.avatarColor,
                  child: Text(
                    entry.isSavedContact && entry.contactName.isNotEmpty
                        ? entry.contactName.substring(0, 1).toUpperCase()
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

                // Caller info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.isSavedContact
                            ? '${entry.contactName}${entry.callCount > 1 ? " (${entry.callCount})" : ""}'
                            : formatPhone(entry.phoneNumber),
                        style: const TextStyle(
                          fontSize: 19.0,
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
                          Icon(entry.typeIcon, size: 16.0, color: entry.typeColor),
                          const SizedBox(width: 4.0),
                          Text(
                            callTypeLabel,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: entry.typeColor,
                              fontFamily: AppTypography.fontFamily,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            entry.telugifiedTime,
                            style: const TextStyle(
                              fontSize: 13.0,
                              color: AppDesignColors.textSecondary,
                              fontFamily: AppTypography.fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Trailing: Direct call or Quick save
                entry.isSavedContact
                    ? IconButton(
                        icon: const Icon(
                          Icons.phone_in_talk_rounded,
                          color: AppDesignColors.success,
                          size: 28.0,
                        ),
                        onPressed: () => _dialDirect(entry.phoneNumber),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesignColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 8.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18.0),
                        label: Text(
                          localization.saveCallText,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTypography.fontFamily,
                          ),
                        ),
                        onPressed: () {
                          context.push(
                            '${AppRoutes.quickSave}?phone=${Uri.encodeComponent(entry.phoneNumber)}',
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _dialDirect(String phoneNumber) async {
    final status = await Permission.phone.request();
    if (status.isGranted) {
      const platform = MethodChannel('com.ammananna.app/direct_call');
      try {
        await platform.invokeMethod('makeCall', {'phoneNumber': phoneNumber});
      } catch (_) {
        final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
        try {
          await launchUrl(phoneUri);
        } catch (_) {}
      }
    }
  }

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.phone_missed_rounded,
            size: 72.0,
            color: AppDesignColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context)!.noCallLogs,
            style: AppTypography.sectionHeader.copyWith(
              color: AppDesignColors.textSecondary,
            ),
          ),
        ],
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
