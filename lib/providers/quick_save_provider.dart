import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/contacts_service.dart';
import '../services/speech_service.dart';
import 'call_log_provider.dart';
import 'system_provider.dart';

/// State model for the Quick Voice-Save overlay.
class QuickSaveState {
  final String phoneNumber;
  final String recognizedName;
  final SpeechState speechState;
  final bool isSaving;
  final String errorMessage;

  const QuickSaveState({
    required this.phoneNumber,
    this.recognizedName = '',
    this.speechState = SpeechState.idle,
    this.isSaving = false,
    this.errorMessage = '',
  });

  QuickSaveState copyWith({
    String? phoneNumber,
    String? recognizedName,
    SpeechState? speechState,
    bool? isSaving,
    String? errorMessage,
  }) {
    return QuickSaveState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      recognizedName: recognizedName ?? this.recognizedName,
      speechState: speechState ?? this.speechState,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// State notifier to manage voice capture, microphone permissions, and final persistence.
class QuickSaveNotifier extends StateNotifier<QuickSaveState> {
  final ContactsService _contactsService;
  final SpeechService _speechService;
  final Ref _ref;

  QuickSaveNotifier({
    required String phoneNumber,
    required ContactsService contactsService,
    required SpeechService speechService,
    required Ref ref,
  })  : _contactsService = contactsService,
        _speechService = speechService,
        _ref = ref,
        super(QuickSaveState(phoneNumber: phoneNumber));

  /// Binds recording events to Google STT under 'te_IN' Telugu defaults.
  Future<void> startListeningName() async {
    state = state.copyWith(
      speechState: SpeechState.listening,
      recognizedName: '',
      errorMessage: '',
    );

    try {
      // 1. Request microphone permissions
      final bool granted = await _speechService.requestMicrophonePermission();
      if (!granted) {
        state = state.copyWith(
          speechState: SpeechState.error,
          errorMessage: 'మైక్ ఉపయోగించడానికి అనుమతి లేదు', // Mic permission denied
        );
        return;
      }

      // 2. Initialize speech-to-text configurations
      final bool initialized = await _speechService.initialize(
        onStatus: (status) {
          if (status == 'listening') {
            state = state.copyWith(speechState: SpeechState.listening);
          } else if (status == 'notListening') {
            if (state.speechState == SpeechState.listening && state.recognizedName.isEmpty) {
              state = state.copyWith(speechState: SpeechState.idle);
            }
          }
        },
        onError: (err) {
          state = state.copyWith(
            speechState: SpeechState.error,
            errorMessage: err,
          );
        },
      );

      if (!initialized) {
        state = state.copyWith(
          speechState: SpeechState.error,
          errorMessage: 'వాయిస్ సేవలు అందుబాటులో లేవు', // Speech services unavailable
        );
        return;
      }

      // 3. Start voice capture
      await _speechService.startListening(
        onResult: (words, isFinal) {
          state = state.copyWith(
            recognizedName: words,
            speechState: isFinal ? SpeechState.result : SpeechState.listening,
          );
        },
        onError: (err) {
          state = state.copyWith(
            speechState: SpeechState.error,
            errorMessage: err,
          );
        },
      );
    } catch (e) {
      debugPrint('Quick save speech capture crashed: $e');
      state = state.copyWith(
        speechState: SpeechState.error,
        errorMessage: 'మైక్ ప్రారంభం కాలేదు', // Mic failed
      );
    }
  }

  /// Halts active recording.
  Future<void> stopListeningName() async {
    await _speechService.stopListening();
    state = state.copyWith(speechState: SpeechState.result);
  }

  /// Clear name details for retries.
  void resetVoiceName() {
    state = state.copyWith(recognizedName: '', speechState: SpeechState.idle, errorMessage: '');
  }

  /// Manually overrides name.
  void setManualName(String name) {
    state = state.copyWith(recognizedName: name, speechState: SpeechState.result);
  }

  /// Saves the caller contact to the address book, then triggers a silent refresh on callLogProvider.
  Future<bool> commitContact() async {
    if (state.recognizedName.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'పేరు చెప్పండి'); // Tell the name in Telugu
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: '');

    try {
      final bool success = await _contactsService.saveContact(
        state.recognizedName.trim(),
        state.phoneNumber,
      );

      if (success) {
        // Dynamic invalidation: immediately refresh the call log provider list!
        _ref.read(callLogProvider.notifier).refreshCalls();
      }

      state = state.copyWith(isSaving: false);
      return success;
    } catch (e) {
      debugPrint('Contacts saving failed during quick save: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: e.toString().contains('ఇప్పటికే') 
            ? 'ఈ పరిచయం ఇప్పటికే ఉంది' // Already exists
            : 'సేవ్ చేయడం కుదరలేదు', // Save failed
      );
      return false;
    }
  }
}

/// Parameter-based auto-disposing quick save provider.
final quickSaveProvider = StateNotifierProvider.autoDispose.family<QuickSaveNotifier, QuickSaveState, String>((ref, phoneNumber) {
  final contacts = ref.read(contactsServiceProvider);
  final speech = ref.read(speechServiceProvider);
  
  return QuickSaveNotifier(
    phoneNumber: phoneNumber,
    contactsService: contacts,
    speechService: speech,
    ref: ref,
  );
});
