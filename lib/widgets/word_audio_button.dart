import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/word_entry.dart';
import '../services/speech_service.dart';

class WordAudioButton extends StatelessWidget {
  const WordAudioButton({
    super.key,
    required this.entry,
    this.iconColor,
    this.iconSize = 22,
    this.padding,
  });

  final WordEntry entry;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      padding: padding ?? const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      icon: Icon(
        Icons.volume_up,
        size: iconSize,
        color: iconColor ?? theme.colorScheme.primary,
      ),
      tooltip: 'Play pronunciation',
      onPressed: () async {
        final speech = context.read<SpeechService>();
        await speech.speakWord(entry);
      },
    );
  }
}
