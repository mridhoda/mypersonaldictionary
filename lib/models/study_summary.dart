class StudySummary {
  const StudySummary({
    required this.totalWords,
    required this.learnedWords,
    required this.notLearnedWords,
    required this.totalAnswers,
    required this.correctAnswers,
    required this.averageAnswersPerDay,
  });

  final int totalWords;
  final int learnedWords;
  final int notLearnedWords;
  final int totalAnswers;
  final int correctAnswers;
  final double averageAnswersPerDay;

  double get accuracy {
    if (totalAnswers == 0) {
      return 0;
    }
    return correctAnswers / totalAnswers;
  }
}
