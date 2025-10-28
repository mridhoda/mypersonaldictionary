import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      selected: selected,
      label: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: selected ? theme.colorScheme.primary : Colors.white,
        ),
      ),
      onSelected: onSelected,
      showCheckmark: false,
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.8)
            : Colors.transparent,
      ),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      backgroundColor: theme.cardColor.withValues(alpha: 0.9),
    );
  }
}
