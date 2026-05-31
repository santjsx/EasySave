import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/routes.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/easy_button.dart';

/// Screen 2 of Share Photo: Confirm Photo selection.
/// Renders a full-bleed aspect-ratio layout with a large confirmation continue CTA.
class PhotoConfirmScreen extends StatelessWidget {
  final String imagePath;

  const PhotoConfirmScreen({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final imageFile = File(imagePath);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full-bleed background photo preview (Comfortable visual check)
          Positioned.fill(
            bottom: 180.0, // Leave breathing space for bottom drawer sheet
            child: Semantics(
              label: 'మీరు ఎంచుకున్న ఫోటో', // Accessible screen reader label
              child: Container(
                color: Colors.black.withOpacity(0.05),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 96.0,
                        color: AppDesignColors.textSecondary,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 2. Translucent top-bar enclosing the massive back navigation button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: CircleAvatar(
                    radius: 28.0,
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 28.0,
                      ),
                      tooltip: 'వెనక్కి', // Accessible tooltip
                      onPressed: () {
                        context.pop();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Fixed high-contrast bottom action drawer sheet (180dp height)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 190.0,
            child: Container(
              decoration: BoxDecoration(
                color: AppDesignColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.cardRadius),
                  topRight: Radius.circular(AppSpacing.cardRadius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24.0,
                    offset: const Offset(0, -6),
                  ),
                ],
                border: const Border(
                  top: BorderSide(
                    color: AppDesignColors.divider,
                    width: 2.0,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ఈ ఫోటో సరిగ్గా ఉందా?', // Telugu: "Is this photo okay?"
                    style: AppTypography.sectionHeader.copyWith(
                      color: AppDesignColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Giant trigger push to recipient picker
                  EasyButton(
                    label: 'ఈ ఫోటో పంపండి →', // Telugu: "Send this Photo"
                    onPressed: () {
                      context.push(
                        '${AppRoutes.contactPicker}?imagePath=${Uri.encodeComponent(imagePath)}',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
