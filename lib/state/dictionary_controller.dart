import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/dictionary_repository.dart';
import '../models/language_profile.dart';
import '../models/study_summary.dart';
import '../models/training_activity.dart';
import '../models/word_entry.dart';

class DictionaryController extends ChangeNotifier {
  DictionaryController(this._repository) : _uuid = const Uuid();

  final DictionaryRepository _repository;
  final Uuid _uuid;

  bool _initialized = false;
  bool _isBusy = false;

  List<LanguageProfile> _languages = <LanguageProfile>[];
  List<WordEntry> _words = <WordEntry>[];
  String? _activeLanguageCode;

  String _searchQuery = '';
  final Set<String> _selectedTags = <String>{};
  bool _showOnlyNewWords = false;
  static const List<TrainingActivity> _activities = <TrainingActivity>[
    TrainingActivity(
      mode: TrainingMode.translationSearch,
      title: 'Search translation',
      description: 'Find the correct translation for the prompted word.',
      icon: Icons.translate,
    ),
    TrainingActivity(
      mode: TrainingMode.wordSearch,
      title: 'Search word',
      description: 'Recall the native word from its translation.',
      icon: Icons.manage_search,
    ),
    TrainingActivity(
      mode: TrainingMode.matching,
      title: 'Matching of word to its translation',
      description: 'Match pairs of words and translations.',
      icon: Icons.view_module,
      minimumWords: 6,
    ),
    TrainingActivity(
      mode: TrainingMode.writeWordFromTranslation,
      title: 'Writing words by using translation',
      description: 'Type the learned word from the shown translation.',
      icon: Icons.spellcheck,
    ),
    TrainingActivity(
      mode: TrainingMode.writeTranslationFromWord,
      title: 'Writing translations by using word',
      description: 'Type the translation that fits the given word.',
      icon: Icons.edit_note,
    ),
    TrainingActivity(
      mode: TrainingMode.writeWordInExamples,
      title: 'Writing words in examples',
      description: 'Fill in the missing word inside example sentences.',
      icon: Icons.auto_stories,
    ),
    TrainingActivity(
      mode: TrainingMode.listenWordThenTranslation,
      title: 'Sound: word - translation',
      description: 'Listen to the word and choose the translation.',
      icon: Icons.volume_up,
    ),
    TrainingActivity(
      mode: TrainingMode.listenTranslationThenWord,
      title: 'Sound: translation - word',
      description: 'Listen to the translation and recall the word.',
      icon: Icons.record_voice_over,
    ),
  ];

  // region getters
  bool get isInitialized => _initialized;
  bool get isBusy => _isBusy;

  List<LanguageProfile> get languages => UnmodifiableListView(_languages);
  List<TrainingActivity> get trainingActivities =>
      List<TrainingActivity>.unmodifiable(_activities);

  LanguageProfile? get activeLanguage {
    if (_activeLanguageCode == null) {
      return null;
    }
    try {
      return _languages.firstWhere(
        (language) => language.code == _activeLanguageCode,
      );
    } on StateError {
      return null;
    }
  }

  String? get activeLanguageCode => _activeLanguageCode;

  Set<String> get selectedTags => Set<String>.unmodifiable(_selectedTags);

  bool get showOnlyNewWords => _showOnlyNewWords;

  String get searchQuery => _searchQuery;

  List<WordEntry> get allWords => UnmodifiableListView(_words);

  List<WordEntry> get filteredActiveWords {
    Iterable<WordEntry> result = _words;
    if (_activeLanguageCode != null) {
      result = result.where((word) => word.languageCode == _activeLanguageCode);
    }

    if (_selectedTags.isNotEmpty) {
      result = result.where(
        (word) => word.tags
            .map((tag) => tag.toLowerCase())
            .toSet()
            .intersection(_selectedTags)
            .isNotEmpty,
      );
    }

    if (_showOnlyNewWords) {
      result = result.where((word) => !word.learned);
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where(
        (word) =>
            word.word.toLowerCase().contains(query) ||
            word.mainTranslation.toLowerCase().contains(query) ||
            word.additionalTranslations
                .map((t) => t.toLowerCase())
                .any((translation) => translation.contains(query)) ||
            word.tags
                .map((tag) => tag.toLowerCase())
                .any((tag) => tag.contains(query)),
      );
    }

    final sorted = result.toList()
      ..sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
    return sorted;
  }

  List<String> get availableTags {
    final tags = <String>{};
    Iterable<WordEntry> target = _words;
    if (_activeLanguageCode != null) {
      target = target.where((word) => word.languageCode == _activeLanguageCode);
    }
    for (final word in target) {
      tags.addAll(word.tags.map((tag) => tag.toLowerCase()));
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }
  // endregion

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _setBusy(true);

    _languages = _repository.loadLanguages();
    _words = _repository.loadWords();
    _activeLanguageCode = _repository.loadActiveLanguage();

    final bool seededLanguages = _languages.isEmpty;
    final bool seededWords = _words.isEmpty;

    if (seededLanguages) {
      _languages = _createDefaultLanguages();
      await _repository.saveLanguages(_languages);
    }

    if (seededWords) {
      _words = _createSeedWords();
      await _repository.saveWords(_words);
    }

    if (_activeLanguageCode == null) {
      _activeLanguageCode = _languages.isNotEmpty
          ? _languages.first.code
          : null;
      if (_activeLanguageCode != null) {
        await _repository.saveActiveLanguage(_activeLanguageCode!);
      }
    }

    _initialized = true;
    _setBusy(false);
    notifyListeners();
  }

  Future<void> switchLanguage(String code) async {
    if (_activeLanguageCode == code) {
      return;
    }
    _activeLanguageCode = code;
    await _repository.saveActiveLanguage(code);
    notifyListeners();
  }

  Future<void> addLanguage(LanguageProfile profile) async {
    _languages = List<LanguageProfile>.from(_languages)..add(profile);
    await _repository.saveLanguages(_languages);
    notifyListeners();
  }

  Future<void> updateLanguage(LanguageProfile updated) async {
    _languages = _languages
        .map((language) => language.code == updated.code ? updated : language)
        .toList();
    await _repository.saveLanguages(_languages);
    notifyListeners();
  }

  Future<void> deleteLanguage(String code) async {
    _languages = _languages.where((language) => language.code != code).toList();
    _words = _words.where((word) => word.languageCode != code).toList();

    if (_activeLanguageCode == code) {
      _activeLanguageCode = _languages.isNotEmpty
          ? _languages.first.code
          : null;
      if (_activeLanguageCode != null) {
        await _repository.saveActiveLanguage(_activeLanguageCode!);
      }
    }

    await _repository.saveLanguages(_languages);
    await _repository.saveWords(_words);
    notifyListeners();
  }

  Future<void> addWord({
    required String languageCode,
    required String word,
    required String mainTranslation,
    String? transcription,
    List<String>? additionalTranslations,
    List<String>? tags,
    List<String>? examples,
    String? notes,
    String? imagePath,
  }) async {
    final entry = WordEntry(
      id: _uuid.v4(),
      languageCode: languageCode,
      word: word.trim(),
      mainTranslation: mainTranslation.trim(),
      transcription: transcription?.trim().isEmpty ?? true
          ? null
          : transcription!.trim(),
      additionalTranslations: (additionalTranslations ?? <String>[])
          .where((value) => value.trim().isNotEmpty)
          .map((value) => value.trim())
          .toList(),
      tags: (tags ?? <String>[])
          .where((tag) => tag.trim().isNotEmpty)
          .map((tag) => tag.trim())
          .toList(),
      examples: (examples ?? <String>[])
          .where((example) => example.trim().isNotEmpty)
          .map((example) => example.trim())
          .toList(),
      notes: notes?.trim().isEmpty ?? true ? null : notes!.trim(),
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );

    _words = List<WordEntry>.from(_words)..add(entry);
    await _repository.saveWords(_words);
    notifyListeners();
  }

  Future<void> updateWord(WordEntry updated) async {
    _words = _words
        .map((word) => word.id == updated.id ? updated : word)
        .toList();
    await _repository.saveWords(_words);
    notifyListeners();
  }

  Future<void> deleteWord(String id) async {
    _words = _words.where((word) => word.id != id).toList();
    await _repository.saveWords(_words);
    notifyListeners();
  }

  Future<void> toggleLearned(String id) async {
    final index = _words.indexWhere((word) => word.id == id);
    if (index == -1) {
      return;
    }
    final current = _words[index];
    final updated = current.copyWith(learned: !current.learned);
    _words[index] = updated;
    await _repository.saveWords(_words);
    notifyListeners();
  }

  Future<void> recordAnswer(String id, {required bool isCorrect}) async {
    final index = _words.indexWhere((word) => word.id == id);
    if (index == -1) {
      return;
    }
    final current = _words[index];
    final updated = current.copyWith(
      totalAnswers: current.totalAnswers + 1,
      correctAnswers: current.correctAnswers + (isCorrect ? 1 : 0),
      learned: isCorrect ? true : current.learned,
      lastReviewed: DateTime.now(),
    );
    _words[index] = updated;
    await _repository.saveWords(_words);
    notifyListeners();
  }

  WordEntry? wordById(String id) {
    try {
      return _words.firstWhere((word) => word.id == id);
    } on StateError {
      return null;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void toggleTag(String tag) {
    final normalized = tag.toLowerCase();
    if (_selectedTags.contains(normalized)) {
      _selectedTags.remove(normalized);
    } else {
      _selectedTags.add(normalized);
    }
    notifyListeners();
  }

  void clearFilters() {
    _selectedTags.clear();
    _searchQuery = '';
    _showOnlyNewWords = false;
    notifyListeners();
  }

  void toggleShowOnlyNewWords() {
    _showOnlyNewWords = !_showOnlyNewWords;
    notifyListeners();
  }

  StudySummary summaryForLanguage(String? languageCode) {
    Iterable<WordEntry> target = _words;
    if (languageCode != null) {
      target = target.where((entry) => entry.languageCode == languageCode);
    }

    final words = target.toList();
    final totalWords = words.length;
    final learnedWords = words.where((word) => word.learned).length;
    final notLearnedWords = totalWords - learnedWords;
    final totalAnswers = words.fold<int>(
      0,
      (sum, word) => sum + word.totalAnswers,
    );
    final correctAnswers = words.fold<int>(
      0,
      (sum, word) => sum + word.correctAnswers,
    );

    final DateTime? earliestInteraction = _earliestInteraction(words);
    final double averagePerDay = _averageAnswersPerDay(
      totalAnswers: totalAnswers,
      earliestInteraction: earliestInteraction,
    );

    return StudySummary(
      totalWords: totalWords,
      learnedWords: learnedWords,
      notLearnedWords: notLearnedWords,
      totalAnswers: totalAnswers,
      correctAnswers: correctAnswers,
      averageAnswersPerDay: averagePerDay,
    );
  }

  Map<DateTime, int> answersPerDay(String? languageCode) {
    Iterable<WordEntry> target = _words;
    if (languageCode != null) {
      target = target.where((entry) => entry.languageCode == languageCode);
    }

    final Map<DateTime, int> counts = <DateTime, int>{};
    for (final word in target) {
      if (word.lastReviewed == null || word.totalAnswers == 0) {
        continue;
      }
      final day = DateTime(
        word.lastReviewed!.year,
        word.lastReviewed!.month,
        word.lastReviewed!.day,
      );
      counts.update(
        day,
        (value) => value + word.totalAnswers,
        ifAbsent: () => word.totalAnswers,
      );
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return LinkedHashMap<DateTime, int>.fromEntries(sortedEntries);
  }

  List<WordEntry> randomWordsForTraining({
    int count = 10,
    bool onlyUnlearned = false,
  }) {
    Iterable<WordEntry> target = _words;
    if (_activeLanguageCode != null) {
      target = target.where(
        (entry) => entry.languageCode == _activeLanguageCode,
      );
    }
    if (onlyUnlearned) {
      target = target.where((entry) => !entry.learned);
    }

    final list = target.toList();
    if (list.length <= count) {
      return list;
    }
    final random = Random();
    final selected = <WordEntry>[];
    final usedIndices = <int>{};
    while (selected.length < count && usedIndices.length < list.length) {
      final index = random.nextInt(list.length);
      if (usedIndices.contains(index)) {
        continue;
      }
      usedIndices.add(index);
      selected.add(list[index]);
    }
    return selected;
  }

  void _setBusy(bool value) {
    if (_isBusy == value) {
      return;
    }
    _isBusy = value;
    notifyListeners();
  }

  DateTime? _earliestInteraction(List<WordEntry> words) {
    DateTime? earliest;
    for (final word in words) {
      final candidates = <DateTime?>[word.createdAt, word.lastReviewed];
      for (final item in candidates) {
        if (item == null) {
          continue;
        }
        if (earliest == null || item.isBefore(earliest)) {
          earliest = item;
        }
      }
    }
    return earliest;
  }

  double _averageAnswersPerDay({
    required int totalAnswers,
    required DateTime? earliestInteraction,
  }) {
    if (totalAnswers == 0 || earliestInteraction == null) {
      return 0;
    }
    final now = DateTime.now();
    final difference = now.difference(earliestInteraction).inDays;
    final days = difference <= 0 ? 1 : difference;
    return totalAnswers / days;
  }

  List<LanguageProfile> _createDefaultLanguages() {
    return <LanguageProfile>[
      const LanguageProfile(
        code: 'en',
        name: 'English',
        dailyGoal: 15,
        colorHex: '#FFB74D',
      ),
      const LanguageProfile(
        code: 'id',
        name: 'Indonesian',
        dailyGoal: 10,
        colorHex: '#4FC3F7',
      ),
      const LanguageProfile(
        code: 'de',
        name: 'German',
        dailyGoal: 12,
        colorHex: '#9575CD',
      ),
    ];
  }

  List<WordEntry> _createSeedWords() {
    final now = DateTime.now();
    final List<WordEntry> entries = <WordEntry>[
      WordEntry(
        id: _uuid.v4(),
        languageCode: 'en',
        word: 'Ablution',
        transcription: 'uh-BLOO-shun',
        mainTranslation: 'pembersihan',
        additionalTranslations: const ['ritual washing', 'dry ablution'],
        examples: const [
          'He performed ablution before the prayer.',
          'Ceremonial ablution is part of the tradition.',
        ],
        tags: const ['noun', 'ritual'],
        learned: true,
        correctAnswers: 18,
        totalAnswers: 20,
        createdAt: now.subtract(const Duration(days: 7)),
        lastReviewed: now.subtract(const Duration(days: 1)),
      ),
      WordEntry(
        id: _uuid.v4(),
        languageCode: 'en',
        word: 'Acclimated',
        transcription: 'AK-luh-may-ted',
        mainTranslation: 'terbiasa',
        additionalTranslations: const ['acclimatized', 'adapted'],
        examples: const ['She acclimated quickly to the new climate.'],
        tags: const ['adjective'],
        learned: false,
        correctAnswers: 4,
        totalAnswers: 7,
        createdAt: now.subtract(const Duration(days: 6)),
        lastReviewed: now.subtract(const Duration(days: 2)),
      ),
      WordEntry(
        id: _uuid.v4(),
        languageCode: 'en',
        word: 'Acknowledgement',
        transcription: 'ak-NOL-ij-ment',
        mainTranslation: 'pengakuan',
        additionalTranslations: const ['apresiasi', 'terima kasih'],
        examples: const ['The letter was an acknowledgement of the gift.'],
        tags: const ['noun', 'verb'],
        learned: false,
        correctAnswers: 6,
        totalAnswers: 10,
        createdAt: now.subtract(const Duration(days: 5)),
        lastReviewed: now.subtract(const Duration(days: 2)),
      ),
      WordEntry(
        id: _uuid.v4(),
        languageCode: 'en',
        word: 'Administering',
        transcription: 'ad-MIN-iss-tur-ing',
        mainTranslation: 'administrasi',
        additionalTranslations: const ['managing', 'governing'],
        tags: const ['verb'],
        learned: false,
        correctAnswers: 2,
        totalAnswers: 5,
        createdAt: now.subtract(const Duration(days: 4)),
        lastReviewed: now.subtract(const Duration(days: 3)),
      ),
      WordEntry(
        id: _uuid.v4(),
        languageCode: 'en',
        word: 'Atonement',
        transcription: 'uh-TONE-ment',
        mainTranslation: 'penebusan dosa',
        additionalTranslations: const ['reparation', 'penance'],
        tags: const ['noun'],
        learned: false,
        correctAnswers: 1,
        totalAnswers: 3,
        createdAt: now.subtract(const Duration(days: 3)),
        lastReviewed: now.subtract(const Duration(days: 1)),
      ),
      WordEntry(
        id: _uuid.v4(),
        languageCode: 'en',
        word: 'Authority',
        transcription: 'aw-THOR-ih-tee',
        mainTranslation: 'otoritas',
        additionalTranslations: const ['wewenang', 'pemerintah'],
        tags: const ['noun', 'adjective'],
        learned: true,
        correctAnswers: 11,
        totalAnswers: 14,
        createdAt: now.subtract(const Duration(days: 2)),
        lastReviewed: now.subtract(const Duration(days: 1)),
      ),
      WordEntry(
        id: _uuid.v4(),
        languageCode: 'en',
        word: 'Aversion',
        transcription: 'uh-VER-zhun',
        mainTranslation: 'kebencian',
        additionalTranslations: const ['keengganan', 'antipati'],
        tags: const ['noun'],
        learned: false,
        correctAnswers: 0,
        totalAnswers: 2,
        createdAt: now.subtract(const Duration(days: 1)),
        lastReviewed: now.subtract(const Duration(days: 1)),
      ),
    ];
    return entries;
  }
}
