import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart'
    show ThousandsSeparatorInputFormatter, stripAmount;

class CategoryBudgetOption {
  const CategoryBudgetOption({required this.accountId, required this.label});

  final String accountId;
  final String label;
}

Future<({String accountId, double amount})?> showAddCategoryBudgetSheet(
  BuildContext context, {
  required List<CategoryBudgetOption> options,
}) {
  return showModalBottomSheet<({String accountId, double amount})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final maxH = MediaQuery.sizeOf(sheetContext).height * 0.85;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: maxH,
          child: _AddCategoryBudgetSheet(options: options),
        ),
      );
    },
  );
}

class _AddCategoryBudgetSheet extends StatefulWidget {
  const _AddCategoryBudgetSheet({required this.options});

  final List<CategoryBudgetOption> options;

  @override
  State<_AddCategoryBudgetSheet> createState() => _AddCategoryBudgetSheetState();
}

class _AddCategoryBudgetSheetState extends State<_AddCategoryBudgetSheet> {
  CategoryBudgetOption? _selectedOption;
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();

  @override
  void dispose() {
    _amountFocus.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final selectedOption = _selectedOption;
    if (selectedOption == null) return;
    final v = double.tryParse(stripAmount(_amountController.text));
    if (v == null || v <= 0) return;
    Navigator.of(context).pop((accountId: selectedOption.accountId, amount: v));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_selectedOption == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            child: Text('新增分類預算', style: theme.textStyles.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text('選擇要設定上限的支出分類', style: theme.textStyles.bodyMuted),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
              itemCount: widget.options.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
              itemBuilder: (context, i) {
                final option = widget.options[i];
                return ListTile(
                  title: Text(option.label, style: theme.textStyles.bodyLarge),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  onTap: () {
                    setState(() => _selectedOption = option);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _amountFocus.requestFocus();
                    });
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() {
                    _selectedOption = null;
                    _amountController.clear();
                  });
                  _amountFocus.unfocus();
                },
              ),
              Expanded(
                child: Text(
                  _selectedOption!.label,
                  style: theme.textStyles.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text('預算上限', style: theme.textStyles.sectionLabel),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _amountController,
            focusNode: _amountFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [ThousandsSeparatorInputFormatter()],
            decoration: InputDecoration(
              hintText: '輸入金額',
              prefixText: '\$ ',
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: FilledButton(onPressed: _submit, child: const Text('加入')),
        ),
      ],
    );
  }
}
