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
  final bool isFlexibleAllowed;
  final bool isImmediateAllowed;
  final int updatePriority;
  final String? errorMessage;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.currentVersion = '',
    this.currentBuildNumber = '',
    this.availableVersionCode,
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

/// Riverpod StateNotifier managing the Google Play In-App Updates lifecycle.
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

  /// Check Google Play for app updates.
  /// [silent]: If true, background check that will not show error states if unsupported/offline.
  Future<void> checkForUpdate({bool silent = false}) async {
    if (state.currentVersion.isEmpty) {
      await _loadVersionInfo();
    }

    if (!silent) {
      state = state.copyWith(status: UpdateStatus.checking, clearError: true);
    }

    try {
      final updateInfo = await _updateService.checkForUpdate();

      if (updateInfo == null) {
        // PlatformException or not installed via Play Store
        if (!silent) {
          state = state.copyWith(
            status: UpdateStatus.error,
            errorMessage: 'Google Play Store తో అనుసంధానం కాలేకపోయింది.',
          );
        }
        return;
      }

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        state = state.copyWith(
          status: UpdateStatus.available,
          availableVersionCode: updateInfo.availableVersionCode,
          isFlexibleAllowed: updateInfo.flexibleUpdateAllowed,
          isImmediateAllowed: updateInfo.immediateUpdateAllowed,
          updatePriority: updateInfo.updatePriority,
          clearError: true,
        );

        // For critical updates (priority >= 4), if immediate is allowed, we can trigger immediate flow
        if (updateInfo.updatePriority >= 4 && updateInfo.immediateUpdateAllowed) {
          await performImmediateUpdate();
        }
      } else if (updateInfo.updateAvailability == UpdateAvailability.updateNotAvailable) {
        state = state.copyWith(
          status: UpdateStatus.upToDate,
          clearError: true,
        );
      } else {
        if (!silent) {
          state = state.copyWith(status: UpdateStatus.idle);
        }
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

  /// Initiate flexible background download.
  Future<void> startFlexibleUpdate() async {
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

  /// Complete flexible update by restarting the application.
  Future<void> completeFlexibleUpdate() async {
    try {
      await _updateService.completeFlexibleUpdate();
    } catch (e) {
      developer.log('Error completing update: $e', name: _tag);
    }
  }

  /// Launch Google Play immediate fullscreen update flow.
  Future<void> performImmediateUpdate() async {
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
