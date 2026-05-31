import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/contact_model.dart';
import '../../providers/contacts_list_provider.dart';
import '../../theme/spacing.dart';
import '../../widgets/easy_button.dart';
import '../../widgets/easy_snackbar.dart';

/// Highly accessible Contacts Manager Screen for EasySave.
/// Provides large tactile targets, clean Noto Sans Telugu scripts,
/// search capabilities, calling shortcuts, and editing/deleting confirmation dialogs.
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7), // Warm accessible light green background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAF7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2E7D32), size: 28.0),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'నా పరిచయాలు',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontSize: 26.0,
            fontWeight: FontWeight.w900,
            fontFamily: 'NotoSansTelugu',
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Highly Accessible Custom Search Bar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(contactsListProvider.notifier).search(val);
                  },
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansTelugu',
                  ),
                  decoration: InputDecoration(
                    hintText: 'ఇక్కడ పేరు చెప్పి వెతకండి...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 18.0,
                      fontFamily: 'NotoSansTelugu',
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2E7D32), size: 28.0),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel_rounded, color: Colors.grey, size: 24.0),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(contactsListProvider.notifier).search('');
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
                  ),
                ),
              ),
            ),

            // 2. Contacts Scrollable List
            Expanded(
              child: contactsState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E7D32),
                        strokeWidth: 4.0,
                      ),
                    )
                  : contactsState.errorMessage.isNotEmpty
                      ? _buildErrorPlaceholder(contactsState.errorMessage)
                      : contactsState.filteredContacts.isEmpty
                          ? _buildEmptyPlaceholder()
                          : ListView.separated(
                              itemCount: contactsState.filteredContacts.length,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              separatorBuilder: (context, index) => const SizedBox(height: 12.0),
                              itemBuilder: (context, index) {
                                final ContactModel contact = contactsState.filteredContacts[index];
                                return _buildContactTile(context, contact);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single contact list tile with minimum 72dp height touch target constraints.
  Widget _buildContactTile(BuildContext context, ContactModel contact) {
    return Container(
      height: 80.0, // Minimum tactile size 72dp+
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showContactOptionsSheet(context, contact),
          borderRadius: BorderRadius.circular(20.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              children: [
                // 1. Large Warm Avatar (56px)
                CircleAvatar(
                  radius: 28.0,
                  backgroundColor: contact.avatarColor,
                  child: Text(
                    contact.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14.0),

                // 2. Name & Phone Block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          color: Color(0xFF212121),
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansTelugu',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        contact.phone,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 16.0,
                          fontFamily: 'NotoSansTelugu',
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Trailing arrow details indicator
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 24.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Displays the custom full-screen/modal options sheet for a selected contact.
  void _showContactOptionsSheet(BuildContext context, ContactModel contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (BuildContext sheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decorative Pill Handle
              Container(
                width: 44.0,
                height: 5.0,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(100.0),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Header Avatar & Info
              CircleAvatar(
                radius: 36.0,
                backgroundColor: contact.avatarColor,
                child: Text(
                  contact.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                contact.name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansTelugu',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4.0),
              Text(
                contact.phone,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 18.0,
                  fontFamily: 'NotoSansTelugu',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action 1: Call Now (Massive Green Tactile Button)
              EasyButton(
                label: 'ఫోన్ చేయండి',
                icon: Icons.phone_in_talk_rounded,
                color: const Color(0xFF2E7D32), // Green
                onPressed: () async {
                  Navigator.pop(sheetCtx);
                  final status = await Permission.phone.request();
                  if (status.isGranted) {
                    const platform = MethodChannel('com.ammananna.app/direct_call');
                    try {
                      await platform.invokeMethod('makeCall', {
                        'phoneNumber': contact.phone,
                      });
                    } catch (_) {
                      final Uri phoneUri = Uri(scheme: 'tel', path: contact.phone);
                      await launchUrl(phoneUri);
                    }
                  } else {
                    if (context.mounted) {
                      EasySnackBar.showError(context, 'కాల్ చేయడానికి పర్మిషన్ ఇవ్వాలి');
                    }
                  }
                },
              ),
              const SizedBox(height: 12.0),

              // Action 2: Rename / Edit (Massive Amber Tactile Button)
              EasyButton(
                label: 'పేరు మార్చండి',
                icon: Icons.edit_note_rounded,
                color: const Color(0xFFC17B3F), // Turmeric Amber
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _showRenameDialog(context, contact);
                },
              ),
              const SizedBox(height: 12.0),

              // Action 3: Delete / Remove (Massive Red Tactile Button)
              EasyButton(
                label: 'డిలీట్ చేయండి',
                icon: Icons.delete_forever_rounded,
                color: const Color(0xFFD32F2F), // Accessible Red
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _showDeleteConfirmDialog(context, contact);
                },
              ),
              const SizedBox(height: 12.0),

              // Action 4: Close Sheet
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56.0),
                ),
                onPressed: () => Navigator.pop(sheetCtx),
                child: const Text(
                  'రద్దు చేయి',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansTelugu',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Displays a customized tactile dialog for editing contact details.
  void _showRenameDialog(BuildContext context, ContactModel contact) {
    final TextEditingController nameEditController = TextEditingController(text: contact.name);
    final TextEditingController phoneEditController = TextEditingController(text: contact.phone);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          title: const Text(
            'వివరాలు మార్చండి',
            style: TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoSansTelugu',
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name Field Label
                const Text(
                  'పేరు',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansTelugu',
                  ),
                ),
                const SizedBox(height: 6.0),
                TextField(
                  controller: nameEditController,
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Color(0xFFC17B3F), width: 2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Phone Field Label
                const Text(
                  'ఫోన్ నంబర్',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NotoSansTelugu',
                  ),
                ),
                const SizedBox(height: 6.0),
                TextField(
                  controller: phoneEditController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Color(0xFFC17B3F), width: 2.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            // Cancel
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(100, 48)),
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'రద్దు చేయి',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansTelugu',
                ),
              ),
            ),
            // Commit Save (Update)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () async {
                final newName = nameEditController.text.trim();
                final newPhone = phoneEditController.text.trim();
                if (newName.isEmpty || newPhone.isEmpty) {
                  EasySnackBar.showError(context, 'సరైన వివరాలు ఇవ్వండి');
                  return;
                }

                Navigator.pop(dialogCtx);
                final success = await ref
                    .read(contactsListProvider.notifier)
                    .updateContact(contact.id, newName, newPhone);

                if (success) {
                  if (context.mounted) {
                    EasySnackBar.showSuccess(context, 'వివరాలు మార్చబడ్డాయి!');
                  }
                } else {
                  if (context.mounted) {
                    EasySnackBar.showError(context, 'సేవ్ చేయడం కుదరలేదు');
                  }
                }
              },
              child: const Text(
                'సేవ్ చేయండి',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansTelugu',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Displays the red-themed delete confirmation dialog.
  void _showDeleteConfirmDialog(BuildContext context, ContactModel contact) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 28.0),
              SizedBox(width: 8.0),
              Text(
                'డిలీట్ చేయాలా?',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansTelugu',
                ),
              ),
            ],
          ),
          content: Text(
            'మీరు నిజంగా నిశ్చయంగా "${contact.name}" ని డిలీట్ చేయాలనుకుంటున్నారా?',
            style: TextStyle(
              fontSize: 18.0,
              color: Colors.grey[800],
              height: 1.4,
              fontFamily: 'NotoSansTelugu',
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            // Cancel Action
            TextButton(
              style: TextButton.styleFrom(minimumSize: const Size(100, 48)),
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'రద్దు చేయి',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansTelugu',
                ),
              ),
            ),
            // Confirmed Delete Action (Red)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final success = await ref
                    .read(contactsListProvider.notifier)
                    .deleteContact(contact.id);

                if (success) {
                  if (context.mounted) {
                    EasySnackBar.showSuccess(context, 'పరిచయం తీసివేయబడింది!');
                  }
                } else {
                  if (context.mounted) {
                    EasySnackBar.showError(context, 'డిలీట్ చేయడం కుదరలేదు');
                  }
                }
              },
              child: const Text(
                'డిలీట్ చేయి',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NotoSansTelugu',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds a friendly placeholder card if contacts permission is missing or lists fail.
  Widget _buildErrorPlaceholder(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48.0),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansTelugu',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => ref.read(contactsListProvider.notifier).fetchContacts(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                minimumSize: const Size(150, 48),
              ),
              child: const Text(
                'మళ్ళీ ప్రయత్నించండి',
                style: TextStyle(fontSize: 16.0, fontFamily: 'NotoSansTelugu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a peaceful placeholder card when no contacts are found.
  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'పరిచయాలు ఏమీ లేవు',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 20.0,
            fontFamily: 'NotoSansTelugu',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
