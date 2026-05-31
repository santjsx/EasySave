import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/contacts_service.dart';
import '../services/speech_service.dart';
import 'system_provider.dart';

/// Wizard state model for the Contact Saver flow.
class SaveContactState {
  final String phoneNumber;
  final String recognizedName;
  final SpeechState speechState;
  final bool isSaving;
  final String errorMessage;

  const SaveContactState({
    this.phoneNumber = '',
    this.recognizedName = '',
    this.speechState = SpeechState.idle,
    this.isSaving = false,
    this.errorMessage = '',
  });

  SaveContactState copyWith({
    String? phoneNumber,
    String? recognizedName,
    SpeechState? speechState,
    bool? isSaving,
    String? errorMessage,
  }) {
    return SaveContactState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      recognizedName: recognizedName ?? this.recognizedName,
      speechState: speechState ?? this.speechState,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// State notifier to manage digit entry updates, voice inputs, and final contact insertion operations.
class SaveContactNotifier extends StateNotifier<SaveContactState> {
  final ContactsService _contactsService;
  final SpeechService _speechService;

  SaveContactNotifier({
    required ContactsService contactsService,
    required SpeechService speechService,
  })  : _contactsService = contactsService,
        _speechService = speechService,
        super(const SaveContactState());

  // -------------------------------------------------------------
  // Custom Keypad Operations (NumberEntryScreen)
  // -------------------------------------------------------------

  /// Adds a digit on the circular keypad dialer. Limits input length to 10 digits.
  void addDigit(String digit) {
    if (state.phoneNumber.length >= 10) return;
    state = state.copyWith(
      phoneNumber: state.phoneNumber + digit,
      errorMessage: '',
    );
  }

  /// Removes the last entered digit (Backspace callback).
  void removeLastDigit() {
    if (state.phoneNumber.isEmpty) return;
    state = state.copyWith(
      phoneNumber: state.phoneNumber.substring(0, state.phoneNumber.length - 1),
      errorMessage: '',
    );
  }

  /// Wipes dialed buffers on restart.
  void clearPhoneNumber() {
    state = state.copyWith(phoneNumber: '', errorMessage: '');
  }

  // -------------------------------------------------------------
  // Voice Input Operations (VoiceNameScreen)
  // -------------------------------------------------------------

  /// Binds recording events to Google STT under 'te_IN' Telugu defaults.
  Future<void> startListeningName() async {
    state = state.copyWith(
      speechState: SpeechState.listening,
      recognizedName: '',
      errorMessage: '',
    );

    try {
      // 1. Request microphone permissions cleanly (Pre-permission explanation check)
      final bool granted = await _speechService.requestMicrophonePermission();
      if (!granted) {
        state = state.copyWith(
          speechState: SpeechState.error,
          errorMessage: 'మైక్ ఉపయోగించడానికి అనుమతి లేదు', // Mic permission denied in Telugu
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
          errorMessage: 'వాయిస్ సేవలు అందుబాటులో లేవు', // Speech services not available
        );
        return;
      }

      // 3. Start listen capture
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
      debugPrint('Start listening failed: $e');
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

  /// Manually overrides name (if keyboard fallback is tapped).
  void setManualName(String name) {
    state = state.copyWith(recognizedName: name, speechState: SpeechState.result);
  }

  // -------------------------------------------------------------
  // Save Contact Persistence (ConfirmContactScreen)
  // -------------------------------------------------------------

  /// Performs contact insertion to address book and updates completion state.
  Future<bool> commitContact() async {
    if (state.phoneNumber.isEmpty || state.recognizedName.isEmpty) {
      state = state.copyWith(errorMessage: 'సరైన వివరాలు ఇవ్వండి'); // Provide correct details
      return false;
    }

    state = state.copyWith(isSaving: true, errorMessage: '');

    try {
      final bool success = await _contactsService.saveContact(
        state.recognizedName,
        state.phoneNumber,
      );

      state = state.copyWith(isSaving: false);
      return success;
    } catch (e) {
      debugPrint('Contact insertion failed: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'సేవ్ చేయడం కుదరలేదు', // Saving failed
      );
      return false;
    }
  }

  /// Complete wizard reset.
  void resetWizard() {
    state = const SaveContactState();
  }
}

/// Declares the auto-disposing save contact state engine provider.
final saveContactProvider = StateNotifierProvider.autoDispose<SaveContactNotifier, SaveContactState>((ref) {
  final contacts = ref.read(contactsServiceProvider);
  final speech = ref.read(speechServiceProvider);
  
  return SaveContactNotifier(
    contactsService: contacts,
    speechService: speech,
  );
});
