import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Represents the high-level in-app update state.
enum UpdateStatus {
  /// Initial idle state or no update checked yet.
  idle,

  /// Currently checking Google Play / update servers.
  checking,

  /// A new update is available on Google Play.
  available,

  /// Flexible update is actively downloading in background.
  downloading,

  /// Flexible update download completed and ready for 1-tap restart.
  downloaded,

  /// App is already at the latest version.
  upToDate,

  /// Update check failed or device is not running a Play Store build.
  error,
}

/// Abstract contract for update operations (enables clean mocking in tests).
abstract class IUpdateService {
  Future<PackageInfo> getPackageInfo();
  Future<AppUpdateInfo?> checkForUpdate();
  Future<AppUpdateResult> startFlexibleUpdate();
  Future<void> completeFlexibleUpdate();
  Future<AppUpdateResult> performImmediateUpdate();
  Future<bool> openPlayStoreListing();
}

/// Production implementation using Google Play In-App Updates (Play Core API).
class UpdateService implements IUpdateService {
  static const String _tag = 'UpdateService';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ammananna.app';
  static const String _marketUri =
      'market://details?id=com.ammananna.app';

  PackageInfo? _cachedPackageInfo;

  @override
  Future<PackageInfo> getPackageInfo() async {
    if (_cachedPackageInfo != null) return _cachedPackageInfo!;
    try {
      _cachedPackageInfo = await PackageInfo.fromPlatform();
      return _cachedPackageInfo!;
    } catch (e) {
      developer.log('Failed to fetch PackageInfo: $e', name: _tag);
      return PackageInfo(
        appName: 'EasySave',
        packageName: 'com.ammananna.app',
        version: '1.2.14',
        buildNumber: '30',
      );
    }
  }

  @override
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      developer.log('Checking for updates via Google Play Core API...', name: _tag);
      final info = await InAppUpdate.checkForUpdate();
      developer.log(
        'Update check result: availability=${info.updateAvailability}, '
        'availableVersionCode=${info.availableVersionCode}, '
        'flexibleAllowed=${info.flexibleUpdateAllowed}, '
        'immediateAllowed=${info.immediateUpdateAllowed}',
        name: _tag,
      );
      return info;
    } on PlatformException catch (e) {
      // Expected when running debug APK, sideload, or outside Google Play Store.
      developer.log(
        'PlatformException during update check: ${e.code} - ${e.message}',
        name: _tag,
      );
      return null;
    } catch (e, stack) {
      developer.log('Unexpected error checking for update: $e', name: _tag, error: e, stackTrace: stack);
      return null;
    }
  }

  @override
  Future<AppUpdateResult> startFlexibleUpdate() async {
    try {
      developer.log('Starting background flexible update download...', name: _tag);
      return await InAppUpdate.startFlexibleUpdate();
    } on PlatformException catch (e) {
      developer.log('Failed to start flexible update: ${e.code} - ${e.message}', name: _tag);
      return AppUpdateResult.inAppUpdateFailed;
    } catch (e) {
      developer.log('Error starting flexible update: $e', name: _tag);
      return AppUpdateResult.inAppUpdateFailed;
    }
  }

  @override
  Future<void> completeFlexibleUpdate() async {
    try {
      developer.log('Completing flexible update and restarting application...', name: _tag);
      await InAppUpdate.completeFlexibleUpdate();
    } on PlatformException catch (e) {
      developer.log('Failed to complete flexible update: ${e.code} - ${e.message}', name: _tag);
    } catch (e) {
      developer.log('Error completing flexible update: $e', name: _tag);
    }
  }

  @override
  Future<AppUpdateResult> performImmediateUpdate() async {
    try {
      developer.log('Launching Google Play immediate fullscreen update flow...', name: _tag);
      return await InAppUpdate.performImmediateUpdate();
    } on PlatformException catch (e) {
      developer.log('Failed to perform immediate update: ${e.code} - ${e.message}', name: _tag);
      return AppUpdateResult.inAppUpdateFailed;
    } catch (e) {
      developer.log('Error performing immediate update: $e', name: _tag);
      return AppUpdateResult.inAppUpdateFailed;
    }
  }

  @override
  Future<bool> openPlayStoreListing() async {
    try {
      final marketUri = Uri.parse(_marketUri);
      if (await canLaunchUrl(marketUri)) {
        return await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      }
      final webUri = Uri.parse(_playStoreUrl);
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      developer.log('Failed to launch Play Store: $e', name: _tag);
      return false;
    }
  }
}
