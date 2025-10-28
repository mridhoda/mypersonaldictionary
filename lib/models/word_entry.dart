import 'dart:convert';

class WordEntry {
  const WordEntry({
    required this.id,
    required this.languageCode,
    required this.word,
    required this.mainTranslation,
    this.transcription,
    this.additionalTranslations = const [],
    this.tags = const [],
    this.examples = const [],
    this.notes,
    this.imagePath,
    this.learned = false,
    this.correctAnswers = 0,
    this.totalAnswers = 0,
    required this.createdAt,
    this.lastReviewed,
  });

  final String id;
  final String languageCode;
  final String word;
  final String? transcription;
  final String mainTranslation;
  final List<String> additionalTranslations;
  final List<String> tags;
  final List<String> examples;
  final String? notes;
  final String? imagePath;
  final bool learned;
  final int correctAnswers;
  final int totalAnswers;
  final DateTime createdAt;
  final DateTime? lastReviewed;

  double get accuracy {
    if (totalAnswers == 0) {
      return 0;
    }
    return correctAnswers / totalAnswers;
  }

  WordEntry copyWith({
    String? id,
    String? languageCode,
    String? word,
    String? transcription,
    String? mainTranslation,
    List<String>? additionalTranslations,
    List<String>? tags,
    List<String>? examples,
    String? notes,
    String? imagePath,
    bool? learned,
    int? correctAnswers,
    int? totalAnswers,
    DateTime? createdAt,
    DateTime? lastReviewed,
  }) {
    return WordEntry(
      id: id ?? this.id,
      languageCode: languageCode ?? this.languageCode,
      word: word ?? this.word,
      transcription: transcription ?? this.transcription,
      mainTranslation: mainTranslation ?? this.mainTranslation,
      additionalTranslations:
          additionalTranslations ??
          List<String>.from(this.additionalTranslations),
      tags: tags ?? List<String>.from(this.tags),
      examples: examples ?? List<String>.from(this.examples),
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      learned: learned ?? this.learned,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalAnswers: totalAnswers ?? this.totalAnswers,
      createdAt: createdAt ?? this.createdAt,
      lastReviewed: lastReviewed ?? this.lastReviewed,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'languageCode': languageCode,
      'word': word,
      'transcription': transcription,
      'mainTranslation': mainTranslation,
      'additionalTranslations': additionalTranslations,
      'tags': tags,
      'examples': examples,
      'notes': notes,
      'imagePath': imagePath,
      'learned': learned,
      'correctAnswers': correctAnswers,
      'totalAnswers': totalAnswers,
      'createdAt': createdAt.toIso8601String(),
      'lastReviewed': lastReviewed?.toIso8601String(),
    };
  }

  factory WordEntry.fromMap(Map<String, dynamic> map) {
    return WordEntry(
      id: map['id'] as String,
      languageCode: map['languageCode'] as String,
      word: map['word'] as String,
      transcription: map['transcription'] as String?,
      mainTranslation: map['mainTranslation'] as String,
      additionalTranslations: List<String>.from(
        (map['additionalTranslations'] as List?) ?? <String>[],
      ),
      tags: List<String>.from((map['tags'] as List?) ?? <String>[]),
      examples: List<String>.from((map['examples'] as List?) ?? <String>[]),
      notes: map['notes'] as String?,
      imagePath: map['imagePath'] as String?,
      learned: (map['learned'] ?? false) as bool,
      correctAnswers: (map['correctAnswers'] ?? 0) as int,
      totalAnswers: (map['totalAnswers'] ?? 0) as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastReviewed: map['lastReviewed'] == null
          ? null
          : DateTime.parse(map['lastReviewed'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory WordEntry.fromJson(String source) =>
      WordEntry.fromMap(json.decode(source) as Map<String, dynamic>);
}
