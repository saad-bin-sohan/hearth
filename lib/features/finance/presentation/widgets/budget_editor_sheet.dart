import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hearth/core/theme/app_dimensions.dart';
import 'package:hearth/core/utils/formatters.dart';
import 'package:hearth/core/widgets/hearth_button.dart';
import 'package:hearth/core/widgets/hearth_text_field.dart';
import 'package:hearth/features/finance/domain/finance_models.dart';
import 'package:hearth/features/finance/presentation/finance_notifier.dart';

class BudgetEditorSheet extends ConsumerStatefulWidget {
  const BudgetEditorSheet({required this.progress, super.key});

  final BudgetProgress progress;

  @override
  ConsumerState<BudgetEditorSheet> createState() => _BudgetEditorSheetState();
}

class _BudgetEditorSheetState extends ConsumerState<BudgetEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.progress.limitCents == null
          ? ''
          : (widget.progress.limitCents! / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeNotifierProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Set ${widget.progress.category.label} budget',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            HearthTextField(
              label: 'Monthly limit',
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              hintText: '0.00',
            ),
            const SizedBox(height: AppSpacing.lg),
            HearthButton(
              label: 'Save Budget',
              isLoading: financeState.isLoading,
              onPressed: () async {
                final limit = AppFormatters.centsFromInput(
                  _amountController.text,
                );
                await ref
                    .read(financeNotifierProvider.notifier)
                    .setBudget(
                      category: widget.progress.category,
                      limitCents: limit,
                    );
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            HearthButton(
              label: 'Clear Budget',
              variant: HearthButtonVariant.ghost,
              onPressed: () async {
                await ref
                    .read(financeNotifierProvider.notifier)
                    .setBudget(
                      category: widget.progress.category,
                      limitCents: null,
                    );
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
