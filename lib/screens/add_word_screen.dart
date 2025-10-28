import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/word_entry.dart';
import '../state/dictionary_controller.dart';
import '../widgets/word_image.dart';

class AddWordScreen extends StatefulWidget {
  const AddWordScreen({super.key});

  static const routeName = '/add-word';

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _wordController;
  late final TextEditingController _transcriptionController;
  late final TextEditingController _mainTranslationController;
  late final TextEditingController _additionalController;
  late final TextEditingController _tagsController;
  late final TextEditingController _examplesController;
  late final TextEditingController _notesController;

  final ImagePicker _imagePicker = ImagePicker();

  WordEntry? _editingEntry;
  String? _languageCode;
  bool _learned = false;
  bool _initialised = false;
  File? _selectedImageFile;
  String? _previewImagePath;
  String? _existingImagePath;
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController();
    _transcriptionController = TextEditingController();
    _mainTranslationController = TextEditingController();
    _additionalController = TextEditingController();
    _tagsController = TextEditingController();
    _examplesController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _wordController.dispose();
    _transcriptionController.dispose();
    _mainTranslationController.dispose();
    _additionalController.dispose();
    _tagsController.dispose();
    _examplesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) {
      return;
    }
    final controller = context.read<DictionaryController>();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is WordEntry) {
      _editingEntry = arguments;
      _applyEntry(arguments);
    } else {
      _languageCode = controller.activeLanguageCode;
      _existingImagePath = null;
      _previewImagePath = null;
      _selectedImageFile = null;
      _removeImage = false;
    }
    _initialised = true;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DictionaryController>();
    final languages = controller.languages;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingEntry == null ? 'New word' : 'Edit word'),
        actions: <Widget>[
          TextButton(onPressed: _submit, child: const Text('Save')),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              if (languages.length > 1)
                DropdownButtonFormField<String>(
                  initialValue: _languageCode,
                  decoration: const InputDecoration(labelText: 'Language'),
                  items: languages
                      .map(
                        (language) => DropdownMenuItem<String>(
                          value: language.code,
                          child: Text(language.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _languageCode = value),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _wordController,
                decoration: const InputDecoration(
                  labelText: 'Word',
                  prefixIcon: Icon(Icons.text_fields),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a word';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _transcriptionController,
                decoration: const InputDecoration(
                  labelText: 'Transcription',
                  prefixIcon: Icon(Icons.volume_mute),
                  hintText: 'Optional',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mainTranslationController,
                decoration: const InputDecoration(
                  labelText: 'Main translation',
                  prefixIcon: Icon(Icons.translate),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Provide the main translation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _additionalController,
                decoration: const InputDecoration(
                  labelText: 'Additional translations',
                  hintText: 'Separate multiple translations with commas',
                  prefixIcon: Icon(Icons.library_add),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Image',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  WordImage(
                    imagePath: _previewImagePath,
                    height: 96,
                    width: 96,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            _previewImagePath == null
                                ? 'Add image'
                                : 'Change image',
                          ),
                        ),
                        if (_previewImagePath != null) ...<Widget>[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _removeSelectedImage,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove image'),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Optional visual cue to remember the word.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'E.g. weather, verb, idiom',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _examplesController,
                decoration: const InputDecoration(
                  labelText: 'Examples',
                  hintText: 'One example per line',
                  prefixIcon: Icon(Icons.menu_book),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Extra information or mnemonics',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _learned,
                onChanged: (value) {
                  setState(() {
                    _learned = value ?? false;
                  });
                },
                title: const Text('Mark as learned'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: const Text('Save word'),
              ),
              if (_editingEntry != null) ...<Widget>[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Restore defaults'),
                          content: const Text(
                            'Reset the fields to their original values?',
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Reset'),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirmed ?? false) {
                      setState(() {
                        if (_editingEntry != null) {
                          _applyEntry(_editingEntry!);
                        }
                      });
                    }
                  },
                  child: const Text('Reset changes'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final controller = context.read<DictionaryController>();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_languageCode == null) {
      final snackBar = SnackBar(
        content: const Text('Select a language first'),
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return;
    }

    final additionalTranslations = _splitByComma(_additionalController.text);
    final tags = _splitByComma(_tagsController.text);
    final examples = _splitByLines(_examplesController.text);
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    String? finalImagePath = _existingImagePath;
    try {
      if (_removeImage) {
        if (_existingImagePath != null) {
          await _deleteStoredImage(_existingImagePath!);
        }
        finalImagePath = null;
      } else if (_selectedImageFile != null) {
        finalImagePath = await _persistImage(_selectedImageFile!);
        if (_editingEntry != null &&
            _existingImagePath != null &&
            _existingImagePath != finalImagePath) {
          await _deleteStoredImage(_existingImagePath!);
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save the image. Please try again.'),
        ),
      );
      return;
    }

    if (_editingEntry != null) {
      final updated = _editingEntry!.copyWith(
        languageCode: _languageCode,
        word: _wordController.text.trim(),
        transcription: _transcriptionController.text.trim().isEmpty
            ? null
            : _transcriptionController.text.trim(),
        mainTranslation: _mainTranslationController.text.trim(),
        additionalTranslations: additionalTranslations,
        tags: tags,
        examples: examples,
        notes: notes,
        learned: _learned,
        imagePath: finalImagePath,
      );
      await controller.updateWord(updated);
    } else {
      await controller.addWord(
        languageCode: _languageCode!,
        word: _wordController.text.trim(),
        mainTranslation: _mainTranslationController.text.trim(),
        transcription: _transcriptionController.text.trim(),
        additionalTranslations: additionalTranslations,
        tags: tags,
        examples: examples,
        notes: notes,
        imagePath: finalImagePath,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  List<String> _splitByComma(String input) {
    return input
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  List<String> _splitByLines(String input) {
    return input
        .split('\n')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  void _applyEntry(WordEntry entry) {
    _languageCode = entry.languageCode;
    _wordController.text = entry.word;
    _transcriptionController.text = entry.transcription ?? '';
    _mainTranslationController.text = entry.mainTranslation;
    _additionalController.text = entry.additionalTranslations.join(', ');
    _tagsController.text = entry.tags.join(', ');
    _examplesController.text = entry.examples.join('\n');
    _notesController.text = entry.notes ?? '';
    _learned = entry.learned;
    _existingImagePath = entry.imagePath;
    _previewImagePath = entry.imagePath;
    _selectedImageFile = null;
    _removeImage = false;
  }

  Future<void> _pickImage() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }
    setState(() {
      _selectedImageFile = File(file.path);
      _previewImagePath = file.path;
      _removeImage = false;
    });
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImageFile = null;
      _previewImagePath = null;
      _removeImage = true;
    });
  }

  Future<String> _persistImage(File source) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(directory.path, 'vocab_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final extension = p.extension(source.path).isEmpty
        ? '.jpg'
        : p.extension(source.path);
    final filename = 'word_${DateTime.now().millisecondsSinceEpoch}$extension';
    final targetPath = p.join(imagesDir.path, filename);
    final copied = await source.copy(targetPath);
    return copied.path;
  }

  Future<void> _deleteStoredImage(String path) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      if (path.startsWith(directory.path)) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {
      // Ignore deletion errors.
    }
  }
}
