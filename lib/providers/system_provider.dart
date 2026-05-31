import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repository/contacts_repository.dart';
import '../repository/contacts_repository_impl.dart';
import '../services/contacts_service.dart';
import '../services/media_service.dart';
import '../services/speech_service.dart';
import '../services/storage_service.dart';
import '../services/whatsapp_service.dart';

import '../services/photo_service.dart';
import '../services/call_log_service.dart';

// -------------------------------------------------------------
// 1. Service Provider Singletons (Dependency Injection)
// -------------------------------------------------------------

/// Provider for system call history logs.
final callLogServiceProvider = Provider<CallLogService>((ref) {
  final contacts = ref.read(contactsServiceProvider);
  return CallLogService(contacts);
});

/// Provider for the storage service. Must be overridden in main.dart once SharedPreferences loads.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider was not overridden inside main.dart.');
});

/// Provider for the Telugu speech-to-text service.
final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechService();
});

/// Provider for the contacts abstract repository contract.
final contactsRepositoryProvider = Provider<ContactsRepository>((ref) {
  return ContactsRepositoryImpl();
});

/// Provider for reading and writing native contacts.
final contactsServiceProvider = Provider<ContactsService>((ref) {
  final repo = ref.read(contactsRepositoryProvider);
  return ContactsService(repo);
});

/// Provider for photo selection.
final mediaServiceProvider = Provider<MediaService>((ref) {
  return MediaService();
});

/// Provider for high-integrity photo selections.
final photoServiceProvider = Provider<PhotoService>((ref) {
  return PhotoService();
});

/// Provider for WhatsApp sharing intents.
final whatsappServiceProvider = Provider<WhatsAppService>((ref) {
  return WhatsAppService();
});

// -------------------------------------------------------------
// 2. Global State Notifiers (Permissions & Lifecycle)
// -------------------------------------------------------------

class PermissionState {
  final bool hasContactsPermission;
  final bool hasWriteContactsPermission;
  final bool hasPhotosPermission;
  final bool hasMicPermission;

  const PermissionState({
    this.hasContactsPermission = false,
    this.hasWriteContactsPermission = false,
    this.hasPhotosPermission = false,
    this.hasMicPermission = false,
  });

  PermissionState copyWith({
    bool? hasContactsPermission,
    bool? hasWriteContactsPermission,
    bool? hasPhotosPermission,
    bool? hasMicPermission,
  }) {
    return PermissionState(
      hasContactsPermission: hasContactsPermission ?? this.hasContactsPermission,
      hasWriteContactsPermission: hasWriteContactsPermission ?? this.hasWriteContactsPermission,
      hasPhotosPermission: hasPhotosPermission ?? this.hasPhotosPermission,
      hasMicPermission: hasMicPermission ?? this.hasMicPermission,
    );
  }
}

/// Provider for managing permission flags.
class PermissionNotifier extends StateNotifier<PermissionState> {
  PermissionNotifier() : super(const PermissionState());

  void updateContactsPermission(bool value) {
    state = state.copyWith(hasContactsPermission: value);
  }

  void updateWriteContactsPermission(bool value) {
    state = state.copyWith(hasWriteContactsPermission: value);
  }

  void updatePhotosPermission(bool value) {
    state = state.copyWith(hasPhotosPermission: value);
  }

  void updateMicPermission(bool value) {
    state = state.copyWith(hasMicPermission: value);
  }
}

final permissionsProvider = StateNotifierProvider<PermissionNotifier, PermissionState>((ref) {
  return PermissionNotifier();
});
