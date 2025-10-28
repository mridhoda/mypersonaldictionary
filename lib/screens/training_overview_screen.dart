import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dictionary_controller.dart';
import 'training_session_screen.dart';

class TrainingOverviewScreen extends StatelessWidget {
  const TrainingOverviewScreen({super.key});

  static const routeName = '/training';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Training')),
      body: Consumer<DictionaryController>(
        builder: (context, controller, child) {
          final activities = controller.trainingActivities;
          final words = controller.filteredActiveWords;
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final activity = activities[index];
              final enoughWords = words.length >= activity.minimumWords;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.2,
                      ),
                      child: Icon(
                        activity.icon,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            activity.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            activity.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Selected words: ${words.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: enoughWords
                          ? () {
                              Navigator.of(context).pushNamed(
                                TrainingSessionScreen.routeName,
                                arguments: activity.mode,
                              );
                            }
                          : null,
                      child: const Text('Start'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
