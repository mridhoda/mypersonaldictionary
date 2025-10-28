import 'package:flutter_tts/flutter_tts.dart';

import '../models/word_entry.dart';

class SpeechService {
  SpeechService();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> speakWord(WordEntry entry) async {
    await speak(entry.word, languageCode: entry.languageCode);
  }

  Future<void> speak(String text, {String? languageCode}) async {
    if (text.trim().isEmpty) {
      return;
    }
    await _ensureInitialized();
    await _configureLanguage(languageCode);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) {
      return;
    }
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
    _isInitialized = true;
  }

  Future<void> _configureLanguage(String? languageCode) async {
    final locale = _languageToLocale(languageCode);
    await _tts.setLanguage(locale);
  }

  String _languageToLocale(String? languageCode) {
    if (languageCode == null || languageCode.isEmpty) {
      return 'en-US';
    }
    switch (languageCode) {
      case 'en':
        return 'en-US';
      case 'id':
        return 'id-ID';
      case 'de':
        return 'de-DE';
      default:
        if (languageCode.contains('-')) {
          return languageCode;
        }
        if (languageCode.length == 2) {
          final lower = languageCode.toLowerCase();
          final upper = languageCode.toUpperCase();
          return '$lower-$upper';
        }
        return languageCode;
    }
  }

  Future<void> stop() => _tts.stop();

  void dispose() {
    _tts.stop();
  }
}
