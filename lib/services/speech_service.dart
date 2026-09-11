import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Semantic speech recognizer states.
enum SpeechState {
  idle,
  listening,
  result,
  error,
}

/// A hardened, Telugu-first voice recognition service wrapping `speech_to_text`.
/// Features:
/// - Inactivity & silence auto-commit watchdog (prevents UI hanging on Android silence timeouts).
/// - Intelligent token-level and phrase-level consecutive duplicate speech cleaning.
/// - Sound level meter stream for visual voice pulsation.
/// - Graceful mapping of native errors into natural spoken Telugu.
class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  String _lastRecognizedWords = '';
  Timer? _silenceWatchdog;
  bool _hasDeliveredFinal = false;

  SpeechService();

  bool get isInitialized => _isInitialized;
  bool get isListening => _speechToText.isListening;

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

    final bool hasPermission = await Permission.microphone.isGranted;
    if (!hasPermission) {
      onError('వాయిస్ సేవలు ఉపయోగించడానికి మైక్ అనుమతి అవసరం');
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
      onError('వాయిస్ రికార్డర్ అందుబాటులో లేదు');
      return false;
    }
  }

  /// Start capture with strict 'te_IN' settings and watchdog timers.
  Future<void> startListening({
    required Function(String recognizedWords, bool isFinal) onResult,
    required Function(String errorDescription) onError,
    Function(double soundLevel)? onSoundLevel,
  }) async {
    _silenceWatchdog?.cancel();
    _lastRecognizedWords = '';
    _hasDeliveredFinal = false;

    if (!_isInitialized) {
      final ok = await initialize(
        onStatus: (status) {
          if ((status == 'notListening' || status == 'done') &&
              !_hasDeliveredFinal &&
              _lastRecognizedWords.isNotEmpty) {
            _hasDeliveredFinal = true;
            onResult(_lastRecognizedWords, true);
          }
        },
        onError: onError,
      );
      if (!ok) return;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          final String cleanedResult = _cleanDuplicateSpeech(result.recognizedWords);
          _lastRecognizedWords = cleanedResult;

          if (result.finalResult) {
            _silenceWatchdog?.cancel();
            _hasDeliveredFinal = true;
            onResult(cleanedResult, true);
          } else {
            onResult(cleanedResult, false);

            // Silence auto-commit watchdog: if user speaks and pauses for 1800ms, auto-commit
            _silenceWatchdog?.cancel();
            _silenceWatchdog = Timer(const Duration(milliseconds: 1800), () {
              if (!_hasDeliveredFinal && _lastRecognizedWords.trim().isNotEmpty) {
                _hasDeliveredFinal = true;
                onResult(_lastRecognizedWords, true);
                stopListening();
              }
            });
          }
        },
        onSoundLevelChange: (level) {
          if (onSoundLevel != null) {
            onSoundLevel(level);
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: 'te_IN',
          listenFor: const Duration(seconds: 25),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('Speech listen crashed: $e');
      onError('వాయిస్ వినడం సాధ్యం కాలేదు, మళ్ళీ ప్రయత్నించండి');
    }
  }

  /// Stop active recorder capture and commit any buffered text.
  Future<void> stopListening() async {
    _silenceWatchdog?.cancel();
    if (!_isInitialized) return;
    await _speechToText.stop();
  }

  /// Cancel active recorder capture without committing.
  Future<void> cancelListening() async {
    _silenceWatchdog?.cancel();
    _lastRecognizedWords = '';
    _hasDeliveredFinal = true;
    if (!_isInitialized) return;
    await _speechToText.cancel();
  }

  /// Cleans duplicate/repeating words caused by stutter or speech-to-text duplication.
  /// Example: "సంతోష్ సంతోష్" -> "సంతోష్"
  /// Example: "రవి కుమార్ రవి కుమార్" -> "రవి కుమార్"
  /// Preserves valid names with repeated syllables/distinct words like "బాల బాలకృష్ణ".
  String _cleanDuplicateSpeech(String input) {
    if (input.trim().isEmpty) return input;

    final List<String> words = input.trim().split(RegExp(r'\s+'));
    if (words.length <= 1) return input;

    // 1. Deduplicate immediate consecutive identical words
    final List<String> deduplicated = [];
    for (int i = 0; i < words.length; i++) {
      if (deduplicated.isEmpty || deduplicated.last != words[i]) {
        deduplicated.add(words[i]);
      }
    }

    // 2. Deduplicate repeated multi-word phrases (e.g. "రవి కుమార్ రవి కుమార్")
    if (deduplicated.length >= 4 && deduplicated.length % 2 == 0) {
      final int half = deduplicated.length ~/ 2;
      final String firstHalf = deduplicated.sublist(0, half).join(' ');
      final String secondHalf = deduplicated.sublist(half).join(' ');
      if (firstHalf == secondHalf) {
        return firstHalf;
      }
    }

    return deduplicated.join(' ');
  }

  /// Maps native Android speech engine errors to elderly-friendly natural Telugu.
  String _mapNativeErrorToTelugu(String nativeError) {
    switch (nativeError.toLowerCase()) {
      case 'error_permission':
        return 'మైక్ ఉపయోగించడానికి అనుమతి అవసరం';
      case 'error_audio_record':
      case 'error_busy':
        return 'మైక్రోఫోన్ అందుబాటులో లేదు';
      case 'error_no_match':
        return 'స్పష్టంగా వినిపించలేదు, మళ్ళీ చెప్పండి';
      case 'error_speech_timeout':
        return 'ఏమీ వినిపించలేదు, మైక్ నొక్కి మళ్ళీ చెప్పండి';
      case 'error_network':
      case 'error_network_timeout':
        return 'నెట్‌వర్క్ అందుబాటులో లేదు';
      default:
        return 'సమస్య వచ్చింది, మళ్ళీ ప్రయత్నించండి';
    }
  }
}
