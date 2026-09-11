import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import '../services/update_service.dart';

/// State representation for app update lifecycle.
class UpdateState {
  final UpdateStatus status;
  final String currentVersion;
  final String currentBuildNumber;
  final int? availableVersionCode;
  final String? availableVersionName;
  final String? downloadUrl;
  final String? downloadedApkPath;
  final double downloadProgress;
  final bool isGitHubSource;
  final bool isFlexibleAllowed;
  final bool isImmediateAllowed;
  final int updatePriority;
  final String? errorMessage;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.currentVersion = '',
    this.currentBuildNumber = '',
    this.availableVersionCode,
    this.availableVersionName,
    this.downloadUrl,
    this.downloadedApkPath,
    this.downloadProgress = 0.0,
    this.isGitHubSource = false,
    this.isFlexibleAllowed = false,
    this.isImmediateAllowed = false,
    this.updatePriority = 0,
    this.errorMessage,
  });

  String get fullVersionString {
    if (currentVersion.isEmpty) return '';
    return currentBuildNumber.isNotEmpty
        ? '$currentVersion ($currentBuildNumber)'
        : currentVersion;
  }

  UpdateState copyWith({
    UpdateStatus? status,
    String? currentVersion,
    String? currentBuildNumber,
    int? availableVersionCode,
    String? availableVersionName,
    String? downloadUrl,
    String? downloadedApkPath,
    double? downloadProgress,
    bool? isGitHubSource,
    bool? isFlexibleAllowed,
    bool? isImmediateAllowed,
    int? updatePriority,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UpdateState(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
      availableVersionCode: availableVersionCode ?? this.availableVersionCode,
      availableVersionName: availableVersionName ?? this.availableVersionName,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      downloadedApkPath: downloadedApkPath ?? this.downloadedApkPath,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isGitHubSource: isGitHubSource ?? this.isGitHubSource,
      isFlexibleAllowed: isFlexibleAllowed ?? this.isFlexibleAllowed,
      isImmediateAllowed: isImmediateAllowed ?? this.isImmediateAllowed,
      updatePriority: updatePriority ?? this.updatePriority,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Provider for the UpdateService dependency.
final updateServiceProvider = Provider<IUpdateService>((ref) {
  return UpdateService();
});

/// Riverpod StateNotifier managing the Dual-Engine (GitHub Direct + Play Core) lifecycle.
class UpdateNotifier extends StateNotifier<UpdateState> {
  final IUpdateService _updateService;
  static const String _tag = 'UpdateNotifier';

  UpdateNotifier(this._updateService) : super(const UpdateState()) {
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final info = await _updateService.getPackageInfo();
      state = state.copyWith(
        currentVersion: info.version,
        currentBuildNumber: info.buildNumber,
      );
    } catch (e) {
      developer.log('Failed to load version info: $e', name: _tag);
    }
  }

  /// Check for app updates using Dual-Engine (Google Play + GitHub Releases).
  /// [silent]: If true, background check that will not show error states if unsupported/offline.
  Future<void> checkForUpdate({bool silent = false}) async {
    if (state.currentVersion.isEmpty) {
      await _loadVersionInfo();
    }

    if (!silent) {
      state = state.copyWith(status: UpdateStatus.checking, clearError: true);
    }

    try {
      // 1. First probe Google Play Core API
      final updateInfo = await _updateService.checkForUpdate();

      if (updateInfo != null) {
        if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
          state = state.copyWith(
            status: UpdateStatus.available,
            availableVersionCode: updateInfo.availableVersionCode,
            isGitHubSource: false,
            isFlexibleAllowed: updateInfo.flexibleUpdateAllowed,
            isImmediateAllowed: updateInfo.immediateUpdateAllowed,
            updatePriority: updateInfo.updatePriority,
            clearError: true,
          );

          if (updateInfo.updatePriority >= 4 && updateInfo.immediateUpdateAllowed) {
            await performImmediateUpdate();
          }
          return;
        } else if (updateInfo.updateAvailability == UpdateAvailability.updateNotAvailable) {
          // Play store says not available, verify if GitHub has a newer release
          final gitHubInfo = await _updateService.checkGitHubRelease();
          if (gitHubInfo != null &&
              UpdateService.compareSemVer(gitHubInfo.version, state.currentVersion) > 0) {
            state = state.copyWith(
              status: UpdateStatus.available,
              availableVersionName: gitHubInfo.version,
              downloadUrl: gitHubInfo.apkDownloadUrl,
              isGitHubSource: true,
              isFlexibleAllowed: true,
              isImmediateAllowed: true,
              clearError: true,
            );
            return;
          }

          state = state.copyWith(
            status: UpdateStatus.upToDate,
            clearError: true,
          );
          return;
        }
      }

      // 2. Play Core returned null (sideloaded APK, GitHub build, debug).
      // Query GitHub Releases for direct OTA package handoff.
      final gitHubInfo = await _updateService.checkGitHubRelease();
      if (gitHubInfo != null) {
        final int comparison = UpdateService.compareSemVer(
          gitHubInfo.version,
          state.currentVersion,
        );

        if (comparison > 0) {
          state = state.copyWith(
            status: UpdateStatus.available,
            availableVersionName: gitHubInfo.version,
            downloadUrl: gitHubInfo.apkDownloadUrl,
            isGitHubSource: true,
            isFlexibleAllowed: true,
            isImmediateAllowed: true,
            clearError: true,
          );
          return;
        } else {
          state = state.copyWith(
            status: UpdateStatus.upToDate,
            clearError: true,
          );
          return;
        }
      }

      // 3. Both Play Core and GitHub queries failed (offline / network error)
      if (!silent) {
        state = state.copyWith(
          status: UpdateStatus.error,
          errorMessage: 'అప్‌డేట్ వివరాలు పొందలేకపోయాము. ఇంటర్నెట్ సరిచూసుకోండి.',
        );
      } else {
        state = state.copyWith(status: UpdateStatus.idle);
      }
    } catch (e) {
      developer.log('Error checking for update: $e', name: _tag);
      if (!silent) {
        state = state.copyWith(
          status: UpdateStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  /// Initiate flexible background download or direct GitHub streaming APK download.
  Future<void> startFlexibleUpdate() async {
    if (state.isGitHubSource && state.downloadUrl != null && state.downloadUrl!.isNotEmpty) {
      state = state.copyWith(
        status: UpdateStatus.downloading,
        downloadProgress: 0.0,
        clearError: true,
      );

      try {
        final downloadedFile = await _updateService.downloadGitHubApk(
          state.downloadUrl!,
          (progress) {
            state = state.copyWith(downloadProgress: progress);
          },
        );

        if (downloadedFile != null) {
          state = state.copyWith(
            status: UpdateStatus.downloaded,
            downloadedApkPath: downloadedFile.path,
            downloadProgress: 1.0,
            clearError: true,
          );

          // Trigger native installer immediately for seamless UX
          await _updateService.installApk(downloadedFile.path);
        } else {
          state = state.copyWith(
            status: UpdateStatus.error,
            errorMessage: 'అప్‌డేట్ డౌన్‌లోడ్ విఫలమైంది.',
          );
        }
      } catch (e) {
        developer.log('Error in direct OTA download: $e', name: _tag);
        state = state.copyWith(
          status: UpdateStatus.error,
          errorMessage: e.toString(),
        );
      }
      return;
    }

    // Google Play Flexible Update Flow
    state = state.copyWith(status: UpdateStatus.downloading, clearError: true);
    try {
      final result = await _updateService.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        state = state.copyWith(status: UpdateStatus.downloaded);
      } else if (result == AppUpdateResult.userDeniedUpdate) {
        state = state.copyWith(status: UpdateStatus.available);
      } else {
        state = state.copyWith(
          status: UpdateStatus.error,
          errorMessage: 'అప్‌డేట్ డౌన్‌లోడ్ విఫలమైంది.',
        );
      }
    } catch (e) {
      developer.log('Failed during flexible update: $e', name: _tag);
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Complete flexible update by restarting or re-triggering native installer.
  Future<void> completeFlexibleUpdate() async {
    if (state.downloadedApkPath != null) {
      await _updateService.installApk(state.downloadedApkPath!);
      return;
    }
    try {
      await _updateService.completeFlexibleUpdate();
    } catch (e) {
      developer.log('Error completing update: $e', name: _tag);
    }
  }

  /// Launch immediate update flow.
  Future<void> performImmediateUpdate() async {
    if (state.isGitHubSource) {
      await startFlexibleUpdate();
      return;
    }
    try {
      final result = await _updateService.performImmediateUpdate();
      if (result != AppUpdateResult.success) {
        state = state.copyWith(status: UpdateStatus.available);
      }
    } catch (e) {
      developer.log('Error performing immediate update: $e', name: _tag);
    }
  }

  /// Open Google Play Store product page as direct fallback.
  Future<void> openPlayStore() async {
    await _updateService.openPlayStoreListing();
  }
}

/// Global provider for application update state.
final updateProvider = StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  final service = ref.watch(updateServiceProvider);
  return UpdateNotifier(service);
});
