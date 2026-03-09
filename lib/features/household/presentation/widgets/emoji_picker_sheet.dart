import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';

class EmojiPickerSheet extends StatelessWidget {
  const EmojiPickerSheet({super.key});

  static const List<String> emojis = <String>[
    '🏡',
    '🏠',
    '🌿',
    '🪴',
    '☕',
    '🕯️',
    '🍳',
    '🛋️',
    '🧺',
    '🪵',
    '🌞',
    '🌙',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Choose an emoji', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: emojis
              .map(
                (String emoji) => HearthChip(
                  label: emoji,
                  selected: false,
                  onTap: () => Navigator.of(context).pop<String>(emoji),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
