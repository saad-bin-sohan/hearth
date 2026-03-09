import 'package:flutter/material.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/finance/domain/finance_models.dart';

class SplitRuleConfigurator extends StatelessWidget {
  const SplitRuleConfigurator({
    required this.participants,
    required this.selectedType,
    required this.amountCents,
    required this.percentages,
    required this.fixedControllers,
    required this.exemptUserIds,
    required this.onTypeChanged,
    required this.onPercentageChanged,
    required this.onExemptionToggled,
    super.key,
  });

  final List<FinanceParticipant> participants;
  final SplitRuleType selectedType;
  final int? amountCents;
  final Map<String, int> percentages;
  final Map<String, TextEditingController> fixedControllers;
  final Set<String> exemptUserIds;
  final ValueChanged<SplitRuleType> onTypeChanged;
  final void Function(String userId, int value) onPercentageChanged;
  final void Function(String userId) onExemptionToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Split Rule', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: SplitRuleType.values
              .map(
                (SplitRuleType type) => HearthChip(
                  label: _labelForType(type),
                  selected: type == selectedType,
                  onTap: () => onTypeChanged(type),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        switch (selectedType) {
          SplitRuleType.equal => _EqualRulePreview(participants: participants),
          SplitRuleType.percentage => _PercentageRuleEditor(
              participants: participants,
              percentages: percentages,
              onChanged: onPercentageChanged,
            ),
          SplitRuleType.fixed => _FixedRuleEditor(
              participants: participants,
              fixedControllers: fixedControllers,
              amountCents: amountCents,
            ),
          SplitRuleType.exemption => _ExemptionRuleEditor(
              participants: participants,
              exemptUserIds: exemptUserIds,
              onToggle: onExemptionToggled,
            ),
        },
      ],
    );
  }

  String _labelForType(SplitRuleType type) {
    return switch (type) {
      SplitRuleType.equal => 'Equal',
      SplitRuleType.percentage => 'Percentage',
      SplitRuleType.fixed => 'Fixed',
      SplitRuleType.exemption => 'Exemption',
    };
  }
}

class _EqualRulePreview extends StatelessWidget {
  const _EqualRulePreview({
    required this.participants,
  });

  final List<FinanceParticipant> participants;

  @override
  Widget build(BuildContext context) {
    return Text(
      'The total will be split evenly across ${participants.length} household members in their current order.',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _PercentageRuleEditor extends StatelessWidget {
  const _PercentageRuleEditor({
    required this.participants,
    required this.percentages,
    required this.onChanged,
  });

  final List<FinanceParticipant> participants;
  final Map<String, int> percentages;
  final void Function(String userId, int value) onChanged;

  @override
  Widget build(BuildContext context) {
    final total = percentages.values.fold<int>(0, (int left, int right) => left + right);
    return Column(
      children: <Widget>[
        for (final participant in participants) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  participant.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${percentages[participant.userId] ?? 0}%',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
          Slider(
            value: (percentages[participant.userId] ?? 0).toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            label: '${percentages[participant.userId] ?? 0}%',
            onChanged: (double value) => onChanged(
              participant.userId,
              value.round(),
            ),
          ),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total: $total%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: total == 100
                  ? AppColors.successFor(Theme.of(context).brightness)
                  : AppColors.errorFor(Theme.of(context).brightness),
            ),
          ),
        ),
      ],
    );
  }
}

class _FixedRuleEditor extends StatelessWidget {
  const _FixedRuleEditor({
    required this.participants,
    required this.fixedControllers,
    required this.amountCents,
  });

  final List<FinanceParticipant> participants;
  final Map<String, TextEditingController> fixedControllers;
  final int? amountCents;

  @override
  Widget build(BuildContext context) {
    final allocated = fixedControllers.values.fold<int>(0, (
      int total,
      TextEditingController controller,
    ) {
      final raw = controller.text.trim();
      if (raw.isEmpty) {
        return total;
      }
      final parsed = double.tryParse(raw);
      if (parsed == null) {
        return total;
      }
      return total + (parsed * 100).round();
    });
    return Column(
      children: <Widget>[
        for (final participant in participants) ...<Widget>[
          HearthTextField(
            label: participant.displayName,
            controller: fixedControllers[participant.userId],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hintText: '0.00',
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            amountCents == null
                ? 'Add an amount to validate fixed allocations.'
                : 'Allocated ${_formatCents(allocated)} of ${_formatCents(amountCents!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  String _formatCents(int value) {
    final dollars = (value / 100).toStringAsFixed(2);
    return '\$$dollars';
  }
}

class _ExemptionRuleEditor extends StatelessWidget {
  const _ExemptionRuleEditor({
    required this.participants,
    required this.exemptUserIds,
    required this.onToggle,
  });

  final List<FinanceParticipant> participants;
  final Set<String> exemptUserIds;
  final void Function(String userId) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: participants
          .map(
            (FinanceParticipant participant) => HearthChip(
              label: participant.displayName,
              selected: exemptUserIds.contains(participant.userId),
              onTap: () => onToggle(participant.userId),
            ),
          )
          .toList(),
    );
  }
}
