import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:amma_nanna_app/providers/update_provider.dart';
import 'package:amma_nanna_app/services/update_service.dart';

class MockUpdateService implements IUpdateService {
  PackageInfo packageInfo = PackageInfo(
    appName: 'EasySave',
    packageName: 'com.ammananna.app',
    version: '1.2.14',
    buildNumber: '30',
  );

  AppUpdateInfo? mockUpdateInfo;
  GitHubReleaseInfo? mockGitHubRelease;
  AppUpdateResult flexibleResult = AppUpdateResult.success;
  AppUpdateResult immediateResult = AppUpdateResult.success;
  bool completeFlexibleCalled = false;
  bool openPlayStoreCalled = false;
  bool installApkCalled = false;
  String? installedApkPath;

  @override
  Future<PackageInfo> getPackageInfo() async => packageInfo;

  @override
  Future<AppUpdateInfo?> checkForUpdate() async => mockUpdateInfo;

  @override
  Future<AppUpdateResult> startFlexibleUpdate() async => flexibleResult;

  @override
  Future<void> completeFlexibleUpdate() async {
    completeFlexibleCalled = true;
  }

  @override
  Future<AppUpdateResult> performImmediateUpdate() async => immediateResult;

  @override
  Future<bool> openPlayStoreListing() async {
    openPlayStoreCalled = true;
    return true;
  }

  @override
  Future<GitHubReleaseInfo?> checkGitHubRelease() async => mockGitHubRelease;

  @override
  Future<File?> downloadGitHubApk(
    String downloadUrl,
    void Function(double progress) onProgress,
  ) async {
    onProgress(0.5);
    onProgress(1.0);
    return File('/mock/cache/EasySave-update.apk');
  }

  @override
  Future<bool> installApk(String filePath) async {
    installApkCalled = true;
    installedApkPath = filePath;
    return true;
  }
}

void main() {
  group('In-App OTA Updates - Unit Tests', () {
    late MockUpdateService mockService;
    late UpdateNotifier notifier;

    setUp(() {
      mockService = MockUpdateService();
      notifier = UpdateNotifier(mockService);
    });

    test('1. Initial state loads dynamic PackageInfo version and build number', () async {
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.currentVersion, equals('1.2.14'));
      expect(notifier.state.currentBuildNumber, equals('30'));
      expect(notifier.state.fullVersionString, equals('1.2.14 (30)'));
      expect(notifier.state.status, equals(UpdateStatus.idle));
    });

    test('2. checkForUpdate marks upToDate when no update is available on Play Store or GitHub', () async {
      mockService.mockUpdateInfo = AppUpdateInfo(
        updateAvailability: UpdateAvailability.updateNotAvailable,
        immediateUpdateAllowed: false,
        immediateAllowedPreconditions: null,
        flexibleUpdateAllowed: false,
        flexibleAllowedPreconditions: null,
        availableVersionCode: null,
        installStatus: InstallStatus.unknown,
        packageName: 'com.ammananna.app',
        clientVersionStalenessDays: null,
        updatePriority: 0,
      );
      mockService.mockGitHubRelease = null;

      await notifier.checkForUpdate(silent: false);

      expect(notifier.state.status, equals(UpdateStatus.upToDate));
      expect(notifier.state.isFlexibleAllowed, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('3. checkForUpdate identifies available flexible update correctly from Google Play', () async {
      mockService.mockUpdateInfo = AppUpdateInfo(
        updateAvailability: UpdateAvailability.updateAvailable,
        immediateUpdateAllowed: false,
        immediateAllowedPreconditions: null,
        flexibleUpdateAllowed: true,
        flexibleAllowedPreconditions: null,
        availableVersionCode: 31,
        installStatus: InstallStatus.unknown,
        packageName: 'com.ammananna.app',
        clientVersionStalenessDays: 1,
        updatePriority: 2,
      );

      await notifier.checkForUpdate(silent: false);

      expect(notifier.state.status, equals(UpdateStatus.available));
      expect(notifier.state.availableVersionCode, equals(31));
      expect(notifier.state.isFlexibleAllowed, isTrue);
      expect(notifier.state.isImmediateAllowed, isFalse);
      expect(notifier.state.isGitHubSource, isFalse);
    });

    test('4. startFlexibleUpdate transitions to downloading and then downloaded for Google Play', () async {
      mockService.flexibleResult = AppUpdateResult.success;

      await notifier.startFlexibleUpdate();

      expect(notifier.state.status, equals(UpdateStatus.downloaded));
    });

    test('5. completeFlexibleUpdate calls restart install hook on service', () async {
      await notifier.completeFlexibleUpdate();

      expect(mockService.completeFlexibleCalled, isTrue);
    });

    test('6. Sideload or non-Play Store error gracefully handles fallback', () async {
      mockService.mockUpdateInfo = null; // Emulates PlatformException from Play Core
      mockService.mockGitHubRelease = null; // Offline or no release available

      // In silent mode (e.g. background startup check), status remains idle
      await notifier.checkForUpdate(silent: true);
      expect(notifier.state.status, equals(UpdateStatus.idle));

      // In manual mode (user tapped in settings), status switches to error with fallback guidance
      await notifier.checkForUpdate(silent: false);
      expect(notifier.state.status, equals(UpdateStatus.error));
      expect(notifier.state.errorMessage, isNotNull);

      // User taps open Play Store
      await notifier.openPlayStore();
      expect(mockService.openPlayStoreCalled, isTrue);
    });

    test('7. GitHub Releases OTA update detected when newer version available for sideloaded app', () async {
      mockService.mockUpdateInfo = null; // Sideloaded APK has no Play Core connection
      mockService.mockGitHubRelease = const GitHubReleaseInfo(
        tagName: 'v1.3.5',
        version: '1.3.5',
        name: 'v1.3.5 Release',
        body: 'New features and bugfixes',
        apkDownloadUrl: 'https://github.com/santjsx/EasySave/releases/download/v1.3.5/app-release.apk',
        apkSizeBytes: 25000000,
      );

      await notifier.checkForUpdate(silent: false);

      expect(notifier.state.status, equals(UpdateStatus.available));
      expect(notifier.state.isGitHubSource, isTrue);
      expect(notifier.state.availableVersionName, equals('1.3.5'));
      expect(notifier.state.downloadUrl, contains('v1.3.5/app-release.apk'));
    });

    test('8. GitHub streaming OTA download and native package installation handoff', () async {
      mockService.mockUpdateInfo = null;
      mockService.mockGitHubRelease = const GitHubReleaseInfo(
        tagName: 'v1.3.5',
        version: '1.3.5',
        name: 'v1.3.5 Release',
        body: 'Bugfixes',
        apkDownloadUrl: 'https://github.com/santjsx/EasySave/releases/download/v1.3.5/app-release.apk',
        apkSizeBytes: 25000000,
      );

      await notifier.checkForUpdate(silent: false);
      expect(notifier.state.status, equals(UpdateStatus.available));

      await notifier.startFlexibleUpdate();

      expect(notifier.state.status, equals(UpdateStatus.downloaded));
      expect(notifier.state.downloadProgress, equals(1.0));
      expect(mockService.installApkCalled, isTrue);
      expect(mockService.installedApkPath, equals('/mock/cache/EasySave-update.apk'));
    });

    test('9. Semantic version comparator behaves accurately across major, minor, and patch', () {
      expect(UpdateService.compareSemVer('1.3.5', '1.3.4'), greaterThan(0));
      expect(UpdateService.compareSemVer('1.4.0', '1.3.9'), greaterThan(0));
      expect(UpdateService.compareSemVer('2.0.0', '1.99.99'), greaterThan(0));
      expect(UpdateService.compareSemVer('v1.3.4', '1.3.4'), equals(0));
      expect(UpdateService.compareSemVer('1.3.4', '1.3.5'), lessThan(0));
    });
  });
}
