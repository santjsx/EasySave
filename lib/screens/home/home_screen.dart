import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/call_log_model.dart';
import '../../providers/call_log_provider.dart';
import '../../routing/routes.dart';
import '../../theme/spacing.dart';
import '../../widgets/easy_snackbar.dart';

/// Redesigned Home Screen Dashboard of EasyConnect (Amma Nanna App).
/// Strictly adheres to modern accessibility-first mobile UI/UX principles,
/// utilizing a Warm Green Accessibility Theme, soft shadows, large avatars,
/// and compact action cards at the bottom.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callLogsState = ref.watch(callLogProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7), // Warm Green Accessibility Background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAF7),
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90.0, // Breathing room
        title: Column(
          children: [
            Text(
              'EasySave',
              style: TextStyle(
                color: const Color(0xFF2E7D32), // Primary Green
                fontSize: 30.0,
                fontWeight: FontWeight.w900,
                fontFamily: 'NotoSansTelugu',
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'మీ సులభమైన సేవ్ యాప్', // Telugu Tagline
              style: TextStyle(
                color: const Color(0xFF556B2F),
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSansTelugu',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 28.0, color: Color(0xFF2E7D32)),
            onPressed: () => _showSettingsExplanationDialog(context),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------------------------------------------------------------
              // Main Section: Recent Call Logs Card (80-85% of screen)
              // -------------------------------------------------------------
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Clean white card background
                    borderRadius: BorderRadius.circular(28.0), // Rounded card container 24px-32px
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16.0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Card Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_in_talk_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 26.0,
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  'ఇటీవల కాల్స్', // Title in Telugu script
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'NotoSansTelugu',
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                context.push(AppRoutes.recentCalls);
                              },
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'అన్ని చూడండి', // "View all" in Telugu
                                      style: TextStyle(
                                        color: const Color(0xFF2E7D32),
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'NotoSansTelugu',
                                      ),
                                    ),
                                    const SizedBox(width: 2.0),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFF2E7D32),
                                      size: 20.0,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        color: Color(0xFFF1F8E9),
                        thickness: 1.5,
                        height: 1.0,
                      ),
                      // Call Feed List (Scrollable preview inside Card)
                      Expanded(
                        child: callLogsState.when(
                          data: (logs) => _buildRecentCallsList(context, ref, logs),
                          loading: () => const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2E7D32),
                              strokeWidth: 4.0,
                            ),
                          ),
                          error: (error, stack) => _buildPermissionCTACard(context, ref),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // -------------------------------------------------------------
              // Bottom Section: Highly Accessible Action Column Panel
              // -------------------------------------------------------------
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card 1: My Contacts Manager Card (Full Width Green Card)
                  Container(
                    height: 84.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9), // Soft Theme-Matching Light Green
                      borderRadius: BorderRadius.circular(24.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          context.push(AppRoutes.contactsList);
                        },
                        borderRadius: BorderRadius.circular(24.0),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.contacts_rounded,
                                color: Color(0xFF2E7D32), // Primary Green
                                size: 36.0,
                              ),
                              const SizedBox(width: 14.0),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'నా పరిచయాలు', // My Contacts in Telugu
                                      style: TextStyle(
                                        color: const Color(0xFF1B5E20),
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'NotoSansTelugu',
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      'చూడండి, మార్చండి, తీసేయండి', // View, edit, delete in Telugu
                                      style: TextStyle(
                                        color: const Color(0xFF388E3C),
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'NotoSansTelugu',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF2E7D32),
                                size: 24.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Card 2 & 3 Row: Save Contact & Share Photo
                  SizedBox(
                    height: 84.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card 2: Save Contact (Soft Warm Amber Background)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1), // Soft Amber background
                              borderRadius: BorderRadius.circular(24.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10.0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  context.push(AppRoutes.saveContact);
                                },
                                borderRadius: BorderRadius.circular(24.0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.person_add_alt_1_rounded,
                                        color: Color(0xFF8D6E63),
                                        size: 28.0,
                                      ),
                                      const SizedBox(width: 8.0),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'కొత్త నంబర్',
                                              style: TextStyle(
                                                color: const Color(0xFF5D4037),
                                                fontSize: 16.0,
                                                height: 1.2,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: 'NotoSansTelugu',
                                              ),
                                            ),
                                            Text(
                                              'సేవ్ చేయండి',
                                              style: TextStyle(
                                                color: const Color(0xFF5D4037),
                                                fontSize: 16.0,
                                                height: 1.2,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: 'NotoSansTelugu',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Color(0xFF5D4037),
                                        size: 16.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: AppSpacing.sm),

                        // Card 3: Share Photo (Soft Light Blue Background)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD), // Soft light blue background
                              borderRadius: BorderRadius.circular(24.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10.0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  context.push(AppRoutes.sharePhoto);
                                },
                                borderRadius: BorderRadius.circular(24.0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        color: Color(0xFF1976D2),
                                        size: 28.0,
                                      ),
                                      const SizedBox(width: 8.0),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ఫోటో పంపండి',
                                              style: TextStyle(
                                                color: const Color(0xFF0D47A1),
                                                fontSize: 16.0,
                                                height: 1.2,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: 'NotoSansTelugu',
                                              ),
                                            ),
                                            Text(
                                              '(WhatsApp)',
                                              style: TextStyle(
                                                color: const Color(0xFF0D47A1),
                                                fontSize: 14.0,
                                                height: 1.2,
                                                fontWeight: FontWeight.w900,
                                                fontFamily: 'NotoSansTelugu',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Color(0xFF0D47A1),
                                        size: 16.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the top-feed list of the 4 most recent system call history items with generous spacing.
  Widget _buildRecentCallsList(BuildContext context, WidgetRef ref, List<CallLogEntry> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'కాల్ రికార్డులు ఏమీ లేవు',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 18.0,
              fontFamily: 'NotoSansTelugu',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final top4Logs = logs.take(4).toList();

    return ListView.separated(
      itemCount: top4Logs.length,
      padding: const EdgeInsets.all(8.0),
      physics: const NeverScrollableScrollPhysics(), // Clean static dashboard preview
      separatorBuilder: (context, index) => const SizedBox(height: 14.0), // Generous spacing between rows
      itemBuilder: (context, index) {
        final CallLogEntry entry = top4Logs[index];

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              // Direct dialing on tap
              final status = await Permission.phone.request();
              if (status.isGranted) {
                const platform = MethodChannel('com.ammananna.app/direct_call');
                try {
                  await platform.invokeMethod('makeCall', {
                    'phoneNumber': entry.phoneNumber,
                  });
                } catch (e) {
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
            borderRadius: BorderRadius.circular(20.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  // 1. Large circular avatar (64px / radius 32)
                  CircleAvatar(
                    radius: 32.0, // Large circular avatar (64px)
                    backgroundColor: entry.avatarColor,
                    child: Text(
                      entry.isSavedContact
                          ? entry.contactName.substring(0, 1).toUpperCase()
                          : 'అ', // Unsaved clever Telugu label 'అ'
                      style: const TextStyle(
                        fontSize: 26.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14.0),

                  // 2. Name / Number Middle Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (entry.isSavedContact)
                          Text(
                            '${entry.contactName}${entry.callCount > 1 ? " (${entry.callCount})" : ""}',
                            style: const TextStyle(
                              color: Color(0xFF212121), // Text Primary
                              fontSize: 20.0, // Large bold name (20-24px)
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansTelugu',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else
                          SizedBox(
                            height: 26.0,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                entry.phoneNumber,
                                style: const TextStyle(
                                  color: Color(0xFF212121),
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'NotoSansTelugu',
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 4.0),
                        if (entry.isSavedContact)
                          SizedBox(
                            height: 20.0,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                entry.phoneNumber,
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 16.0,
                                  fontFamily: 'NotoSansTelugu',
                                ),
                              ),
                            ),
                          )
                        else
                          Text(
                            'సేవ్ చేయండి', // Under unsaved phone show red call-to-action
                            style: TextStyle(
                              color: const Color(0xFFD32F2F), // Red missed status color
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansTelugu',
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 3. Right Status Block: Call Status Icon, Label, Time, and Green Save Button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                entry.typeIcon,
                                size: 18.0,
                                color: entry.typeColor,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                entry.telugifiedCallType,
                                style: TextStyle(
                                  color: entry.typeColor, // Green, Blue, or Red accent
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'NotoSansTelugu',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            entry.telugifiedTime,
                            style: TextStyle(
                              color: const Color(0xFF666666),
                              fontSize: 14.0,
                              fontFamily: 'NotoSansTelugu',
                            ),
                          ),
                          // Unsaved: Render dark green pill button under the status block
                          if (!entry.isSavedContact) ...[
                            const SizedBox(height: 6.0),
                            GestureDetector(
                              onTap: () {
                                context.push(
                                  '${AppRoutes.quickSave}?phone=${Uri.encodeComponent(entry.phoneNumber)}',
                                );
                              },
                              child: Container(
                                width: 110.0,
                                height: 34.0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32), // Primary Green pill button
                                  borderRadius: BorderRadius.circular(100.0),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'సేవ్ చేయండి',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NotoSansTelugu',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey,
                        size: 24.0,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a graceful permission call-to-action block within Card 1 if access is denied.
  Widget _buildPermissionCTACard(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.security_rounded,
                color: Color(0xFFD32F2F),
                size: 48.0,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'అనుమతి అవసరం',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansTelugu',
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'మీకు వచ్చిన ఫోన్ కాల్స్ ఇక్కడ చూసి నేరుగా కాల్ చేయడానికి మరియు సేవ్ చేయడానికి కాల్ రికార్డుల పర్మిషన్ ఇవ్వండి.',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14.0,
                  height: 1.4,
                  fontFamily: 'NotoSansTelugu',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                onPressed: () {
                  ref.read(callLogProvider.notifier).requestPermissionAndFetch();
                },
                child: const Text(
                  'అనుమతి ఇవ్వండి',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansTelugu',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a friendly Settings & Info dialog on gear tap.
  void _showSettingsExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          title: const Text(
            'Settings & Info',
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Developer Credits
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.code_rounded, color: Color(0xFF2E7D32), size: 22.0),
                      const SizedBox(width: 10.0),
                      const Expanded(
                        child: Text(
                          'Developed by Santhosh Reddy',
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),

                // 2. Privacy Policy Card
                InkWell(
                  onTap: () => _showPolicyDialog(context, 'Privacy Policy', 
                    'Your trust is our priority. EasySave does not collect, track, or share any of your contacts, call histories, or photos. Everything is processed purely locally on your device to guarantee absolute privacy and security.'),
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.privacy_tip_outlined, color: Colors.grey, size: 20.0),
                        SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14.0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),

                // 3. Terms of Service Card
                InkWell(
                  onTap: () => _showPolicyDialog(context, 'Terms of Service', 
                    'By using EasySave, you agree that your contact directories, dialers, and photo assets are managed offline under your direct local control. The app is provided as-is without remote storage or third-party integrations.'),
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.description_outlined, color: Colors.grey, size: 20.0),
                        SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            'Terms of Service',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(80, 48)),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Opens a sub-dialog displaying policies in English.
  void _showPolicyDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Text(
              body,
              style: TextStyle(
                fontSize: 15.0,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
