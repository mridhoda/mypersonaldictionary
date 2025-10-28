import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/study_summary.dart';
import '../state/dictionary_controller.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  static const routeName = '/statistics';

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String? _selectedLanguageCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<DictionaryController>();
      setState(() {
        _selectedLanguageCode = controller.activeLanguageCode;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: Consumer<DictionaryController>(
        builder: (context, controller, child) {
          final summary = controller.summaryForLanguage(_selectedLanguageCode);
          final answers = controller
              .answersPerDay(_selectedLanguageCode)
              .entries
              .toList();
          final languages = controller.languages;
          final options = <DropdownMenuItem<String?>>[
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All words'),
            ),
            ...languages.map(
              (language) => DropdownMenuItem<String?>(
                value: language.code,
                child: Text(language.name),
              ),
            ),
          ];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              DropdownButtonFormField<String?>(
                initialValue: _selectedLanguageCode,
                items: options,
                decoration: const InputDecoration(labelText: 'Language'),
                onChanged: (value) {
                  setState(() => _selectedLanguageCode = value);
                },
              ),
              const SizedBox(height: 20),
              _StatsGrid(summary: summary),
              const SizedBox(height: 20),
              Text(
                'Activity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(16),
                child: answers.isEmpty
                    ? Center(
                        child: Text(
                          'Complete trainings to see activity over time.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white60,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _AnswersChart(entries: answers),
              ),
              const SizedBox(height: 24),
              Text(
                'Progress insights',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _InsightTile(
                icon: Icons.bolt,
                title: 'Study streak',
                description: summary.totalAnswers == 0
                    ? 'Begin your first training to start a streak.'
                    : 'Keep going! Aim for your daily goal of answers.',
              ),
              _InsightTile(
                icon: Icons.rule_folder,
                title: 'Accuracy',
                description:
                    'You answered ${(summary.accuracy * 100).round()}% of questions correctly.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary});

  final StudySummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        _StatCard(
          label: 'Total words',
          value: summary.totalWords.toString(),
          icon: Icons.menu_book,
        ),
        _StatCard(
          label: 'Learned words',
          value: summary.learnedWords.toString(),
          icon: Icons.check_circle,
        ),
        _StatCard(
          label: 'Correct answers',
          value: summary.correctAnswers.toString(),
          icon: Icons.thumb_up,
        ),
        _StatCard(
          label: 'Accuracy',
          value: '${(summary.accuracy * 100).round()}%',
          icon: Icons.insights,
        ),
        _StatCard(
          label: 'Average/day',
          value: summary.averageAnswersPerDay.toStringAsFixed(1),
          icon: Icons.calendar_today,
        ),
        _StatCard(
          label: 'Not learned',
          value: summary.notLearnedWords.toString(),
          icon: Icons.hourglass_bottom,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _AnswersChart extends StatelessWidget {
  const _AnswersChart({required this.entries});

  final List<MapEntry<DateTime, int>> entries;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AnswersChartPainter(entries: entries),
      child: Container(),
    );
  }
}

class _AnswersChartPainter extends CustomPainter {
  _AnswersChartPainter({required this.entries});

  final List<MapEntry<DateTime, int>> entries;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) {
      return;
    }

    final maxAnswers = entries.fold<int>(
      0,
      (maxValue, entry) => max(maxValue, entry.value),
    );
    final minDate = entries.first.key;
    final maxDate = entries.last.key;
    final dayRange = max(1, maxDate.difference(minDate).inDays);

    final axisPaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height - 20),
      Offset(size.width, size.height - 20),
      axisPaint,
    );
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);

    final path = Path();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final dayOffset = entry.key.difference(minDate).inDays;
      final dx = size.width * (dayOffset / dayRange);
      final dy =
          size.height -
          20 -
          (maxAnswers == 0
              ? 0
              : (entry.value / maxAnswers) * (size.height - 40));
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    final linePaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()
      ..color = const Color(0xFFFFB74D)
      ..style = PaintingStyle.fill;

    for (final entry in entries) {
      final dayOffset = entry.key.difference(minDate).inDays;
      final dx = size.width * (dayOffset / dayRange);
      final dy =
          size.height -
          20 -
          (maxAnswers == 0
              ? 0
              : (entry.value / maxAnswers) * (size.height - 40));
      canvas.drawCircle(Offset(dx, dy), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnswersChartPainter oldDelegate) {
    return oldDelegate.entries != entries;
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
