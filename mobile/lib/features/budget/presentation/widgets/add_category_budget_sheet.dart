import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart'
    show ThousandsSeparatorInputFormatter, stripAmount;

Future<({String subType, double amount})?> showAddCategoryBudgetSheet(
  BuildContext context, {
  required List<String> subTypes,
}) {
  return showModalBottomSheet<({String subType, double amount})>(
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
          child: _AddCategoryBudgetSheet(subTypes: subTypes),
        ),
      );
    },
  );
}

class _AddCategoryBudgetSheet extends StatefulWidget {
  const _AddCategoryBudgetSheet({required this.subTypes});

  final List<String> subTypes;

  @override
  State<_AddCategoryBudgetSheet> createState() => _AddCategoryBudgetSheetState();
}

class _AddCategoryBudgetSheetState extends State<_AddCategoryBudgetSheet> {
  String? _selected;
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();

  @override
  void dispose() {
    _amountFocus.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final selected = _selected;
    if (selected == null) return;
    final v = double.tryParse(stripAmount(_amountController.text));
    if (v == null || v <= 0) return;
    Navigator.of(context).pop((subType: selected, amount: v));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_selected == null) {
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
              itemCount: widget.subTypes.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
              itemBuilder: (context, i) {
                final s = widget.subTypes[i];
                return ListTile(
                  title: Text(s, style: theme.textStyles.bodyLarge),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  onTap: () {
                    setState(() => _selected = s);
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
                    _selected = null;
                    _amountController.clear();
                  });
                  _amountFocus.unfocus();
                },
              ),
              Expanded(
                child: Text(
                  _selected!,
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
