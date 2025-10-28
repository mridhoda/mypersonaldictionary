import 'dart:io';

import 'package:flutter/material.dart';

class WordImage extends StatelessWidget {
  const WordImage({
    super.key,
    required this.imagePath,
    this.height,
    this.width,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
    this.backgroundColor,
  });

  final String? imagePath;
  final double? height;
  final double? width;
  final double borderRadius;
  final BoxFit fit;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        width: width,
        color:
            backgroundColor ??
            theme.colorScheme.primary.withValues(alpha: 0.15),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (imagePath == null || imagePath!.isEmpty) {
      return Icon(Icons.auto_awesome, color: theme.colorScheme.primary);
    }
    final path = imagePath!;
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
      );
    }
    return Icon(Icons.auto_awesome, color: theme.colorScheme.primary);
  }
}
