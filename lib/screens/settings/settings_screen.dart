import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/update_provider.dart';
import '../../services/update_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Dedicated Settings & Information Screen.
/// Replaces the cramped alert dialog with a beautiful, accessible overview,
/// including permissions management and Google Play In-App Updates.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _contactsGranted = false;
  bool _phoneGranted = false;
  bool _micGranted = false;
  bool _photosGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final contacts = await Permission.contacts.isGranted;
    final phone = await Permission.phone.isGranted;
    final mic = await Permission.microphone.isGranted;
    final photos =
        await Permission.photos.isGranted || await Permission.storage.isGranted;

    if (mounted) {
      setState(() {
        _contactsGranted = contacts;
        _phoneGranted = phone;
        _micGranted = mic;
        _photosGranted = photos;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;
    final updateState = ref.watch(updateProvider);
    final updateNotifier = ref.read(updateProvider.notifier);

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
          localization.settingsTitle,
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
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. App Header Branding Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppDesignColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(
                    color: AppDesignColors.primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.phone_android_rounded,
                      size: 64.0,
                      color: AppDesignColors.primaryDark,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      localization.appName,
                      style: AppTypography.appName.copyWith(
                        fontSize: 28.0,
                        fontWeight: FontWeight.w900,
                        color: AppDesignColors.primaryDark,
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
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      updateState.fullVersionString.isNotEmpty
                          ? '${localization.versionLabel}: ${updateState.fullVersionString}'
                          : 'వెర్షన్ 1.3.4 (35)',
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: AppDesignColors.textSecondary,
                        fontFamily: AppTypography.fontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 2. Dual-Engine In-App Updates Card
              _buildUpdateCard(context, localization, updateState, updateNotifier),

              const SizedBox(height: AppSpacing.xl),

              // 3. Permissions Status Section
              Text(
                localization.appPermissionsTitle,
                style: AppTypography.sectionHeader.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppDesignColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              _buildPermissionTile(
                icon: Icons.contacts_rounded,
                title: localization.contactsPermissionLabel,
                isGranted: _contactsGranted,
                onRequest: () async {
                  await Permission.contacts.request();
                  _checkPermissions();
                },
              ),
              const SizedBox(height: AppSpacing.xs),

              _buildPermissionTile(
                icon: Icons.phone_in_talk_rounded,
                title: localization.phoneCallsPermissionLabel,
                isGranted: _phoneGranted,
                onRequest: () async {
                  await Permission.phone.request();
                  _checkPermissions();
                },
              ),
              const SizedBox(height: AppSpacing.xs),

              _buildPermissionTile(
                icon: Icons.mic_rounded,
                title: localization.microphonePermissionLabel,
                isGranted: _micGranted,
                onRequest: () async {
                  await Permission.microphone.request();
                  _checkPermissions();
                },
              ),
              const SizedBox(height: AppSpacing.xs),

              _buildPermissionTile(
                icon: Icons.photo_library_rounded,
                title: localization.photosPermissionLabel,
                isGranted: _photosGranted,
                onRequest: () async {
                  await Permission.photos.request();
                  _checkPermissions();
                },
              ),

              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52.0),
                  side: const BorderSide(color: AppDesignColors.divider, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined, color: AppDesignColors.primaryDark),
                label: Text(
                  localization.openSettings,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: AppDesignColors.primaryDark,
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
                onPressed: () => openAppSettings(),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // 4. Privacy & Trust Statement Card
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
                          Icons.security_rounded,
                          color: AppDesignColors.success,
                          size: 28.0,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            localization.privacyPolicyTitle,
                            style: AppTypography.sectionHeader.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppDesignColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      localization.privacyPolicyText,
                      style: AppTypography.bodyText.copyWith(
                        fontSize: 16.0,
                        color: AppDesignColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 5. Developer Credits
              Center(
                child: Text(
                  localization.developerCredits,
                  style: AppTypography.secondaryText.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppDesignColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateCard(
    BuildContext context,
    AppLocalizations localization,
    UpdateState updateState,
    UpdateNotifier updateNotifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: updateState.status == UpdateStatus.downloaded
              ? AppDesignColors.success
              : (updateState.status == UpdateStatus.available
                  ? AppDesignColors.primary
                  : AppDesignColors.divider),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.system_update_rounded,
                color: updateState.status == UpdateStatus.downloaded
                    ? AppDesignColors.success
                    : AppDesignColors.primaryDark,
                size: 28.0,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                localization.appUpdate,
                style: AppTypography.sectionHeader.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppDesignColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (updateState.status == UpdateStatus.upToDate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: AppDesignColors.successLight,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppDesignColors.success, size: 16.0),
                      SizedBox(width: 4.0),
                      Text(
                        'తాజా వెర్షన్',
                        style: TextStyle(
                          color: AppDesignColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Dynamic status content based on UpdateStatus
          if (updateState.status == UpdateStatus.checking) ...[
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
                Text(
                  localization.checkingForUpdates,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppDesignColors.textSecondary,
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
              ],
            ),
          ] else if (updateState.status == UpdateStatus.downloading) ...[
            Text(
              updateState.isGitHubSource && updateState.downloadProgress > 0
                  ? localization.downloadingUpdateWithProgress(
                      (updateState.downloadProgress * 100).toInt(),
                    )
                  : localization.downloadingUpdate,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                color: AppDesignColors.primaryDark,
                fontFamily: AppTypography.fontFamily,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: updateState.downloadProgress > 0 ? updateState.downloadProgress : null,
              backgroundColor: AppDesignColors.primaryLight,
              color: AppDesignColors.primary,
              minHeight: 8.0,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ] else if (updateState.status == UpdateStatus.downloaded) ...[
            Text(
              updateState.isGitHubSource
                  ? localization.readyToInstallUpdate
                  : localization.updateDownloaded,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: AppDesignColors.success,
                fontFamily: AppTypography.fontFamily,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesignColors.success,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
              ),
              icon: Icon(
                updateState.isGitHubSource
                    ? Icons.system_update_rounded
                    : Icons.restart_alt_rounded,
                size: 24.0,
              ),
              label: Text(
                updateState.isGitHubSource
                    ? localization.installNowAction
                    : localization.restartToUpdate,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
              onPressed: () => updateNotifier.completeFlexibleUpdate(),
            ),
          ] else if (updateState.status == UpdateStatus.available) ...[
            Text(
              localization.updateAvailable,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: AppDesignColors.primaryDark,
                fontFamily: AppTypography.fontFamily,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppDesignColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
              ),
              icon: const Icon(Icons.download_rounded, size: 24.0),
              label: Text(
                localization.updateNow,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
              onPressed: () {
                if (updateState.isFlexibleAllowed) {
                  updateNotifier.startFlexibleUpdate();
                } else {
                  updateNotifier.performImmediateUpdate();
                }
              },
            ),
          ] else if (updateState.status == UpdateStatus.error) ...[
            Text(
              updateState.errorMessage ?? localization.updateError,
              style: const TextStyle(
                fontSize: 15.0,
                color: AppDesignColors.textSecondary,
                fontFamily: AppTypography.fontFamily,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppDesignColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    icon: const Icon(Icons.store_rounded, color: AppDesignColors.primaryDark, size: 20.0),
                    label: Text(
                      localization.openInPlayStore,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: AppDesignColors.primaryDark,
                        fontFamily: AppTypography.fontFamily,
                      ),
                    ),
                    onPressed: () => updateNotifier.openPlayStore(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppDesignColors.primaryDark),
                  tooltip: localization.tryAgainTooltip,
                  onPressed: () => updateNotifier.checkForUpdate(silent: false),
                ),
              ],
            ),
          ] else ...[
            // Idle or UpToDate
            Text(
              updateState.status == UpdateStatus.upToDate
                  ? localization.upToDate
                  : localization.updateCheckSubtitle,
              style: const TextStyle(
                fontSize: 15.0,
                color: AppDesignColors.textSecondary,
                fontFamily: AppTypography.fontFamily,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48.0),
                side: const BorderSide(color: AppDesignColors.divider, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, color: AppDesignColors.primaryDark, size: 20.0),
              label: Text(
                localization.checkForUpdates,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: AppDesignColors.primaryDark,
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
              onPressed: () => updateNotifier.checkForUpdate(silent: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required bool isGranted,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppDesignColors.surfaceCard,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppDesignColors.divider, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppDesignColors.primaryDark, size: 28.0),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                color: AppDesignColors.textPrimary,
                fontFamily: AppTypography.fontFamily,
              ),
            ),
          ),
          isGranted
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: AppDesignColors.successLight,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: AppDesignColors.success, size: 18.0),
                      SizedBox(width: 4.0),
                      Text(
                        'సరే',
                        style: TextStyle(
                          color: AppDesignColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                )
              : TextButton(
                  onPressed: onRequest,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  ),
                  child: const Text(
                    'అనుమతించు',
                    style: TextStyle(
                      color: AppDesignColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0,
                      fontFamily: AppTypography.fontFamily,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
