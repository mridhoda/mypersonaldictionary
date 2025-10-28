import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dictionary_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedLanguageCode;
  double _dailyGoal = 10;
  bool _notificationsEnabled = false;
  bool _cloudSync = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<DictionaryController>();
      setState(() {
        _selectedLanguageCode = controller.activeLanguageCode;
        _dailyGoal = (controller.activeLanguage?.dailyGoal ?? 10).toDouble();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<DictionaryController>(
        builder: (context, controller, child) {
          final languages = controller.languages;
          if (languages.isEmpty) {
            return const Center(
              child: Text('Add a language first to configure settings.'),
            );
          }
          final selectedLanguage = languages.firstWhere(
            (language) => language.code == _selectedLanguageCode,
            orElse: () => controller.activeLanguage ?? languages.first,
          );

          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text(
                'Study preferences',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedLanguageCode ?? selectedLanguage.code,
                decoration: const InputDecoration(labelText: 'Language'),
                items: languages
                    .map(
                      (language) => DropdownMenuItem<String>(
                        value: language.code,
                        child: Text(language.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedLanguageCode = value;
                    final profile = languages.firstWhere(
                      (language) => language.code == value,
                    );
                    _dailyGoal = profile.dailyGoal.toDouble();
                  });
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Daily goal: ${_dailyGoal.round()} answers',
                style: theme.textTheme.bodyLarge,
              ),
              Slider(
                value: _dailyGoal,
                min: 5,
                max: 50,
                divisions: 9,
                label: '${_dailyGoal.round()}',
                onChanged: (value) {
                  setState(() => _dailyGoal = value);
                },
                onChangeEnd: (value) {
                  final languageCode =
                      _selectedLanguageCode ?? selectedLanguage.code;
                  final profile = languages.firstWhere(
                    (language) => language.code == languageCode,
                  );
                  final updated = profile.copyWith(dailyGoal: value.round());
                  controller.updateLanguage(updated);
                },
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
                title: const Text('Notifications'),
                subtitle: const Text(
                  'Receive reminders to review your vocabulary.',
                ),
              ),
              SwitchListTile(
                value: _cloudSync,
                onChanged: (value) {
                  setState(() => _cloudSync = value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cloud sync coming soon.')),
                  );
                },
                title: const Text('Connect to cloud'),
                subtitle: const Text(
                  'Keep your dictionary synced across devices.',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Data',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _SettingsButton(
                icon: Icons.file_download,
                label: 'Export words',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Export to Excel planned for a future update.',
                      ),
                    ),
                  );
                },
              ),
              _SettingsButton(
                icon: Icons.file_upload,
                label: 'Import words',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Import feature coming soon.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'About',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _SettingsButton(
                icon: Icons.info_outline,
                label: 'App version 1.0.0',
                onTap: () {},
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
