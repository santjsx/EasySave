import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'media_service.dart';
export 'media_service.dart';

// -------------------------------------------------------------
// Service Implementation
// -------------------------------------------------------------

/// Production-ready service managing gallery selection and photo validation.
class PhotoService {
  final ImagePicker _picker;

  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Requests native storage/photo permissions based on active Android SDK.
  /// Fully supports Android 14+ Selected Photos Access by checking isLimited.
  Future<bool> checkAndRequestPermissions() async {
    try {
      // For Android 13+ (API 33+), check READ_MEDIA_IMAGES.
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }
      
      // Fallback check for older APIs
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } catch (e) {
      debugPrint('Media permission request crashed: $e');
      return false;
    }
  }

  /// Launches the native system photo gallery and performs complete image integrity checks.
  /// Returns the validated image [File] or null if selection was cancelled.
  /// Throws [PhotoPermissionDeniedException], [UnsupportedFileException], or [CorruptedImageException].
  Future<File?> pickPhotoFromGallery() async {
    // 1. Verify permissions
    final bool hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) {
      throw const PhotoPermissionDeniedException();
    }

    // 2. Trigger native ImagePicker gallery UI
    XFile? pickedFile;
    try {
      pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Slightly compress at OS level to save memory on budget devices
      );
    } catch (e) {
      debugPrint('Native ImagePicker pickImage failed: $e');
      throw const CorruptedImageException('ఫోటో ఎంచుకోవడం కుదరలేదు');
    }

    // 3. Handle Cancelled selection (return null gracefully)
    if (pickedFile == null) {
      debugPrint('User cancelled the photo picker selection.');
      return null;
    }

    final File file = File(pickedFile.path);

    // 4. Validate File existence
    if (!await file.exists()) {
      throw const CorruptedImageException();
    }

    // 5. Validate File size (Empty / Corrupted check)
    final int size = await file.length();
    if (size <= 0) {
      throw const CorruptedImageException();
    }

    // 6. Validate File extension (Unsupported format check)
    final String extension = pickedFile.path.split('.').last.toLowerCase();
    const supportedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
    if (!supportedExtensions.contains(extension)) {
      throw const UnsupportedFileException();
    }

    debugPrint('Successfully validated picked image: ${file.path} (${(size / 1024).toStringAsFixed(2)} KB)');
    return file;
  }
}
