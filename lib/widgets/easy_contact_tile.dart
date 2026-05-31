import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'easy_card.dart';

/// Highly readable contact item tile.
/// Vertical touch boundaries are locked at 72dp to prevent overlapping click zones.
/// Employs a deterministic warm color scheme circle avatar and bold Telugu typography.
class EasyContactTile extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback onTap;

  const EasyContactTile({
    super.key,
    required this.contact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Extract first letter of name for initials display
    final String initial = contact.name.isNotEmpty
        ? contact.name.characters.first.toUpperCase()
        : 'పరిచయం';

    return Semantics(
      button: true,
      label: '${contact.name}, ఫోన్ నంబర్ ${contact.phone}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: EasyCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          onTap: onTap,
          child: SizedBox(
            height: 72.0, // Expanded from 56.0 to perfectly clear the larger Telugu fonts without vertical overflow
            child: Row(
              children: [
                // 1. Initial Circle Avatar (48dp diameter)
                Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: contact.avatarColor,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: AppTypography.sectionHeader.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // 2. High-Contrast Details Text Block
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: AppTypography.sectionHeader.copyWith(
                          color: AppDesignColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        contact.phone,
                        style: AppTypography.secondaryText.copyWith(
                          color: AppDesignColors.textSecondary,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                // Arrow indicator to invite action (decorative)
                const ExcludeSemantics(
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 24.0,
                    color: AppDesignColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
