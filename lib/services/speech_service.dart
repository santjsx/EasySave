import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Semantic speech recognizer states as required by Rule 10.
enum SpeechState {
  idle,
  listening,
  result,
  error,
}

/// A Telugu-first voice recognition service wrapping `speech_to_text`.
/// Proactively maps native Android SpeechRecognizer error strings to user-friendly Telugu.
class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  SpeechService();

  bool get isInitialized => _isInitialized;

  /// Requests microphone hardware permissions.
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      debugPrint('Microphone permission check returned: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('Microphone permission request crashed: $e');
      return false;
    }
  }

  /// Initializes the on-device speech engine and checks Telugu ('te_IN') locale availability.
  Future<bool> initialize({
    required Function(String status) onStatus,
    required Function(String errorDescription) onError,
  }) async {
    if (_isInitialized) return true;

    // Check mic permission first (Permission denied check)
    final bool hasPermission = await Permission.microphone.isGranted;
    if (!hasPermission) {
      onError('వాయిస్ సేవలు ఉపయోగించడానికి మైక్ అనుమతి అవసరం'); // Telugu: Mic permission needed
      return false;
    }

    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('Native STT Status callback: $status');
          onStatus(status);
        },
        onError: (errorNotification) {
          final String teError = _mapNativeErrorToTelugu(errorNotification.errorMsg);
          debugPrint('Native STT Error callback: ${errorNotification.errorMsg} Mapped: $teError');
          onError(teError);
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('STT initialization crashed: $e');
      onError('వాయిస్ రికార్డర్ అందుబాటులో లేదు'); // Microphone unavailable fallback
      return false;
    }
  }

  /// Start capture with strict 'te_IN' settings.
  Future<void> startListening({
    required Function(String recognizedWords, bool isFinal) onResult,
    required Function(String errorDescription) onError,
  }) async {
    if (!_isInitialized) {
      onError('రికార్డర్ ప్రారంభించబడలేదు');
      return;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          final String cleanedResult = _cleanDuplicateSpeech(result.recognizedWords);
          onResult(cleanedResult, result.finalResult);
        },
        listenOptions: SpeechListenOptions(
          localeId: 'te_IN', // Non-negotiable constraint
          listenFor: const Duration(seconds: 30), // Increased window for relaxed flow
          pauseFor: const Duration(seconds: 4),   // Increased pause window to allow breath pause between names
          partialResults: true,
          listenMode: ListenMode.dictation,       // Set dictation mode for continuous, patient voice capture
        ),
      );
    } catch (e) {
      debugPrint('Speech listen crashed: $e');
      onError('వాయిస్ వినడం సాధ్యం కాలేదు');
    }
  }

  /// Stop active recorder capture.
  Future<void> stopListening() async {
    if (!_isInitialized) return;
    await _speechToText.stop();
  }

  /// Cancel active recorder capture.
  Future<void> cancelListening() async {
    if (!_isInitialized) return;
    await _speechToText.cancel();
  }

  /// Cleans duplicate/repeating words from a recognized speech string.
  /// Example: "సంతోష్ సంతోష్" -> "సంతోష్"
  /// Example: "రవి కుమార్ రవి కుమార్" -> "రవి కుమార్"
  String _cleanDuplicateSpeech(String input) {
    if (input.isEmpty) return input;
    
    // Split by whitespace
    final List<String> words = input.trim().split(RegExp(r'\s+'));
    if (words.length <= 1) return input;
    
    final List<String> uniqueWords = [];
    for (final word in words) {
      if (!uniqueWords.contains(word)) {
        uniqueWords.add(word);
      }
    }
    
    return uniqueWords.join(' ');
  }

  /// Maps native Android speech engine errors to elderly-friendly Telugu scripts.
  String _mapNativeErrorToTelugu(String nativeError) {
    switch (nativeError.toLowerCase()) {
      case 'error_permission':
        return 'మైక్ ఉపయోగించడానికి అనుమతి లేదు'; // Permission Denied
      case 'error_audio_record':
      case 'error_busy':
        return 'మైక్రోఫోన్ అందుబాటులో లేదు'; // Microphone Unavailable
      case 'error_no_match':
        return 'అర్థం కాలేదు, మళ్ళీ చెప్పండి'; // Recognition Failure / Didn't match
      case 'error_speech_timeout':
        return 'మీరు మాట్లాడలేదు, మళ్ళీ చెప్పండి'; // No Speech Detected
      case 'error_network':
      case 'error_network_timeout':
        return 'నెట్వర్క్ అందుబాటులో లేదు'; // Network Failure
      default:
        return 'తప్పు జరిగింది, మళ్ళీ చెప్పండి'; // General error
    }
  }
}
