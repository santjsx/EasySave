import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/call_log_model.dart';
import '../../providers/call_log_provider.dart';
import '../../routing/routes.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/easy_button.dart';
import '../../widgets/easy_snackbar.dart';

/// Screen displaying system call history logs (Recent Calls list) for Telugu-only elderly users.
/// Custom structures match duplicate entries, call states, and direct voice-saving prompts.
class RecentCallsScreen extends ConsumerWidget {
  const RecentCallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callLogsState = ref.watch(callLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ఫోన్ కాల్స్', // Telugu: "Recent Calls"
          style: AppTypography.appName.copyWith(
            color: AppDesignColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28.0),
          tooltip: 'వెనక్కి',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: callLogsState.when(
            data: (logs) => _buildCallLogsList(context, logs),
            loading: () => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 5.0,
                color: AppDesignColors.primary,
              ),
            ),
            error: (error, stack) => _buildPermissionDeniedScreen(context, ref, error),
          ),
        ),
      ),
    );
  }

  /// Builds a highly scrollable lazy list of callers with O(1) matching performance metrics.
  Widget _buildCallLogsList(BuildContext context, List<CallLogEntry> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.phone_missed_rounded,
              size: 96.0,
              color: AppDesignColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'కాల్ రికార్డులు ఏమీ లేవు', // Telugu: "No call logs"
              style: AppTypography.primaryLabel.copyWith(
                color: AppDesignColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: logs.length,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      separatorBuilder: (context, index) => const Divider(
        color: AppDesignColors.divider,
        thickness: 1.5,
      ),
      itemBuilder: (context, index) {
        final CallLogEntry entry = logs[index];

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              // 1. Request and verify CALL_PHONE permission first using permission_handler
              final status = await Permission.phone.request();
              if (status.isGranted) {
                // 2. Place direct call bypassing dialer keypad via native MethodChannel
                const platform = MethodChannel('com.ammananna.app/direct_call');
                try {
                  await platform.invokeMethod('makeCall', {
                    'phoneNumber': entry.phoneNumber,
                  });
                } catch (e) {
                  // Fallback to standard url_launcher dialer if native call fails
                  final Uri phoneUri = Uri(scheme: 'tel', path: entry.phoneNumber);
                  try {
                    await launchUrl(phoneUri);
                  } catch (_) {
                    if (context.mounted) {
                      EasySnackBar.showError(context, 'కాల్ చేయడం కుదరలేదు');
                    }
                  }
                }
              } else {
                if (context.mounted) {
                  EasySnackBar.showError(context, 'కాల్ చేయడానికి పర్మిషన్ ఇవ్వాలి');
                }
              }
            },
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  // 1. Initial Avatar (warm palette deterministic hash match)
                  Semantics(
                    excludeSemantics: true,
                    child: CircleAvatar(
                      radius: 30.0,
                      backgroundColor: entry.avatarColor,
                      child: Text(
                        entry.isSavedContact
                            ? entry.contactName.substring(0, 1).toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 26.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // 2. Caller Details & Info Card
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Contact Name / Phone Number Header
                        if (entry.isSavedContact)
                          Text(
                            '${entry.contactName}${entry.callCount > 1 ? " (${entry.callCount})" : ""}',
                            style: AppTypography.confirmedName.copyWith(
                              color: AppDesignColors.textPrimary,
                              fontSize: 22.0, // Enlarged bold focus
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          SizedBox(
                            height: 28.0,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                entry.phoneNumber,
                                style: AppTypography.confirmedName.copyWith(
                                  color: AppDesignColors.textPrimary,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 4.0),

                        // If saved, show phone number below
                        if (entry.isSavedContact) ...[
                          SizedBox(
                            height: 24.0,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                entry.phoneNumber,
                                style: AppTypography.secondaryText.copyWith(
                                  color: AppDesignColors.textSecondary,
                                  fontSize: 18.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                        ],

                        // Call Type Description (Natural Telugu) & Call Time
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: 4.0,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  entry.typeIcon,
                                  size: 20.0,
                                  color: entry.typeColor,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  entry.telugifiedCallType,
                                  style: AppTypography.bodyText.copyWith(
                                    color: entry.typeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              entry.telugifiedTime,
                              style: AppTypography.secondaryText.copyWith(
                                color: AppDesignColors.textSecondary,
                                fontSize: 16.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3. CTA Action: Direct Save Voice-Overlay (Rendered strictly for unsaved)
                  if (!entry.isSavedContact) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Semantics(
                      label: 'సేవ్ చేయండి', // Accessible voice override trigger
                      child: SizedBox(
                        width: 120.0,
                        height: 52.0, // High visibility tactile button
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppDesignColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                            ),
                          ),
                          onPressed: () {
                            // Jump directly to quick voice-saving workflow!
                            context.push(
                              '${AppRoutes.quickSave}?phone=${Uri.encodeComponent(entry.phoneNumber)}',
                            );
                          },
                          child: const Text(
                            'సేవ్ చేయండి', // Telugu: "Save contact"
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansTelugu',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // For saved contacts, render a large phone call icon
                    const SizedBox(width: AppSpacing.xs),
                    Semantics(
                      label: 'కాల్ చేయండి', // "Make a call" in Telugu
                      child: Container(
                        width: 56.0,
                        height: 56.0,
                        decoration: BoxDecoration(
                          color: AppDesignColors.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone_forwarded_rounded,
                          size: 28.0,
                          color: AppDesignColors.success,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a high-contrast elegant fallback screen in Telugu for gracefully handling permission denials.
  Widget _buildPermissionDeniedScreen(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.security_rounded,
                size: 96.0,
                color: AppDesignColors.error,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'కాల్ రికార్డులు అనుమతి', // Telugu: "Call records permission"
                style: AppTypography.appName.copyWith(
                  color: AppDesignColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'మీ ఫోన్‌కు వచ్చిన లేదా మిస్ అయిన కాల్స్ నంబర్లను చూసి సులభంగా సేవ్ చేసుకోవడానికి, ఈ యాప్‌కు కాల్ రికార్డుల అనుమతి తప్పనిసరిగా ఇవ్వాలి.', 
                // "To see calls and save easily, this app needs call records permission."
                style: AppTypography.bodyText.copyWith(
                  color: AppDesignColors.textSecondary,
                  fontSize: 18.0,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              EasyButton(
                label: 'అనుమతి ఇవ్వండి', // Telugu: "Give Permission"
                onPressed: () {
                  ref.read(callLogProvider.notifier).requestPermissionAndFetch();
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
