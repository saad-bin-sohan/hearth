import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_colors.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/hearth_avatar.dart';
import 'package:hearth/core/widgets/hearth_bottom_sheet.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_chip.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/finance/domain/finance_models.dart';
import 'package:hearth/features/finance/presentation/finance_notifier.dart';
import 'package:hearth/features/finance/presentation/widgets/split_rule_configurator.dart';

Future<void> showAddExpenseSheet(
  BuildContext context, {
  ExpenseEntity? initialExpense,
  bool startAsRecurring = false,
}) {
  return showHearthBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
      return AddExpenseSheet(
        initialExpense: initialExpense,
        startAsRecurring: startAsRecurring,
      );
    },
  );
}

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({
    this.initialExpense,
    this.startAsRecurring = false,
    super.key,
  });

  final ExpenseEntity? initialExpense;
  final bool startAsRecurring;

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final Map<String, TextEditingController> _fixedControllers =
      <String, TextEditingController>{};

  DateTime _selectedDate = DateTime.now();
  FinanceCategory _selectedCategory = FinanceCategory.groceries;
  SplitRuleType _selectedSplitType = SplitRuleType.equal;
  RecurrenceFrequency _selectedRecurrence = RecurrenceFrequency.monthly;
  String? _payerUserId;
  bool _isRecurring = false;
  bool _initialized = false;
  final Map<String, int> _percentages = <String, int>{};
  final Set<String> _exemptUserIds = <String>{};

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    for (final controller in _fixedControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financeContext = ref.watch(financeContextProvider);
    final actionState = ref.watch(financeNotifierProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: financeContext.when(
          data: (FinanceContext? value) {
            if (value == null) {
              return const SizedBox.shrink();
            }
            _initialize(value);
            final amountCents = AppFormatters.centsFromInput(
              _amountController.text,
            );
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.initialExpense == null
                          ? (_isRecurring
                                ? 'Add Recurring Bill'
                                : 'Add Expense')
                          : (_isRecurring
                                ? 'Edit Recurring Bill'
                                : 'Edit Expense'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Store a household expense with a stable split snapshot and live balance impact.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    HearthTextField(
                      label: 'Amount',
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: '0.00',
                      validator: (String? value) {
                        final cents = AppFormatters.centsFromInput(value ?? '');
                        if (cents == null || cents <= 0) {
                          return 'Enter an amount greater than zero.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    HearthTextField(
                      label: 'Title',
                      controller: _titleController,
                      validator: (String? value) {
                        if (value == null || value.trim().length < 3) {
                          return 'Use at least 3 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: FinanceCategory.values.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (BuildContext context, int index) {
                          final category = FinanceCategory.values[index];
                          return HearthChip(
                            label: category.label,
                            selected: category == _selectedCategory,
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Date', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    HearthButton(
                      label: AppFormatters.shortDate(_selectedDate),
                      expanded: false,
                      variant: HearthButtonVariant.ghost,
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: _selectedDate,
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Paid by',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: value.participants.map((
                        FinanceParticipant participant,
                      ) {
                        final selected = participant.userId == _payerUserId;
                        return InkWell(
                          borderRadius: BorderRadius.circular(
                            AppRadius.radiusFull,
                          ),
                          onTap: () {
                            setState(() {
                              _payerUserId = participant.userId;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryContainerFor(
                                      Theme.of(context).brightness,
                                    )
                                  : AppColors.surfaceVariantFor(
                                      Theme.of(context).brightness,
                                    ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.radiusFull,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                HearthAvatar(
                                  displayName: participant.displayName,
                                  size: 32,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(participant.displayName),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SplitRuleConfigurator(
                      participants: value.participants,
                      selectedType: _selectedSplitType,
                      amountCents: amountCents,
                      percentages: _percentages,
                      fixedControllers: _fixedControllers,
                      exemptUserIds: _exemptUserIds,
                      onTypeChanged: (SplitRuleType type) {
                        setState(() {
                          _selectedSplitType = type;
                        });
                      },
                      onPercentageChanged: _handlePercentageChanged,
                      onExemptionToggled: (String userId) {
                        setState(() {
                          if (_exemptUserIds.contains(userId)) {
                            _exemptUserIds.remove(userId);
                          } else {
                            _exemptUserIds.add(userId);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Recurring bill',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      subtitle: Text(
                        'Use a template that generates due instances on launch.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      value: _isRecurring,
                      onChanged: (bool value) {
                        setState(() {
                          _isRecurring = value;
                        });
                      },
                    ),
                    if (_isRecurring) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: RecurrenceFrequency.values.map((
                          RecurrenceFrequency frequency,
                        ) {
                          return HearthChip(
                            label: _recurrenceLabel(frequency),
                            selected: frequency == _selectedRecurrence,
                            onTap: () {
                              setState(() {
                                _selectedRecurrence = frequency;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    HearthTextField(
                      label: 'Notes',
                      controller: _notesController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Receipt capture is reserved for a later phase. This record is ready for it.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (actionState.message != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        actionState.message!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.errorFor(
                            Theme.of(context).brightness,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    HearthButton(
                      label: widget.initialExpense == null ? 'Save' : 'Update',
                      isLoading: actionState.isLoading,
                      onPressed: value.canEdit
                          ? () async {
                              if (!(_formKey.currentState?.validate() ??
                                  false)) {
                                return;
                              }
                              final draft = _buildDraft(value);
                              if (draft == null) {
                                setState(() {});
                                return;
                              }
                              try {
                                if (widget.initialExpense == null) {
                                  await ref
                                      .read(financeNotifierProvider.notifier)
                                      .addExpense(draft);
                                } else {
                                  await ref
                                      .read(financeNotifierProvider.notifier)
                                      .updateExpense(draft);
                                }
                                if (!context.mounted) {
                                  return;
                                }
                                Navigator.of(context).pop();
                              } on StateError {
                                return;
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, _) => Center(child: Text('$error')),
        ),
      ),
    );
  }

  void _initialize(FinanceContext context) {
    if (_initialized) {
      return;
    }
    final initial = widget.initialExpense;
    _selectedDate = initial?.expenseDate ?? DateTime.now();
    _selectedCategory = initial?.category ?? FinanceCategory.groceries;
    _payerUserId = initial?.paidByUserId ?? context.currentUserId;
    _isRecurring = initial?.isRecurringTemplate ?? widget.startAsRecurring;
    if (initial != null) {
      _amountController.text = (initial.amountCents / 100).toStringAsFixed(2);
      _titleController.text = initial.title;
      _notesController.text = initial.notes ?? '';
    }
    for (final participant in context.participants) {
      _fixedControllers[participant.userId] = TextEditingController();
    }
    final splitRule = initial?.splitRule;
    if (splitRule is PercentageSplitRule) {
      _selectedSplitType = SplitRuleType.percentage;
      _percentages.addAll(splitRule.percentages);
    } else if (splitRule is FixedSplitRule) {
      _selectedSplitType = SplitRuleType.fixed;
      for (final entry in splitRule.amountsCents.entries) {
        _fixedControllers[entry.key]?.text = (entry.value / 100)
            .toStringAsFixed(2);
      }
    } else if (splitRule is ExemptionSplitRule) {
      _selectedSplitType = SplitRuleType.exemption;
      _exemptUserIds.addAll(splitRule.exemptUserIds);
    } else {
      _selectedSplitType = SplitRuleType.equal;
    }
    if (_percentages.isEmpty) {
      final participants = context.participants;
      final base = 100 ~/ participants.length;
      final remainder = 100 % participants.length;
      for (var index = 0; index < participants.length; index += 1) {
        _percentages[participants[index].userId] =
            base + (index < remainder ? 1 : 0);
      }
    }
    _initialized = true;
  }

  void _handlePercentageChanged(String userId, int value) {
    final current = _percentages[userId] ?? 0;
    var delta = value - current;
    final updated = <String, int>{..._percentages, userId: value};
    final otherIds = updated.keys.where((String key) => key != userId).toList();
    var index = 0;
    while (delta > 0 && otherIds.isNotEmpty) {
      final targetId = otherIds[index % otherIds.length];
      final available = updated[targetId] ?? 0;
      if (available > 0) {
        updated[targetId] = available - 1;
        delta -= 1;
      }
      index += 1;
      if (index > 500) {
        break;
      }
    }
    while (delta < 0 && otherIds.isNotEmpty) {
      final targetId = otherIds[index % otherIds.length];
      updated[targetId] = (updated[targetId] ?? 0) + 1;
      delta += 1;
      index += 1;
      if (index > 500) {
        break;
      }
    }
    setState(() {
      _percentages
        ..clear()
        ..addAll(updated);
    });
  }

  ExpenseDraft? _buildDraft(FinanceContext context) {
    final amountCents = AppFormatters.centsFromInput(_amountController.text);
    if (amountCents == null || amountCents <= 0 || _payerUserId == null) {
      return null;
    }
    final participantIds = context.participants.map((
      FinanceParticipant participant,
    ) {
      return participant.userId;
    }).toList();
    final splitRule = switch (_selectedSplitType) {
      SplitRuleType.equal => EqualSplitRule(participantUserIds: participantIds),
      SplitRuleType.percentage => PercentageSplitRule(
        participantUserIds: participantIds,
        percentages: _percentages,
      ),
      SplitRuleType.fixed => FixedSplitRule(
        participantUserIds: participantIds,
        amountsCents: <String, int>{
          for (final entry in _fixedControllers.entries)
            entry.key: AppFormatters.centsFromInput(entry.value.text) ?? 0,
        },
      ),
      SplitRuleType.exemption => ExemptionSplitRule(
        participantUserIds: participantIds,
        exemptUserIds: _exemptUserIds.toList(),
      ),
    };

    return ExpenseDraft(
      id: widget.initialExpense?.id,
      householdId: context.householdId,
      title: _titleController.text,
      amountCents: amountCents,
      category: _selectedCategory,
      paidByUserId: _payerUserId!,
      expenseDate: _selectedDate,
      splitRule: splitRule,
      isRecurring: _isRecurring,
      isRecurringTemplate: _isRecurring,
      recurrenceRule: _isRecurring
          ? RecurrenceRule(
              frequency: _selectedRecurrence,
              anchorDate: _selectedDate,
            )
          : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      receiptReference: widget.initialExpense?.receiptReference,
      sourceRecurringExpenseId: widget.initialExpense?.sourceRecurringExpenseId,
      nextDueAt: _isRecurring ? _selectedDate : null,
      lastGeneratedAt: widget.initialExpense?.lastGeneratedAt,
      isSettled: widget.initialExpense?.isSettled ?? false,
    );
  }

  String _recurrenceLabel(RecurrenceFrequency frequency) {
    return switch (frequency) {
      RecurrenceFrequency.weekly => 'Weekly',
      RecurrenceFrequency.monthly => 'Monthly',
      RecurrenceFrequency.quarterly => 'Quarterly',
      RecurrenceFrequency.yearly => 'Yearly',
    };
  }
}
