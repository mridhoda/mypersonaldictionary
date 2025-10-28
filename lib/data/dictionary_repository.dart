import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/language_profile.dart';
import '../models/word_entry.dart';

class DictionaryRepository {
  DictionaryRepository(this._prefs);

  static const _languagesKey = 'languages';
  static const _wordsKey = 'words';
  static const _activeLanguageKey = 'active_language';

  final SharedPreferences _prefs;

  List<LanguageProfile> loadLanguages() {
    final raw = _prefs.getString(_languagesKey);
    if (raw == null || raw.isEmpty) {
      return <LanguageProfile>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic item) =>
              LanguageProfile.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> saveLanguages(List<LanguageProfile> languages) {
    final encoded = jsonEncode(
      languages.map((language) => language.toMap()).toList(),
    );
    return _prefs.setString(_languagesKey, encoded);
  }

  List<WordEntry> loadWords() {
    final raw = _prefs.getString(_wordsKey);
    if (raw == null || raw.isEmpty) {
      return <WordEntry>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (dynamic item) =>
              WordEntry.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> saveWords(List<WordEntry> words) {
    final encoded = jsonEncode(words.map((word) => word.toMap()).toList());
    return _prefs.setString(_wordsKey, encoded);
  }

  String? loadActiveLanguage() => _prefs.getString(_activeLanguageKey);

  Future<void> saveActiveLanguage(String code) =>
      _prefs.setString(_activeLanguageKey, code);

  Future<void> clear() async {
    await _prefs.remove(_languagesKey);
    await _prefs.remove(_wordsKey);
    await _prefs.remove(_activeLanguageKey);
  }
}
