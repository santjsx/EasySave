import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/call_log_model.dart';
import '../services/call_log_service.dart';
import 'system_provider.dart';

/// State notifier to manage system call history queries, permissions, and refresh actions.
class CallLogNotifier extends StateNotifier<AsyncValue<List<CallLogEntry>>> {
  final CallLogService _callLogService;

  CallLogNotifier(this._callLogService) : super(const AsyncValue.loading()) {
    checkPermissionAndFetch();
  }

  /// Silently verifies permission status and fetches call history logs if authorized.
  Future<void> checkPermissionAndFetch() async {
    state = const AsyncValue.loading();
    try {
      final List<CallLogEntry> logs = await _callLogService.getRecentCalls();
      state = AsyncValue.data(logs);
    } catch (err, stack) {
      // Permission not granted or native read error
      debugPrint('Check and fetch call logs failed: $err');
      state = AsyncValue.error(err, stack);
    }
  }

  /// Explicitly requests call log access from the OS and performs immediate loading on success.
  Future<void> requestPermissionAndFetch() async {
    state = const AsyncValue.loading();
    try {
      final bool granted = await _callLogService.checkAndRequestPermission();
      if (!granted) {
        state = AsyncValue.error(
          Exception('కాల్ రికార్డులు చూడటానికి అనుమతి అవసరం'), // Permission needed in Telugu
          StackTrace.current,
        );
        return;
      }
      final List<CallLogEntry> logs = await _callLogService.getRecentCalls();
      state = AsyncValue.data(logs);
    } catch (err, stack) {
      debugPrint('Permission request call logs failed: $err');
      state = AsyncValue.error(err, stack);
    }
  }

  /// Performs a synchronous list refresh action (e.g. after a contact is saved).
  Future<void> refreshCalls() async {
    try {
      final List<CallLogEntry> logs = await _callLogService.getRecentCalls();
      state = AsyncValue.data(logs);
    } catch (err, stack) {
      debugPrint('Refresh call logs failed: $err');
      state = AsyncValue.error(err, stack);
    }
  }
}

/// Auto-disposing call history logs provider declaration.
final callLogProvider = StateNotifierProvider.autoDispose<CallLogNotifier, AsyncValue<List<CallLogEntry>>>((ref) {
  final service = ref.read(callLogServiceProvider);
  return CallLogNotifier(service);
});
