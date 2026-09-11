import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Represents the high-level in-app update state.
enum UpdateStatus {
  /// Initial idle state or no update checked yet.
  idle,

  /// Currently checking Google Play / update servers.
  checking,

  /// A new update is available.
  available,

  /// Update is actively downloading.
  downloading,

  /// Update download completed and ready for 1-tap installation / restart.
  downloaded,

  /// App is already at the latest version.
  upToDate,

  /// Update check failed or offline.
  error,
}

/// Metadata representation for GitHub release artifacts.
class GitHubReleaseInfo {
  final String tagName;
  final String version;
  final String name;
  final String body;
  final String apkDownloadUrl;
  final int apkSizeBytes;

  const GitHubReleaseInfo({
    required this.tagName,
    required this.version,
    required this.name,
    required this.body,
    required this.apkDownloadUrl,
    required this.apkSizeBytes,
  });
}

/// Abstract contract for update operations (enables clean mocking in tests).
abstract class IUpdateService {
  Future<PackageInfo> getPackageInfo();
  Future<AppUpdateInfo?> checkForUpdate();
  Future<AppUpdateResult> startFlexibleUpdate();
  Future<void> completeFlexibleUpdate();
  Future<AppUpdateResult> performImmediateUpdate();
  Future<bool> openPlayStoreListing();

  // Direct OTA Engine additions (GitHub & Native Package Installer)
  Future<GitHubReleaseInfo?> checkGitHubRelease();
  Future<File?> downloadGitHubApk(
    String downloadUrl,
    void Function(double progress) onProgress,
  );
  Future<bool> installApk(String filePath);
}

/// Production implementation with Dual-Engine support:
/// 1. Primary engine for Sideloaded / GitHub Release builds: Direct streaming download + native package installer handoff.
/// 2. Secondary engine for Google Play Store builds: Google Play In-App Updates (Play Core API).
class UpdateService implements IUpdateService {
  static const String _tag = 'UpdateService';
  static const String _githubRepo = 'santjsx/EasySave';
  static const String _githubReleaseApiUrl =
      'https://api.github.com/repos/$_githubRepo/releases/latest';
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ammananna.app';
  static const String _marketUri =
      'market://details?id=com.ammananna.app';

  PackageInfo? _cachedPackageInfo;

  /// Compares semver strings (e.g. "1.3.5" vs "1.3.4").
  /// Returns > 0 if remote is strictly newer than local, 0 if equal, < 0 if local is newer.
  static int compareSemVer(String remote, String local) {
    List<int> parse(String v) {
      final clean = v.replaceAll(RegExp(r'[^0-9.]'), '');
      if (clean.isEmpty) return [0, 0, 0];
      return clean.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    }

    final rParts = parse(remote);
    final lParts = parse(local);

    final maxLen = rParts.length > lParts.length ? rParts.length : lParts.length;
    for (int i = 0; i < maxLen; i++) {
      final r = i < rParts.length ? rParts[i] : 0;
      final l = i < lParts.length ? lParts[i] : 0;
      if (r != l) {
        return r.compareTo(l);
      }
    }
    return 0;
  }

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
        version: '1.3.5',
        buildNumber: '36',
      );
    }
  }

  @override
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      developer.log('Checking for updates via Google Play Core API...', name: _tag);
      final info = await InAppUpdate.checkForUpdate();
      developer.log(
        'Google Play check result: availability=${info.updateAvailability}, '
        'availableVersionCode=${info.availableVersionCode}',
        name: _tag,
      );
      return info;
    } on PlatformException catch (e) {
      developer.log(
        'PlatformException during Google Play update check: ${e.code} - ${e.message}',
        name: _tag,
      );
      return null;
    } catch (e, stack) {
      developer.log('Unexpected error checking Play Store: $e', name: _tag, error: e, stackTrace: stack);
      return null;
    }
  }

  @override
  Future<GitHubReleaseInfo?> checkGitHubRelease() async {
    try {
      developer.log('Checking GitHub Releases API: $_githubReleaseApiUrl', name: _tag);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(Uri.parse(_githubReleaseApiUrl));
      request.headers.set('User-Agent', 'EasySave-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');
      final response = await request.close();

      if (response.statusCode != 200) {
        developer.log('GitHub API returned status ${response.statusCode}', name: _tag);
        return null;
      }

      final responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> json = jsonDecode(responseBody) as Map<String, dynamic>;

      final String tagName = (json['tag_name'] as String?) ?? '';
      final String releaseName = (json['name'] as String?) ?? tagName;
      final String releaseBody = (json['body'] as String?) ?? '';
      final List<dynamic> assets = (json['assets'] as List<dynamic>?) ?? [];

      String apkUrl = '';
      int apkSize = 0;
      for (final asset in assets) {
        final name = (asset['name'] as String?) ?? '';
        if (name.toLowerCase().endsWith('.apk')) {
          apkUrl = (asset['browser_download_url'] as String?) ?? '';
          apkSize = (asset['size'] as int?) ?? 0;
          break;
        }
      }

      if (apkUrl.isEmpty && tagName.isNotEmpty) {
        apkUrl = 'https://github.com/$_githubRepo/releases/download/$tagName/app-release.apk';
      }

      final String cleanVersion = tagName.replaceAll(RegExp(r'[^0-9.]'), '');
      return GitHubReleaseInfo(
        tagName: tagName,
        version: cleanVersion,
        name: releaseName,
        body: releaseBody,
        apkDownloadUrl: apkUrl,
        apkSizeBytes: apkSize,
      );
    } catch (e) {
      developer.log('Failed to query GitHub Releases: $e', name: _tag);
      return null;
    }
  }

  @override
  Future<File?> downloadGitHubApk(
    String downloadUrl,
    void Function(double progress) onProgress,
  ) async {
    HttpClient? client;
    IOSink? sink;
    try {
      developer.log('Starting streaming APK download from $downloadUrl', name: _tag);
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 20);

      // Handle HTTP redirects explicitly if required
      Uri currentUri = Uri.parse(downloadUrl);
      HttpClientResponse response;
      int redirectCount = 0;

      while (true) {
        final request = await client.getUrl(currentUri);
        request.headers.set('User-Agent', 'EasySave-App');
        request.followRedirects = false;
        response = await request.close();

        if (response.isRedirect && response.headers.value(HttpHeaders.locationHeader) != null) {
          redirectCount++;
          if (redirectCount > 5) {
            developer.log('Too many redirects downloading APK', name: _tag);
            return null;
          }
          final location = response.headers.value(HttpHeaders.locationHeader)!;
          currentUri = Uri.parse(location);
        } else {
          break;
        }
      }

      if (response.statusCode != HttpStatus.ok) {
        developer.log('Failed to download APK. Status: ${response.statusCode}', name: _tag);
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final targetFile = File('${tempDir.path}/EasySave-update.apk');
      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }

      sink = targetFile.openWrite();
      final int totalLength = response.contentLength;
      int receivedLength = 0;

      await for (final chunk in response) {
        receivedLength += chunk.length;
        sink.add(chunk);
        if (totalLength > 0) {
          final progress = (receivedLength / totalLength).clamp(0.0, 1.0);
          onProgress(progress);
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (await targetFile.exists() && await targetFile.length() > 0) {
        developer.log('APK download finished: ${targetFile.path} (${await targetFile.length()} bytes)', name: _tag);
        onProgress(1.0);
        return targetFile;
      }
      return null;
    } catch (e) {
      developer.log('Error downloading APK: $e', name: _tag);
      return null;
    } finally {
      await sink?.close();
      client?.close();
    }
  }

  @override
  Future<bool> installApk(String filePath) async {
    try {
      developer.log('Triggering native package installer for: $filePath', name: _tag);
      const platform = MethodChannel('com.ammananna.app/direct_call');
      final bool? result = await platform.invokeMethod<bool>('installApk', {'filePath': filePath});
      return result == true;
    } catch (e) {
      developer.log('Error invoking native installApk: $e', name: _tag);
      return false;
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
