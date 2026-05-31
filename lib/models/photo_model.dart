import 'dart:typed_data';

/// Immutable model representing a single gallery image selected or scanned.
/// Fully compatible with both ImagePicker files and photo_manager media assets.
class PhotoModel {
  final String path;
  final Uint8List? thumbnailBytes;
  final DateTime dateCreated;

  const PhotoModel({
    required this.path,
    this.thumbnailBytes,
    required this.dateCreated,
  });

  PhotoModel copyWith({
    String? path,
    Uint8List? thumbnailBytes,
    DateTime? dateCreated,
  }) {
    return PhotoModel(
      path: path ?? this.path,
      thumbnailBytes: thumbnailBytes ?? this.thumbnailBytes,
      dateCreated: dateCreated ?? this.dateCreated,
    );
  }
}
