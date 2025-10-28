import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/word_entry.dart';
import '../state/dictionary_controller.dart';
import '../widgets/app_drawer.dart';
import '../widgets/tag_chip.dart';
import '../widgets/training_card.dart';
import '../widgets/word_card.dart';
import '../widgets/word_image.dart';
import 'add_word_screen.dart';
import 'statistics_screen.dart';
import 'training_overview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _searchController;
  bool _syncedQuery = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_syncedQuery) {
      final controller = context.read<DictionaryController>();
      _searchController.text = controller.searchQuery;
      _syncedQuery = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<DictionaryController>(
      builder: (context, controller, child) {
        final languageName = controller.activeLanguage?.name ?? 'Dictionary';
        final words = controller.filteredActiveWords;
        final tags = controller.availableTags;
        final summary = controller.summaryForLanguage(
          controller.activeLanguageCode,
        );
        final trainingSubtitle = summary.totalWords == 0
            ? 'Add words to unlock exercises'
            : '${summary.totalWords} words / ${summary.learnedWords} learned';

        return Scaffold(
          drawer: const AppDrawer(),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  languageName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${summary.learnedWords} learned / ${summary.totalWords} total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.bar_chart),
                tooltip: 'Statistics',
                onPressed: () {
                  Navigator.of(context).pushNamed(StatisticsScreen.routeName);
                },
              ),
              IconButton(
                icon: const Icon(Icons.menu_book),
                tooltip: 'Training',
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed(TrainingOverviewScreen.routeName);
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AddWordScreen.routeName);
            },
            child: const Icon(Icons.add),
          ),
          body: controller.isBusy && !controller.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    // Lightweight refresh: for now we just wait briefly.
                    await Future<void>.delayed(
                      const Duration(milliseconds: 350),
                    );
                  },
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    children: <Widget>[
                      _SearchField(
                        controller: _searchController,
                        onChanged: controller.setSearchQuery,
                      ),
                      const SizedBox(height: 12),
                      if (tags.isNotEmpty) ...<Widget>[
                        Text(
                          '# Tags',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tags
                              .map(
                                (tag) => TagChip(
                                  label: '#$tag',
                                  selected: controller.selectedTags.contains(
                                    tag,
                                  ),
                                  onSelected: (_) => controller.toggleTag(tag),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SwitchListTile(
                        value: controller.showOnlyNewWords,
                        onChanged: (_) => controller.toggleShowOnlyNewWords(),
                        title: const Text('Show only new words'),
                        tileColor: theme.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TrainingCard(
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(TrainingOverviewScreen.routeName),
                        subtitle: trainingSubtitle,
                      ),
                      const SizedBox(height: 18),
                      if (words.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'No words yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start building your personal dictionary by adding your first word.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white60,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(AddWordScreen.routeName),
                                icon: const Icon(Icons.add),
                                label: const Text('Add word'),
                              ),
                            ],
                          ),
                        )
                      else
                        ...words.map(
                          (word) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: WordCard(
                              entry: word,
                              onTap: () => _showWordDetails(context, word),
                              onToggleLearned: () =>
                                  controller.toggleLearned(word.id),
                              onEdit: () => _editWord(context, word),
                              onDelete: () => _confirmDelete(context, word.id),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  void _showWordDetails(BuildContext context, WordEntry entry) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (entry.imagePath != null &&
                    entry.imagePath!.isNotEmpty) ...<Widget>[
                  WordImage(
                    imagePath: entry.imagePath,
                    height: 180,
                    width: double.infinity,
                    borderRadius: 20,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        entry.word,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                if (entry.transcription != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    entry.transcription!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Main translation',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white60,
                  ),
                ),
                Text(
                  entry.mainTranslation,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (entry.additionalTranslations.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'Additional translations',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: entry.additionalTranslations
                        .map((translation) => Chip(label: Text(translation)))
                        .toList(),
                  ),
                ],
                if (entry.examples.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    'Examples',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...entry.examples.map(
                    (example) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '- $example',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
                if (entry.tags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    'Tags',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: entry.tags
                        .map(
                          (tag) => Chip(label: Text('#${tag.toLowerCase()}')),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _editWord(context, entry),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit word'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _confirmDelete(context, entry.id);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete word'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editWord(BuildContext context, WordEntry entry) async {
    await Navigator.of(
      context,
    ).pushNamed(AddWordScreen.routeName, arguments: entry);
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final controller = context.read<DictionaryController>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete word'),
          content: const Text(
            'Are you sure you want to remove this word permanently?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      await controller.deleteWord(id);
    }
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search words or translations',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
          ),
          style: theme.textTheme.bodyLarge,
        );
      },
    );
  }
}
