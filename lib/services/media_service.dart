import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// -------------------------------------------------------------
// Telugu Semantic Exceptions
// -------------------------------------------------------------

/// Thrown when media or camera permissions are rejected by the user.
class PhotoPermissionDeniedException implements Exception {
  final String message;
  const PhotoPermissionDeniedException([this.message = 'ఫోటోలు చూడడానికి అనుమతి లేదు']);
  @override
  String toString() => message;
}

/// Thrown when the selected file is not a supported image format.
class UnsupportedFileException implements Exception {
  final String message;
  const UnsupportedFileException([this.message = 'ఈ ఫైల్ సపోర్ట్ చేయదు (కేవలం JPG, PNG మాత్రమే)']);
  @override
  String toString() => message;
}

/// Thrown when the image file is empty or corrupted.
class CorruptedImageException implements Exception {
  final String message;
  const CorruptedImageException([this.message = 'ఈ ఫోటో పాడైపోయింది, వేరే ఫోటో ఎంచుకోండి']);
  @override
  String toString() => message;
}

// -------------------------------------------------------------
// Media Service Implementation
// -------------------------------------------------------------

/// Production-ready service wrapper managing media selection and camera snaps.
/// Integrates secure dynamic permissions checks across Android 12, 13, 14, and 15+ SDK scopes.
class MediaService {
  final ImagePicker _picker;

  MediaService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Requests and verifies gallery/photo storage permissions dynamically.
  /// Safely supports Android 14+ Selected Photos Access by checking isLimited.
  Future<bool> checkAndRequestPhotosPermission() async {
    try {
      // For Android 13+ (API 33+), check READ_MEDIA_IMAGES.
      // On Android 14+ (API 34+), this also encompasses Selected Photos Access (isLimited).
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted || photosStatus.isLimited) {
        return true;
      }
      
      // Fallback check for older APIs (Android 12 and below)
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } catch (e) {
      debugPrint('Photos permission request crashed: $e');
      return false;
    }
  }

  /// Requests and verifies microphone/camera permissions dynamically.
  Future<bool> checkAndRequestCameraPermission() async {
    try {
      final cameraStatus = await Permission.camera.request();
      return cameraStatus.isGranted;
    } catch (e) {
      debugPrint('Camera permission request crashed: $e');
      return false;
    }
  }

  /// Launches the system photo gallery picker and performs strict image validations.
  /// Throws [PhotoPermissionDeniedException], [UnsupportedFileException], or [CorruptedImageException].
  Future<String?> pickPhoto() async {
    // 1. Verify permission bounds
    final bool hasPermission = await checkAndRequestPhotosPermission();
    if (!hasPermission) {
      throw const PhotoPermissionDeniedException();
    }

    // 2. Trigger native ImagePicker gallery UI
    XFile? selectedFile;
    try {
      selectedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compressed slightly at OS level to save memory on budget devices
      );
    } catch (e) {
      debugPrint('Native ImagePicker pickImage failed: $e');
      throw const CorruptedImageException('ఫోటో ఎంచుకోవడం కుదరలేదు');
    }

    // 3. Gracefully return null on cancelled selection
    if (selectedFile == null) {
      debugPrint('User cancelled photo picker selection.');
      return null;
    }

    // 4. Validate image file integrity
    await _validateImageFile(selectedFile);

    return selectedFile.path;
  }

  /// Launches the native camera utility, snaps a photo, and performs strict validations.
  /// Throws [PhotoPermissionDeniedException], [UnsupportedFileException], or [CorruptedImageException].
  Future<String?> capturePhoto() async {
    // 1. Verify camera runtime permission (essential for budget device integrity)
    final bool hasPermission = await checkAndRequestCameraPermission();
    if (!hasPermission) {
      throw const PhotoPermissionDeniedException('కెమెరా ఉపయోగించడానికి అనుమతి లేదు');
    }

    // 2. Trigger native ImagePicker camera capture
    XFile? capturedFile;
    try {
      capturedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Compressed to save heap memory on low-tier smartphones
      );
    } catch (e) {
      debugPrint('Native ImagePicker capturePhoto failed: $e');
      throw const CorruptedImageException('ఫోటో తీయడం కుదరలేదు');
    }

    // 3. Gracefully return null on cancelled selection
    if (capturedFile == null) {
      debugPrint('User cancelled camera capture.');
      return null;
    }

    // 4. Validate captured file integrity
    await _validateImageFile(capturedFile);

    return capturedFile.path;
  }

  /// Evaluates files existence, size bounds, and extension limits.
  Future<void> _validateImageFile(XFile fileRef) async {
    final File file = File(fileRef.path);

    // Verify file existence
    if (!await file.exists()) {
      throw const CorruptedImageException();
    }

    // Verify non-zero length
    final int size = await file.length();
    if (size <= 0) {
      throw const CorruptedImageException();
    }

    // Check file extension compatibility
    final String extension = fileRef.path.split('.').last.toLowerCase();
    const supportedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
    if (!supportedExtensions.contains(extension)) {
      throw const UnsupportedFileException();
    }

    debugPrint('Validated media file successfully: ${file.path} (${(size / 1024).toStringAsFixed(2)} KB)');
  }
}
