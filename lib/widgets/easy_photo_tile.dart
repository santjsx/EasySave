import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// A production-grade gallery thumbnail item widget.
/// Enforces physical outline borders and large rounded boundaries.
class EasyPhotoTile extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;

  const EasyPhotoTile({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageFile = File(imagePath);

    return Semantics(
      button: true,
      label: 'ఫోటో', // Telugu descriptor for gallery asset reader
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          child: Material(
            color: AppDesignColors.surfaceMuted,
            child: InkWell(
              onTap: onTap,
              splashColor: AppDesignColors.primaryLight.withValues(alpha: 0.4),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  border: Border.all(
                    color: AppDesignColors.divider,
                    width: 1.5,
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: 1.0, // Force strict square format (Rule 17)
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // High-contrast fallback visual warning when files are missing
                      return const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48.0,
                          color: AppDesignColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
