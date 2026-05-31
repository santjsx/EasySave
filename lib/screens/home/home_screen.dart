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
import '../../widgets/easy_snackbar.dart';

/// Overhauled Home Screen Dashboard of EasyConnect (Amma Nanna App).
/// Strictly adheres to modern accessibility-first mobile UI/UX principles:
/// utilizes the Turmeric & Terracotta Warm Design System, large avatars,
/// generous 56dp touch targets, and a fully scrollable Slivers-based call history.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callLogsState = ref.watch(callLogProvider);
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppDesignColors.surface, // Sandstone global background
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
                color: AppDesignColors.primary,
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
              Icons.settings,
              size: 32.0,
              color: AppDesignColors.primary,
            ),
            tooltip: localization.settingsTitle,
            onPressed: () => _showSettingsExplanationDialog(context),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Sliver 1: Quick Actions (Top)
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildQuickActions(context),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),

              // Sliver 2: Sticky "Recent Calls" Section Header Row
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  minHeight: 60.0,
                  maxHeight: 60.0,
                  child: Container(
                    color: AppDesignColors.surface, // Solid sandstone background
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.sm,
                      left: AppSpacing.xs,
                      top: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.phone_in_talk_rounded,
                          color: AppDesignColors.primary,
                          size: 28.0,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          localization.recentCallsTitle,
                          style: AppTypography.sectionHeader.copyWith(
                            color: AppDesignColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Sliver 3: Call Logs Feed Sliver List
              callLogsState.when(
                data: (logs) => _buildRecentCallsSliverList(context, ref, logs),
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppDesignColors.primary,
                      strokeWidth: 4.0,
                    ),
                  ),
                ),
                error: (error, stack) => SliverToBoxAdapter(
                  child: _buildPermissionCTACard(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a beautifully styled horizontal and vertical grid of primary accessible actions.
  Widget _buildQuickActions(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: My Contacts (Full Width)
        Container(
          height: 96.0, // Expanded accessible height
          decoration: BoxDecoration(
            color: AppDesignColors.primaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: AppDesignColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
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
                context.push(AppRoutes.contactsList);
              },
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    const Icon(
                      Icons.contacts_rounded,
                      color: AppDesignColors.primaryDark,
                      size: 40.0,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localization.viewMyContacts,
                            style: AppTypography.sectionHeader.copyWith(
                              color: AppDesignColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            localization.viewMyContactsSub,
                            style: AppTypography.secondaryText.copyWith(
                              color: AppDesignColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppDesignColors.primaryDark,
                      size: 28.0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Row of Card 2 and Card 3
        SizedBox(
          height: 108.0, // Generous height for side-by-side tiles
          child: Row(
            children: [
              // Card 2: Save Contact (Turmeric theme)
              Expanded(
                child: Container(
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
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.push(AppRoutes.saveContact);
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: AppDesignColors.primary,
                              size: 32.0,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      localization.saveContactLabel.split(' ').take(2).join(' '), // కొత్త నంబర్
                                      style: AppTypography.bodyText.copyWith(
                                        color: AppDesignColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      localization.saveCallText, // సేవ్ చేయండి
                                      style: AppTypography.bodyText.copyWith(
                                        color: AppDesignColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Card 3: WhatsApp Share (Blue/Sandalwood theme)
              Expanded(
                child: Container(
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
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.push(AppRoutes.sharePhoto);
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: AppDesignColors.primary,
                              size: 32.0,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      localization.sharePhotoLabel, // ఫోటో పంపండి
                                      style: AppTypography.bodyText.copyWith(
                                        color: AppDesignColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "(WhatsApp)",
                                      style: AppTypography.secondaryText.copyWith(
                                        color: AppDesignColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the complete scrollable list of recent calls directly inside CustomScrollView.
  Widget _buildRecentCallsSliverList(BuildContext context, WidgetRef ref, List<CallLogEntry> logs) {
    if (logs.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              AppLocalizations.of(context)!.noCallLogs,
              style: AppTypography.sectionHeader.copyWith(
                color: AppDesignColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final CallLogEntry entry = logs[index];
          return _buildCallLogTile(context, ref, entry);
        },
        childCount: logs.length,
      ),
    );
  }

  /// Redesigns each call log tile.
  Widget _buildCallLogTile(BuildContext context, WidgetRef ref, CallLogEntry entry) {
    final localization = AppLocalizations.of(context)!;

    final Widget detailsRow = Row(
      children: [
        // 1. Giant CircleAvatar (88dp size -> radius: 44.0)
        CircleAvatar(
          radius: 44.0,
          backgroundColor: entry.avatarColor,
          child: Text(
            entry.isSavedContact
                ? entry.contactName.substring(0, 1).toUpperCase()
                : 'అ',
            style: const TextStyle(
              fontSize: 34.0, // Bold large letters
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: AppTypography.fontFamily,
            ),
          ),
        ),
        const SizedBox(width: 16.0), // Generous 16dp spacing

        // 2. Middle column: Clean visual hierarchy with strict typography sizes
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Contact Name (or Phone Number for unsaved contacts) -> 22sp semi-bold
              Text(
                entry.isSavedContact
                    ? '${entry.contactName}${entry.callCount > 1 ? " (${entry.callCount})" : ""}'
                    : entry.phoneNumber,
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w600, // Semi-bold
                  color: AppDesignColors.textPrimary,
                  fontFamily: AppTypography.fontFamily,
                  height: 1.3,
                  letterSpacing: 0.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6.0),

              // Call Status -> Row containing type icon and 16sp medium text
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    entry.typeIcon,
                    size: 20.0, // Highly visible accessibility icons
                    color: entry.typeColor,
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    entry.telugifiedCallType,
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w500, // Medium call status
                      color: entry.typeColor,
                      fontFamily: AppTypography.fontFamily,
                      height: 1.2,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),

              // Phone Number (or "Unsaved Number" label for unsaved contacts) -> 16sp regular
              Text(
                entry.isSavedContact
                    ? entry.phoneNumber
                    : localization.unsavedNumber,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400, // Regular
                  color: entry.isSavedContact
                      ? AppDesignColors.textSecondary
                      : AppDesignColors.error,
                  fontFamily: AppTypography.fontFamily,
                  height: 1.2,
                  letterSpacing: 0.5, // Number readability spacing
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12.0),

        // 3. Right Status Block (consistently aligned 20sp medium timestamp + chevron)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.telugifiedTime,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w500, // Medium timestamp
                color: AppDesignColors.textSecondary,
                fontFamily: AppTypography.fontFamily,
                height: 1.2,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 8.0),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppDesignColors.textSecondary,
              size: 28.0,
            ),
          ],
        ),
      ],
    );

    final Widget detailsInkWell = InkWell(
      onTap: () async {
        // Direct dialing logic
        final status = await Permission.phone.request();
        if (status.isGranted) {
          const platform = MethodChannel('com.ammananna.app/direct_call');
          try {
            await platform.invokeMethod('makeCall', {
              'phoneNumber': entry.phoneNumber,
            });
          } catch (e) {
            final Uri phoneUri = Uri(scheme: 'tel', path: entry.phoneNumber);
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
      },
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20.0),
        topRight: Radius.circular(20.0),
        bottomLeft: Radius.circular(20.0),
        bottomRight: Radius.circular(20.0),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 110.0), // Pinned minimum card height
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        alignment: Alignment.center,
        child: detailsRow,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceCard,
        borderRadius: BorderRadius.circular(20.0), // Rounded corners 20dp
        border: Border.all(
          color: AppDesignColors.divider,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: entry.isSavedContact
            ? detailsInkWell
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  detailsInkWell,
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.md,
                      top: AppSpacing.xs,
                    ),
                    child: InkWell(
                      onTap: () {
                        context.push(
                          '${AppRoutes.quickSave}?phone=${Uri.encodeComponent(entry.phoneNumber)}',
                        );
                      },
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      child: Ink(
                        height: AppSpacing.minTouchTarget, // Strictly 56dp height
                        decoration: BoxDecoration(
                          color: AppDesignColors.success,
                          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                          boxShadow: [
                            BoxShadow(
                              color: AppDesignColors.success.withValues(alpha: 0.15),
                              blurRadius: 6.0,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: Colors.white,
                                size: 24.0,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                localization.saveCallText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.0, // High visibility size >= 18sp
                                  fontWeight: FontWeight.bold,
                                  fontFamily: AppTypography.fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Builds a graceful permission call-to-action block if access is denied.
  Widget _buildPermissionCTACard(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context)!;
    
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security_rounded,
                color: AppDesignColors.error,
                size: 56.0,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                localization.permissionRequired,
                style: AppTypography.sectionHeader.copyWith(
                  color: AppDesignColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                localization.callLogPermissionExplanation,
                style: AppTypography.bodyText.copyWith(
                  color: AppDesignColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, AppSpacing.minTouchTarget),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                onPressed: () {
                  ref.read(callLogProvider.notifier).requestPermissionAndFetch();
                },
                child: Text(
                  localization.grantPermission,
                  style: AppTypography.buttonText.copyWith(
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a friendly Settings & Info dialog on gear tap.
  void _showSettingsExplanationDialog(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          backgroundColor: AppDesignColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: const BorderSide(color: AppDesignColors.divider, width: 1.5),
          ),
          title: Text(
            localization.settingsTitle,
            style: AppTypography.sectionHeader.copyWith(
              fontWeight: FontWeight.bold,
              color: AppDesignColors.primary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Developer Credits
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppDesignColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.code_rounded, color: AppDesignColors.primaryDark, size: 24.0),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          localization.developerCredits,
                          style: AppTypography.secondaryText.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppDesignColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 2. Privacy Policy Card
                InkWell(
                  onTap: () => _showPolicyDialog(
                    context, 
                    localization.privacyPolicyTitle, 
                    localization.privacyPolicyText,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppDesignColors.divider, width: 1.5),
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.privacy_tip_outlined, color: AppDesignColors.textSecondary, size: 24.0),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            localization.privacyPolicyTitle,
                            style: AppTypography.secondaryText.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppDesignColors.textSecondary, size: 16.0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Terms of Service Card
                InkWell(
                  onTap: () => _showPolicyDialog(
                    context, 
                    localization.termsOfServiceTitle, 
                    localization.termsOfServiceText,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppDesignColors.divider, width: 1.5),
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, color: AppDesignColors.textSecondary, size: 24.0),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            localization.termsOfServiceTitle,
                            style: AppTypography.secondaryText.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppDesignColors.textSecondary, size: 16.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(80, AppSpacing.minTouchTarget),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                localization.closeButton,
                style: AppTypography.bodyText.copyWith(
                  color: AppDesignColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Opens a sub-dialog displaying policies in English.
  void _showPolicyDialog(BuildContext context, String title, String body) {
    final localization = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          backgroundColor: AppDesignColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: const BorderSide(color: AppDesignColors.divider, width: 1.5),
          ),
          title: Text(
            title,
            style: AppTypography.sectionHeader.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              body,
              style: AppTypography.secondaryText.copyWith(
                color: AppDesignColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(80, AppSpacing.minTouchTarget),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                localization.yesButton,
                style: AppTypography.bodyText.copyWith(
                  color: AppDesignColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Helper Delegate to render beautiful and high-performance pinned persistent headers.
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
