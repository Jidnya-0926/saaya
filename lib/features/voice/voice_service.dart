import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/services/storage_service.dart';

class VoiceService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _isInitialized = false;

  static Future<bool> init() async {
    if (_isInitialized) return true;
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return false;

      _isInitialized = await _speech.initialize(
        onError: (val) => debugPrint('Speech error: $val'),
        onStatus: (val) => debugPrint('Speech status: $val'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Speech-to-Text init exception: $e');
      return false;
    }
  }

  static Future<void> startListening({
    required Function(String recognized) onResult,
    required Function() onListeningStarted,
    required Function() onListeningStopped,
  }) async {
    bool ready = await init();
    if (!ready) {
      onListeningStopped();
      return;
    }

    onListeningStarted();
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult || result.recognizedWords.isNotEmpty) {
          onResult(result.recognizedWords);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      ),
    );
  }

  static Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  static String normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
  }

  static Future<void> saveKeyword(String phrase) async {
    final settingsBox = StorageService.getSettingsBox();
    await settingsBox.put('voice_keyword', normalize(phrase));
  }

  static String getKeyword() {
    final settingsBox = StorageService.getSettingsBox();
    return settingsBox.get('voice_keyword', defaultValue: 'saaya help') as String;
  }

  static bool isKeywordMatch(String spokenText) {
    final target = getKeyword();
    final normalizedSpoken = normalize(spokenText);
    return normalizedSpoken.contains(target) || target.contains(normalizedSpoken);
  }
}
