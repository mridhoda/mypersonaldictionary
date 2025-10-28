import 'package:flutter/material.dart';

import '../models/word_entry.dart';
import 'tag_chip.dart';
import 'word_image.dart';

class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onToggleLearned,
    this.onEdit,
    this.onDelete,
  });

  final WordEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onToggleLearned;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = entry.totalAnswers == 0
        ? 0.0
        : entry.correctAnswers / entry.totalAnswers;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                WordImage(imagePath: entry.imagePath, height: 64, width: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              entry.word,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: onToggleLearned,
                            icon: Icon(
                              entry.learned
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: entry.learned
                                  ? theme.colorScheme.primary
                                  : Colors.white54,
                            ),
                            tooltip: entry.learned
                                ? 'Mark as not learned'
                                : 'Mark as learned',
                          ),
                        ],
                      ),
                      if (entry.transcription != null)
                        Text(
                          entry.transcription!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: <Widget>[
                          Chip(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            label: Text(
                              entry.mainTranslation,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          ...entry.additionalTranslations.map(
                            (translation) => Chip(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              backgroundColor: theme.cardColor.withValues(
                                alpha: 0.4,
                              ),
                              label: Text(
                                translation,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _ProgressBadge(progress: progress),
              ],
            ),
            if (entry.tags.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: entry.tags
                    .map((tag) => TagChip(label: '#${tag.toLowerCase()}'))
                    .toList(),
              ),
            ],
            if (entry.examples.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                entry.examples.first,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
            if (onEdit != null || onDelete != null) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (onEdit != null)
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit word',
                    ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete word',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (progress * 100).round();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          height: 48,
          width: 48,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox(
                height: 48,
                width: 48,
                child: CircularProgressIndicator(
                  value: progress == 0 ? 0.02 : progress.clamp(0.01, 1.0),
                  strokeWidth: 4,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          progress >= 0.99 ? 'Done' : 'In Progress',
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white60),
        ),
      ],
    );
  }
}
