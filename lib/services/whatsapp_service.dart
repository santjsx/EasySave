import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Exception thrown when neither WhatsApp nor WhatsApp Business is installed on the target device.
class WhatsAppNotInstalledException implements Exception {
  final String message;
  WhatsAppNotInstalledException([this.message = 'WhatsApp ఇన్స్టాల్ అయిలేదు']); // Default in Telugu
  @override
  String toString() => message;
}

/// Service wrapper managing direct sharing interactions with WhatsApp/WhatsApp Business on Android.
/// Enforces photo size bounds (Rule 9 and Rule 20) and copies image targets to safe cache folders.
class WhatsAppService {
  static const String fileProviderAuthority = 'com.ammananna.app.fileprovider';

  WhatsAppService();

  /// Compresses, caches, and shares a photo to WhatsApp targeting a normalized phone number.
  /// If WhatsApp is missing, falls back to WhatsApp Business. If both are missing, throws [WhatsAppNotInstalledException].
  Future<void> sharePhoto(File photo, String phoneNumber) async {
    try {
      // 1. Verify WhatsApp presence using URL schemes (Rule 9 fallback checking)
      final Uri whatsappUri = Uri.parse('whatsapp://send?phone=$phoneNumber');
      final Uri whatsappBusinessUri = Uri.parse('whatsapp-w4b://send?phone=$phoneNumber');
      
      bool hasWhatsapp = await canLaunchUrl(whatsappUri);
      bool hasWhatsappBusiness = await canLaunchUrl(whatsappBusinessUri);

      if (!hasWhatsapp && !hasWhatsappBusiness) {
        debugPrint('Both WhatsApp and WhatsApp Business are absent on this device.');
        throw WhatsAppNotInstalledException();
      }

      // 2. High-performance photo compression under 5MB to preserve RAM on budget devices (Rule 9)
      final File compressedFile = await _compressPhoto(photo);

      // 3. Copy file to a dedicated sharing directory inside the app cache (Rule 9)
      final File shareableFile = await _copyToCacheDirectory(compressedFile);

      // 4. Trigger direct WhatsApp intent sharing or use fallback
      debugPrint('Triggering native intent sharing for: ${shareableFile.path}');
      
      try {
        if (Platform.isAndroid) {
          const platform = MethodChannel('com.ammananna.app/direct_call');
          final bool success = await platform.invokeMethod<bool>('shareToWhatsApp', {
            'imagePath': shareableFile.path,
            'phoneNumber': phoneNumber,
          }) ?? false;
          
          if (!success) {
            debugPrint('Direct WhatsApp intent sharing failed/returned false. Falling back to share sheet.');
            await Share.shareXFiles(
              [XFile(shareableFile.path)],
              subject: 'అమ్మానాన్న ఫోటో',
            );
          }
        } else {
          await Share.shareXFiles(
            [XFile(shareableFile.path)],
            subject: 'అమ్మానాన్న ఫోటో',
          );
        }
      } catch (e) {
        debugPrint('Error using direct WhatsApp channel: $e. Falling back to share sheet.');
        await Share.shareXFiles(
          [XFile(shareableFile.path)],
          subject: 'అమ్మానాన్న ఫోటో',
        );
      }

    } on WhatsAppNotInstalledException {
      rethrow;
    } catch (e) {
      debugPrint('Error occurred inside WhatsAppService: $e');
      throw Exception('WhatsApp లో పంపించడం కుదరలేదు'); // Telugu generic error
    }
  }

  /// Reduces image size under 5MB using flutter_image_compress.
  Future<File> _compressPhoto(File originalFile) async {
    final int originalSize = await originalFile.length();
    debugPrint('Original image size: ${(originalSize / (1024 * 1024)).toStringAsFixed(2)} MB');

    if (originalSize <= 5 * 1024 * 1024) {
      return originalFile; // No compression needed if already under 5MB
    }

    final tempDir = await getTemporaryDirectory();
    final String targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Compress to JPEG with 80% quality
    final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
      originalFile.path,
      targetPath,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    if (compressedFile == null) {
      debugPrint('Photo compression returned null. Using original file as fallback.');
      return originalFile;
    }

    final File resultFile = File(compressedFile.path);
    final int compressedSize = await resultFile.length();
    debugPrint('Compressed image size: ${(compressedSize / (1024 * 1024)).toStringAsFixed(2)} MB');
    
    return resultFile;
  }

  /// Copies a target image to the app cache directory to secure cross-app reading access.
  Future<File> _copyToCacheDirectory(File sourceFile) async {
    final Directory cacheDir = await getTemporaryDirectory();
    
    // Create a unique clean filename inside cache
    final String fileName = 'share_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String destinationPath = '${cacheDir.path}/$fileName';

    final File destinationFile = await sourceFile.copy(destinationPath);
    debugPrint('Successfully copied compressed image to sharing cache: $destinationPath');
    
    return destinationFile;
  }
}
