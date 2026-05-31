import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/home/home_screen.dart';
import '../screens/save_contact/confirm_contact_screen.dart';
import '../screens/save_contact/number_entry_screen.dart';
import '../screens/save_contact/success_screen.dart';
import '../screens/save_contact/voice_name_screen.dart';
import '../screens/share_photo/contact_picker_screen.dart';
import '../screens/share_photo/gallery_screen.dart';
import '../screens/share_photo/photo_confirm_screen.dart';
import '../screens/recent_calls/recent_calls_screen.dart';
import '../screens/recent_calls/quick_save_screen.dart';
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

      // -------------------------------------------------------------
      // Feature Flow 1: Contact Saver (Voice-First Flow)
      // -------------------------------------------------------------
      GoRoute(
        path: AppRoutes.saveContact,
        pageBuilder: (context, state) => _buildLinearTransitionPage(
          state: state,
          child: const VoiceNameScreen(), // Base route resolves Voice Name input first
        ),
        routes: [
          // Keyboard dialer entry: /save-contact/number
          GoRoute(
            path: 'number',
            pageBuilder: (context, state) => _buildLinearTransitionPage(
              state: state,
              child: const NumberEntryScreen(),
            ),
          ),
          // Final Details confirm: /save-contact/confirm
          GoRoute(
            path: 'confirm',
            pageBuilder: (context, state) => _buildLinearTransitionPage(
              state: state,
              child: const ConfirmContactScreen(),
            ),
          ),
          // Success dismissal: /save-contact/success
          GoRoute(
            path: 'success',
            pageBuilder: (context, state) => _buildLinearTransitionPage(
              state: state,
              child: const SaveContactSuccessScreen(),
            ),
          ),
        ],
      ),

      // -------------------------------------------------------------
      // Feature Flow 2: WhatsApp Photo Sharer
      // -------------------------------------------------------------
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

      // -------------------------------------------------------------
      // Feature Flow 3: Recent Calls & Quick Voice-Save
      // -------------------------------------------------------------
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
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.linear));

      return SlideTransition(
        position: animation.drive(slideTween),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
  );
}
