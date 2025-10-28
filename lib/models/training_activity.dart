import 'package:flutter/material.dart';

enum TrainingMode {
  translationSearch,
  wordSearch,
  matching,
  writeWordFromTranslation,
  writeTranslationFromWord,
  writeWordInExamples,
  listenWordThenTranslation,
  listenTranslationThenWord,
}

class TrainingActivity {
  const TrainingActivity({
    required this.mode,
    required this.title,
    required this.description,
    required this.icon,
    this.minimumWords = 5,
  });

  final TrainingMode mode;
  final String title;
  final String description;
  final IconData icon;
  final int minimumWords;
}
