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
  AppUpdateResult flexibleResult = AppUpdateResult.success;
  AppUpdateResult immediateResult = AppUpdateResult.success;
  bool completeFlexibleCalled = false;
  bool openPlayStoreCalled = false;

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
      // Allow microtasks to complete initial _loadVersionInfo
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.currentVersion, equals('1.2.14'));
      expect(notifier.state.currentBuildNumber, equals('30'));
      expect(notifier.state.fullVersionString, equals('1.2.14 (30)'));
      expect(notifier.state.status, equals(UpdateStatus.idle));
    });

    test('2. checkForUpdate marks upToDate when no update is available on Play Store', () async {
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

      await notifier.checkForUpdate(silent: false);

      expect(notifier.state.status, equals(UpdateStatus.upToDate));
      expect(notifier.state.isFlexibleAllowed, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('3. checkForUpdate identifies available flexible update correctly', () async {
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
    });

    test('4. startFlexibleUpdate transitions to downloading and then downloaded', () async {
      mockService.flexibleResult = AppUpdateResult.success;

      await notifier.startFlexibleUpdate();

      expect(notifier.state.status, equals(UpdateStatus.downloaded));
    });

    test('5. completeFlexibleUpdate calls restart install hook on service', () async {
      await notifier.completeFlexibleUpdate();

      expect(mockService.completeFlexibleCalled, isTrue);
    });

    test('6. Sideload or non-Play Store error gracefully handles fallback', () async {
      mockService.mockUpdateInfo = null; // Emulates PlatformException caught in service

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
  });
}
