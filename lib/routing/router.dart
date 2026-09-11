import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/contact_model.dart';
import '../screens/contacts/contact_details_screen.dart';
import '../screens/contacts/contact_form_screen.dart';
import '../screens/contacts/contacts_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/recent_calls/quick_save_screen.dart';
import '../screens/recent_calls/recent_calls_screen.dart';
import '../screens/save_contact/confirm_contact_screen.dart';
import '../screens/save_contact/number_entry_screen.dart';
import '../screens/save_contact/success_screen.dart';
import '../screens/save_contact/voice_name_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/share_photo/contact_picker_screen.dart';
import '../screens/share_photo/gallery_screen.dart';
import '../screens/share_photo/photo_confirm_screen.dart';
import 'routes.dart';

/// Riverpod provider for GoRouter configuration.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      // 1. Home Dashboard
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _buildLinearTransitionPage(
          state: state,
          child: const HomeScreen(),
        ),
      ),

      // 2. Contacts Manager Directory & Dedicated Sub-Screens
      GoRoute(
        path: AppRoutes.contactsList,
        pageBuilder: (context, state) => _buildLinearTransitionPage(
          state: state,
          child: const ContactsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'details',
            pageBuilder: (context, state) {
              final contact = state.extra as ContactModel;
              return _buildLinearTransitionPage(
                state: state,
                child: ContactDetailsScreen(contact: contact),
              );
            },
          ),
          GoRoute(
            path: 'form',
            pageBuilder: (context, state) {
              final contact = state.extra as ContactModel?;
              final phone = state.uri.queryParameters['phone'];
              return _buildLinearTransitionPage(
                state: state,
                child: ContactFormScreen(
                  contactToEdit: contact,
                  initialPhone: phone,
                ),
              );
            },
          ),
        ],
      ),

      // 3. Feature Flow: Contact Saver (Voice-First Flow)
      GoRoute(
        path: AppRoutes.saveContact,
        pageBuilder: (context, state) => _buildLinearTransitionPage(
          state: state,
          child: const VoiceNameScreen(),
        ),
        routes: [
          GoRoute(
            path: 'number',
            pageBuilder: (context, state) => _buildLinearTransitionPage(
              state: state,
              child: const NumberEntryScreen(),
            ),
          ),
          GoRoute(
            path: 'confirm',
            pageBuilder: (context, state) => _buildLinearTransitionPage(
              state: state,
              child: const ConfirmContactScreen(),
            ),
          ),
          GoRoute(
            path: 'success',
            pageBuilder: (context, state) => _buildLinearTransitionPage(
              state: state,
              child: const SaveContactSuccessScreen(),
            ),
          ),
        ],
      ),

      // 4. Feature Flow: WhatsApp Photo Sharer
      GoRoute(
        path: AppRoutes.sharePhoto,
        pageBuilder: (context, state) => _buildLinearTransitionPage(
          state: state,
          child: const GalleryScreen(),
        ),
        routes: [
          GoRoute(
            path: 'confirm',
            pageBuilder: (context, state) {
              final imagePath = state.uri.queryParameters['imagePath'] ?? '';
              return _buildLinearTransitionPage(
                state: state,
                child: PhotoConfirmScreen(imagePath: imagePath),
              );
            },
          ),
          GoRoute(
            path: 'contacts',
            pageBuilder: (context, state) {
              final imagePath = state.uri.queryParameters['imagePath'] ?? '';
              return _buildLinearTransitionPage(
                state: state,
                child: ContactPickerScreen(imagePath: imagePath),
              );
            },
          ),
        ],
      ),

      // 5. Feature Flow: Recent Calls & Quick Voice-Save
      GoRoute(
        path: AppRoutes.recentCalls,
        pageBuilder: (context, state) => _buildLinearTransitionPage(
          state: state,
          child: const RecentCallsScreen(),
        ),
        routes: [
          GoRoute(
            path: 'quick-save',
            pageBuilder: (context, state) {
              final phoneNumber = state.uri.queryParameters['phone'] ?? '';
              return _buildLinearTransitionPage(
                state: state,
                child: QuickSaveScreen(phoneNumber: phoneNumber),
              );
            },
          ),
        ],
      ),

      // 6. Settings Screen
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _buildLinearTransitionPage(
          state: state,
          child: const SettingsScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'పేజీ కనుగొనబడలేదు',
          style: TextStyle(
            fontSize: 22.0,
            fontFamily: 'NotoSansTelugu',
            color: Colors.red[800],
          ),
        ),
      ),
    ),
  );
});

CustomTransitionPage<void> _buildLinearTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: child,
        ),
      );
    },
  );
}
