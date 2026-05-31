import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/media_provider.dart';
import '../../routing/routes.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/easy_card.dart';
import '../../widgets/easy_loading.dart';
import '../../widgets/easy_snackbar.dart';

/// Gallery Screen of Share Photo flow.
/// Displays two massive visual cards for choosing from the album or snapping a direct picture.
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sharePhotoProvider);
    final notifier = ref.read(sharePhotoProvider.notifier);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: 'వెనక్కి', // Accessible tooltip
              onPressed: () {
                notifier.resetState();
                context.pop();
              },
            ),
            title: Text(
              'ఫోటో ఎంచుకోండి', // Telugu: "Choose a Photo"
              style: AppTypography.appName,
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'ఎక్కడి నుండి ఫోటో పంపించాలి?', // Telugu: "Where to send photo from?"
                    style: AppTypography.sectionHeader.copyWith(
                      color: AppDesignColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Card Option 1: Gallery Selection (Turmeric Amber Card)
                  Expanded(
                    child: EasyCard(
                      backgroundColor: AppDesignColors.primaryLight,
                      borderColor: AppDesignColors.primary,
                      borderWidth: 2.0,
                      onTap: () async {
                        final bool success = await notifier.selectPhotoFromGallery();
                        if (success && context.mounted) {
                          final path = ref.read(sharePhotoProvider).selectedImagePath;
                          // Redirect directly to Contact Picker Screen
                          context.push('${AppRoutes.contactPicker}?imagePath=${Uri.encodeComponent(path)}');
                        } else if (state.errorMessage.isNotEmpty && context.mounted) {
                          EasySnackBar.showError(context, state.errorMessage);
                        }
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const ExcludeSemantics(
                              child: Icon(
                                Icons.photo_library_outlined,
                                size: 72.0,
                                color: AppDesignColors.primaryDark,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'ఫోన్ గ్యాలరీ', // Telugu: "Phone Gallery"
                              style: AppTypography.primaryLabel.copyWith(
                                color: AppDesignColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'గ్యాలరీ నుండి ఫోటో ఎంచుకోవడానికి', // Telugu description
                              style: AppTypography.secondaryText,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Card Option 2: Camera Capture (High contrast white card)
                  Expanded(
                    child: EasyCard(
                      borderColor: AppDesignColors.divider,
                      borderWidth: 2.0,
                      onTap: () async {
                        final bool success = await notifier.selectPhotoFromCamera();
                        if (success && context.mounted) {
                          final path = ref.read(sharePhotoProvider).selectedImagePath;
                          // Redirect directly to Contact Picker Screen
                          context.push('${AppRoutes.contactPicker}?imagePath=${Uri.encodeComponent(path)}');
                        } else if (state.errorMessage.isNotEmpty && context.mounted) {
                          EasySnackBar.showError(context, state.errorMessage);
                        }
                      },
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const ExcludeSemantics(
                              child: Icon(
                                Icons.camera_alt_outlined,
                                size: 72.0,
                                color: AppDesignColors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'కెమెరాతో ఫోటో తీయండి', // Telugu: "Snap with Camera"
                              style: AppTypography.primaryLabel.copyWith(
                                color: AppDesignColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'వెంటనే ఫోటో తీసి పంపించడానికి', // Telugu description
                              style: AppTypography.secondaryText,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
        if (state.isLoading)
          const EasyLoading(
            label: 'ఫోటో లోడ్ అవుతోంది...', // Telugu: "Photo loading..."
          ),
      ],
    );
  }
}
