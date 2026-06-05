import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/contact_model.dart';
import '../../providers/contacts_list_provider.dart';
import '../../providers/system_provider.dart';
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
            // 1. Highly Accessible Custom Search Bar with Voice Search
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
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
                  const SizedBox(width: 12.0),
                  // Accessible Voice Search Button
                  Container(
                    width: 58.0,
                    height: 58.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2E7D32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                          blurRadius: 8.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          _startVoiceSearch(context);
                        },
                        customBorder: const CircleBorder(),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 30.0,
                        ),
                      ),
                    ),
                  ),
                ],
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
      constraints: const BoxConstraints(minHeight: 80.0), // Flexible responsive height to prevent cutoffs
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0), // Responsive padding
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
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
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
            ),
          ),
        );
      },
    );
  }

  /// Displays a customized tactile dialog for editing contact details.
  void _showRenameDialog(BuildContext context, ContactModel contact) {
    final TextEditingController nameEditController = TextEditingController(text: contact.name);
    final TextEditingController phoneEditController = TextEditingController(text: contact.phone);
    final speechService = ref.read(speechServiceProvider);

    bool isListening = false;
    String statusMessage = '';
    bool hasError = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> stopListening() async {
              await speechService.stopListening();
              if (dialogCtx.mounted) {
                setDialogState(() {
                  isListening = false;
                });
              }
            }

            Future<void> toggleListening() async {
              if (isListening) {
                await stopListening();
                return;
              }

              setDialogState(() {
                isListening = true;
                statusMessage = 'మాట్లాడండి... వింటున్నాము'; // Telugu: Speak... listening
                hasError = false;
              });

              final hasPermission = await speechService.requestMicrophonePermission();
              if (!hasPermission) {
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    isListening = false;
                    statusMessage = 'మైక్ ఉపయోగించడానికి అనుమతి లేదు';
                    hasError = true;
                  });
                }
                return;
              }

              final initialized = await speechService.initialize(
                onStatus: (status) {
                  if (status == 'notListening' && isListening) {
                    if (dialogCtx.mounted) {
                      setDialogState(() {
                        isListening = false;
                      });
                    }
                  }
                },
                onError: (err) {
                  if (dialogCtx.mounted) {
                    setDialogState(() {
                      isListening = false;
                      statusMessage = err;
                      hasError = true;
                    });
                  }
                },
              );

              if (!initialized) {
                if (dialogCtx.mounted) {
                  setDialogState(() {
                    isListening = false;
                    statusMessage = 'వాయిస్ సేవలు అందుబాటులో లేవు';
                    hasError = true;
                  });
                }
                return;
              }

              await speechService.startListening(
                onResult: (words, isFinal) {
                  if (dialogCtx.mounted) {
                    setDialogState(() {
                      nameEditController.text = words;
                      nameEditController.selection = TextSelection.fromPosition(
                        TextPosition(offset: nameEditController.text.length),
                      );
                      if (isFinal) {
                        isListening = false;
                        statusMessage = '';
                      }
                    });
                  }
                },
                onError: (err) {
                  if (dialogCtx.mounted) {
                    setDialogState(() {
                      isListening = false;
                      statusMessage = err;
                      hasError = true;
                    });
                  }
                },
              );
            }

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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
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
                        ),
                        const SizedBox(width: 8.0),
                        // Highly accessible microphone button next to Name
                        Container(
                          width: 56.0,
                          height: 56.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isListening ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                            boxShadow: [
                              BoxShadow(
                                color: (isListening ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32)).withValues(alpha: 0.3),
                                blurRadius: 8.0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.heavyImpact();
                                toggleListening();
                              },
                              customBorder: const CircleBorder(),
                              child: Icon(
                                isListening ? Icons.mic : Icons.mic_none_rounded,
                                color: Colors.white,
                                size: 28.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 8.0),
                      Text(
                        statusMessage,
                        style: TextStyle(
                          color: hasError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'NotoSansTelugu',
                        ),
                      ),
                    ],
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
              actions: [
                Wrap(
                  spacing: 12.0,
                  runSpacing: 10.0,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Cancel
                    TextButton(
                      style: TextButton.styleFrom(minimumSize: const Size(100, 48)),
                      onPressed: () async {
                        if (isListening) {
                          await speechService.stopListening();
                        }
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                      },
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
                        if (isListening) {
                          await speechService.stopListening();
                        }
                        final newName = nameEditController.text.trim();
                        final newPhone = phoneEditController.text.trim();
                        if (newName.isEmpty || newPhone.isEmpty) {
                          if (context.mounted) {
                            EasySnackBar.showError(context, 'సరైన వివరాలు ఇవ్వండి');
                          }
                          return;
                        }

                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
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
                ),
              ],
            );
          },
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
          actions: [
            Wrap(
              spacing: 12.0,
              runSpacing: 10.0,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
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

  /// Starts the voice search flow by showing an accessible bottom sheet with a pulsating mic.
  void _startVoiceSearch(BuildContext parentContext) {
    final speechService = ref.read(speechServiceProvider);
    
    // Bottom sheet state variables
    bool isListening = false;
    String recognizedText = '';
    String statusMessage = 'మాట్లాడండి... వింటున్నాము'; // Telugu: Speak... listening
    bool hasError = false;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (BuildContext sheetCtx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            
            Future<void> stopListening() async {
              await speechService.stopListening();
              if (sheetCtx.mounted) {
                setSheetState(() {
                  isListening = false;
                });
              }
            }

            Future<void> startSpeech() async {
              setSheetState(() {
                isListening = true;
                statusMessage = 'మాట్లాడండి... వింటున్నాము';
                hasError = false;
              });

              final hasPermission = await speechService.requestMicrophonePermission();
              if (!hasPermission) {
                if (sheetCtx.mounted) {
                  setSheetState(() {
                    isListening = false;
                    statusMessage = 'మైక్ ఉపయోగించడానికి అనుమతి లేదు';
                    hasError = true;
                  });
                }
                return;
              }

              final initialized = await speechService.initialize(
                onStatus: (status) {
                  debugPrint('Voice search sheet status: $status');
                  if (status == 'notListening' && isListening) {
                    if (sheetCtx.mounted) {
                      setSheetState(() {
                        isListening = false;
                      });
                    }
                  }
                },
                onError: (err) {
                  if (sheetCtx.mounted) {
                    setSheetState(() {
                      isListening = false;
                      statusMessage = err;
                      hasError = true;
                    });
                  }
                },
              );

              if (!initialized) {
                if (sheetCtx.mounted) {
                  setSheetState(() {
                    isListening = false;
                    statusMessage = 'వాయిస్ సేవలు అందుబాటులో లేవు';
                    hasError = true;
                  });
                }
                return;
              }

              await speechService.startListening(
                onResult: (words, isFinal) {
                  if (sheetCtx.mounted) {
                    setSheetState(() {
                      recognizedText = words;
                      statusMessage = 'వింటున్నాము...';
                      if (isFinal && words.trim().isNotEmpty) {
                        isListening = false;
                        // Populate search bar and filter contacts
                        _searchController.text = words;
                        _searchController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _searchController.text.length),
                        );
                        ref.read(contactsListProvider.notifier).search(words);
                        Navigator.pop(sheetCtx);
                      }
                    });
                  }
                },
                onError: (err) {
                  if (sheetCtx.mounted) {
                    setSheetState(() {
                      isListening = false;
                      statusMessage = err;
                      hasError = true;
                    });
                  }
                },
              );
            }

            // Automatically start listening when bottom sheet opens
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!isListening && !hasError && recognizedText.isEmpty && statusMessage == 'మాట్లాడండి... వింటున్నాము') {
                startSpeech();
              }
            });

            return PopScope(
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) {
                  await speechService.cancelListening();
                }
              },
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.md,
                    bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 44.0,
                        height: 5.0,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(100.0),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      
                      // Title
                      const Text(
                        'వాయిస్ సెర్చ్',
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          fontFamily: 'NotoSansTelugu',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Pulsating Mic Button
                      _VoicePulseMicButton(
                        isListening: isListening,
                        hasError: hasError,
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          if (isListening) {
                            stopListening();
                          } else {
                            startSpeech();
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Status message
                      Text(
                        statusMessage,
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: hasError ? const Color(0xFFD32F2F) : const Color(0xFF666666),
                          fontFamily: 'NotoSansTelugu',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Real-time transcript display
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                          minHeight: 100.0,
                          maxHeight: 150.0,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: const Color(0xFFC5E1A5),
                            width: 1.5,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            recognizedText.isEmpty ? 'ఇక్కడ పేరు కనిపిస్తుంది...' : recognizedText,
                            style: TextStyle(
                              fontSize: 22.0,
                              fontWeight: FontWeight.bold,
                              color: recognizedText.isEmpty ? Colors.grey[500] : const Color(0xFF2E7D32),
                              fontFamily: 'NotoSansTelugu',
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Actions Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                                minimumSize: const Size(0, 52),
                              ),
                              onPressed: () async {
                                await speechService.cancelListening();
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }
                              },
                              child: const Text(
                                'రద్దు చేయి',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  fontFamily: 'NotoSansTelugu',
                                ),
                              ),
                            ),
                          ),
                          if (hasError || (!isListening && recognizedText.isNotEmpty)) ...[
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14.0),
                                  ),
                                  minimumSize: const Size(0, 52),
                                ),
                                onPressed: () async {
                                  if (hasError) {
                                    startSpeech();
                                  } else {
                                    if (recognizedText.trim().isNotEmpty) {
                                      _searchController.text = recognizedText;
                                      _searchController.selection = TextSelection.fromPosition(
                                        TextPosition(offset: _searchController.text.length),
                                      );
                                      ref.read(contactsListProvider.notifier).search(recognizedText);
                                    }
                                    await speechService.stopListening();
                                    if (sheetCtx.mounted) {
                                      Navigator.pop(sheetCtx);
                                    }
                                  }
                                },
                                child: Text(
                                  hasError ? 'మళ్ళీ ప్రయత్నించు' : 'వెతకండి',
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NotoSansTelugu',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Pulsating microphone button for Telugu voice search feedback.
class _VoicePulseMicButton extends StatefulWidget {
  final bool isListening;
  final bool hasError;
  final VoidCallback onTap;

  const _VoicePulseMicButton({
    required this.isListening,
    required this.hasError,
    required this.onTap,
  });

  @override
  State<_VoicePulseMicButton> createState() => _VoicePulseMicButtonState();
}

class _VoicePulseMicButtonState extends State<_VoicePulseMicButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isListening) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _VoicePulseMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = widget.hasError
        ? const Color(0xFFD32F2F)
        : (widget.isListening ? const Color(0xFF2E7D32) : const Color(0xFF4CAF50));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isListening) ...[
              Container(
                width: 90.0 + (30.0 * _controller.value),
                height: 90.0 + (30.0 * _controller.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: baseColor.withValues(alpha: 0.15 * (1.0 - _controller.value)),
                ),
              ),
              Container(
                width: 90.0 + (15.0 * _controller.value),
                height: 90.0 + (15.0 * _controller.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: baseColor.withValues(alpha: 0.3 * (1.0 - _controller.value)),
                ),
              ),
            ],
            Container(
              width: 90.0,
              height: 90.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: baseColor,
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.3),
                    blurRadius: 12.0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  customBorder: const CircleBorder(),
                  child: Icon(
                    widget.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: Colors.white,
                    size: 44.0,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
