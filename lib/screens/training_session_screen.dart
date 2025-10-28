import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_activity.dart';
import '../models/word_entry.dart';
import '../state/dictionary_controller.dart';
import '../widgets/word_audio_button.dart';
import '../widgets/word_image.dart';

class TrainingSessionScreen extends StatefulWidget {
  const TrainingSessionScreen({super.key});

  static const routeName = '/training-session';

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen> {
  TrainingMode _mode = TrainingMode.translationSearch;
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocusNode = FocusNode();
  final List<_TrainingQuestion> _questions = <_TrainingQuestion>[];

  int _currentIndex = 0;
  int _correctAnswers = 0;
  bool _submitted = false;
  bool _completed = false;
  String? _feedbackMessage;
  String? _selectedOption;
  bool _initialized = false;

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is TrainingMode) {
      _mode = args;
    }

    final controller = context.read<DictionaryController>();
    final baseWords = controller.randomWordsForTraining(
      count: 10,
      onlyUnlearned: false,
    );

    if (baseWords.isEmpty) {
      _initialized = true;
      return;
    }

    _questions.addAll(_buildQuestions(baseWords));
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<DictionaryController>();
    final total = _questions.length;
    final instruction = _modeInstructions(_mode);

    return Scaffold(
      appBar: AppBar(title: Text(instruction.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: total == 0
            ? Center(
                child: Text(
                  'You need at least a few words in this language to start training.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              )
            : _completed
            ? _buildSummary(theme, total)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    instruction.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Question ${_currentIndex + 1} of $total',
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Score: $_correctAnswers',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _QuestionCard(
                    mode: _mode,
                    question: _questions[_currentIndex],
                    controller: controller,
                    answerController: _answerController,
                    answerFocusNode: _answerFocusNode,
                    submitted: _submitted,
                    selectedOption: _selectedOption,
                    onSelectOption: (value) {
                      if (_submitted) return;
                      setState(() {
                        _selectedOption = value;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  if (_feedbackMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _feedbackMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _feedbackMessage!.startsWith('Great')
                              ? theme.colorScheme.primary
                              : Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Row(
                    children: <Widget>[
                      if (!_submitted)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleSubmit(controller),
                            child: const Text('Submit'),
                          ),
                        )
                      else
                        Expanded(
                          child: FilledButton(
                            onPressed: _handleNext,
                            child: Text(
                              _currentIndex == total - 1
                                  ? 'Finish'
                                  : 'Next question',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  void _handleSubmit(DictionaryController controller) {
    final question = _questions[_currentIndex];
    bool isCorrect = false;
    String correctAnswer = '';

    switch (_mode) {
      case TrainingMode.translationSearch:
      case TrainingMode.writeTranslationFromWord:
      case TrainingMode.listenWordThenTranslation:
        final userAnswer = _answerController.text.trim();
        final accepted = _acceptedTranslations(question.entry);
        correctAnswer = accepted.join(', ');
        if (userAnswer.isEmpty) {
          _showEmptyAnswerMessage();
          return;
        }
        isCorrect = accepted
            .map((answer) => answer.toLowerCase())
            .contains(userAnswer.toLowerCase());
        break;
      case TrainingMode.wordSearch:
      case TrainingMode.writeWordFromTranslation:
      case TrainingMode.writeWordInExamples:
      case TrainingMode.listenTranslationThenWord:
        final userAnswer = _answerController.text.trim();
        correctAnswer = question.entry.word;
        if (userAnswer.isEmpty) {
          _showEmptyAnswerMessage();
          return;
        }
        isCorrect =
            userAnswer.toLowerCase() == question.entry.word.toLowerCase();
        break;
      case TrainingMode.matching:
        if (_selectedOption == null) {
          _showEmptyAnswerMessage();
          return;
        }
        correctAnswer = _mode == TrainingMode.matching
            ? question.correctOption
            : question.correctOption;
        isCorrect = _selectedOption == question.correctOption;
        break;
    }

    controller.recordAnswer(question.entry.id, isCorrect: isCorrect);

    setState(() {
      _submitted = true;
      if (isCorrect) {
        _correctAnswers++;
        _feedbackMessage = 'Great! That\'s correct.';
      } else {
        _feedbackMessage = 'Keep going! Correct answer: $correctAnswer';
      }
    });
  }

  void _handleNext() {
    final total = _questions.length;
    if (_currentIndex >= total - 1) {
      setState(() {
        _completed = true;
      });
    } else {
      setState(() {
        _currentIndex++;
        _submitted = false;
        _feedbackMessage = null;
        _selectedOption = null;
        _answerController.clear();
        _answerFocusNode.requestFocus();
      });
    }
  }

  Widget _buildSummary(ThemeData theme, int total) {
    final accuracy = total == 0
        ? 0.0
        : (_correctAnswers / total.toDouble()) * 100;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              accuracy > 70 ? Icons.emoji_events : Icons.flag,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Session completed',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You answered $_correctAnswers out of $total correctly.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Accuracy: ${accuracy.toStringAsFixed(1)}%',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back to training'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmptyAnswerMessage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Provide an answer first.')));
  }

  List<_TrainingQuestion> _buildQuestions(List<WordEntry> words) {
    final random = Random();
    final allTranslations = words
        .expand((word) => _acceptedTranslations(word))
        .toList(growable: false);

    return words.map((word) {
      switch (_mode) {
        case TrainingMode.matching:
          final options = <String>{word.mainTranslation};
          while (options.length < 4 &&
              options.length < allTranslations.length) {
            final randomTranslation =
                allTranslations[random.nextInt(allTranslations.length)];
            options.add(randomTranslation);
          }
          final shuffled = options.toList()..shuffle();
          return _TrainingQuestion(
            entry: word,
            options: shuffled,
            correctOption: word.mainTranslation,
          );
        case TrainingMode.translationSearch:
        case TrainingMode.writeTranslationFromWord:
        case TrainingMode.listenWordThenTranslation:
          return _TrainingQuestion(entry: word);
        case TrainingMode.wordSearch:
        case TrainingMode.writeWordFromTranslation:
        case TrainingMode.listenTranslationThenWord:
          return _TrainingQuestion(entry: word);
        case TrainingMode.writeWordInExamples:
          return _TrainingQuestion(entry: word);
      }
    }).toList();
  }

  List<String> _acceptedTranslations(WordEntry entry) {
    return <String>[entry.mainTranslation, ...entry.additionalTranslations];
  }

  _ModeInstruction _modeInstructions(TrainingMode mode) {
    switch (mode) {
      case TrainingMode.translationSearch:
        return const _ModeInstruction(
          title: 'Search translation',
          subtitle: 'Type the translation for each displayed word.',
        );
      case TrainingMode.wordSearch:
        return const _ModeInstruction(
          title: 'Search word',
          subtitle: 'Recall the original word from the given translation.',
        );
      case TrainingMode.matching:
        return const _ModeInstruction(
          title: 'Matching',
          subtitle: 'Tap the translation that matches the word.',
        );
      case TrainingMode.writeWordFromTranslation:
        return const _ModeInstruction(
          title: 'Writing words',
          subtitle: 'Write the word that fits the translation.',
        );
      case TrainingMode.writeTranslationFromWord:
        return const _ModeInstruction(
          title: 'Writing translations',
          subtitle: 'Write the translation that matches the word.',
        );
      case TrainingMode.writeWordInExamples:
        return const _ModeInstruction(
          title: 'Fill in examples',
          subtitle: 'Fill in the missing word inside the sentence.',
        );
      case TrainingMode.listenWordThenTranslation:
        return const _ModeInstruction(
          title: 'Sound: word -> translation',
          subtitle:
              'Imagine listening to the word and provide the translation.',
        );
      case TrainingMode.listenTranslationThenWord:
        return const _ModeInstruction(
          title: 'Sound: translation -> word',
          subtitle: 'Imagine listening to the translation and type the word.',
        );
    }
  }
}

class _TrainingQuestion {
  _TrainingQuestion({required this.entry, this.options, String? correctOption})
    : correctOption = correctOption ?? entry.mainTranslation;

  final WordEntry entry;
  final List<String>? options;
  final String correctOption;
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.mode,
    required this.question,
    required this.controller,
    required this.answerController,
    required this.answerFocusNode,
    required this.submitted,
    required this.selectedOption,
    required this.onSelectOption,
  });

  final TrainingMode mode;
  final _TrainingQuestion question;
  final DictionaryController controller;
  final TextEditingController answerController;
  final FocusNode answerFocusNode;
  final bool submitted;
  final String? selectedOption;
  final ValueChanged<String> onSelectOption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prompt = _buildPrompt(mode, question.entry);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (question.entry.imagePath != null &&
              question.entry.imagePath!.isNotEmpty) ...<Widget>[
            WordImage(
              imagePath: question.entry.imagePath,
              height: 140,
              width: double.infinity,
              borderRadius: 18,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            prompt.label,
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  prompt.value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              WordAudioButton(
                entry: question.entry,
                iconColor: theme.colorScheme.primary,
                iconSize: 26,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (question.options != null)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: question.options!
                  .map(
                    (option) => ChoiceChip(
                      label: Text(option),
                      selected: selectedOption == option,
                      onSelected: submitted
                          ? null
                          : (_) => onSelectOption(option),
                      selectedColor: theme.colorScheme.primary.withValues(
                        alpha: 0.25,
                      ),
                    ),
                  )
                  .toList(),
            )
          else
            TextField(
              controller: answerController,
              focusNode: answerFocusNode,
              enabled: !submitted,
              decoration: const InputDecoration(
                hintText: 'Type your answer',
                prefixIcon: Icon(Icons.edit),
              ),
              onSubmitted: (_) {
                if (!submitted) {
                  FocusScope.of(context).unfocus();
                }
              },
            ),
        ],
      ),
    );
  }

  _Prompt _buildPrompt(TrainingMode mode, WordEntry entry) {
    switch (mode) {
      case TrainingMode.translationSearch:
      case TrainingMode.writeTranslationFromWord:
      case TrainingMode.listenWordThenTranslation:
        return _Prompt(label: 'Word', value: entry.word);
      case TrainingMode.wordSearch:
      case TrainingMode.writeWordFromTranslation:
      case TrainingMode.listenTranslationThenWord:
        return _Prompt(label: 'Translation', value: entry.mainTranslation);
      case TrainingMode.matching:
        return _Prompt(label: 'Word', value: entry.word);
      case TrainingMode.writeWordInExamples:
        final example = entry.examples.isNotEmpty
            ? entry.examples.first
            : 'No example available';
        final masked = example.replaceAll(
          RegExp(entry.word, caseSensitive: false),
          '_____',
        );
        return _Prompt(label: 'Complete the example', value: masked);
    }
  }
}

class _Prompt {
  const _Prompt({required this.label, required this.value});

  final String label;
  final String value;
}

class _ModeInstruction {
  const _ModeInstruction({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
