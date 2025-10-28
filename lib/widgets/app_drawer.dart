import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/settings_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/training_overview_screen.dart';
import '../state/dictionary_controller.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            _DrawerHeader(theme: theme),
            Expanded(
              child: Consumer<DictionaryController>(
                builder: (context, controller, child) {
                  final languages = controller.languages;
                  if (languages.isEmpty) {
                    return const Center(child: Text('No languages yet'));
                  }
                  return ListView.separated(
                    itemCount: languages.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final language = languages[index];
                      final summary = controller.summaryForLanguage(
                        language.code,
                      );
                      final selected =
                          controller.activeLanguageCode == language.code;
                      final progress = summary.totalWords == 0
                          ? 0.0
                          : summary.learnedWords / summary.totalWords;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        tileColor: selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : theme.cardColor,
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          child: Text(
                            language.code.toUpperCase(),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          language.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${summary.totalWords} words',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                        trailing: SizedBox(
                          height: 40,
                          width: 40,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              CircularProgressIndicator(
                                value: progress,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                                backgroundColor: Colors.white10,
                                strokeWidth: 4,
                              ),
                              Text(
                                '${(progress * 100).round()}%',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          controller.switchLanguage(language.code);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: <Widget>[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.leaderboard),
                    title: const Text('Training'),
                    onTap: () {
                      Navigator.of(context)
                        ..pop()
                        ..pushNamed(TrainingOverviewScreen.routeName);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: const Text('Statistics'),
                    onTap: () {
                      Navigator.of(context)
                        ..pop()
                        ..pushNamed(StatisticsScreen.routeName);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.of(context)
                        ..pop()
                        ..pushNamed(SettingsScreen.routeName);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'My Dictionary',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep your personalised vocabulary organised.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
