import 'package:flutter/material.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart'
    show ThousandsSeparatorInputFormatter, stripAmount;
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';

class CategoryBudgetOption {
  const CategoryBudgetOption({required this.accountId, required this.label});

  final String accountId;
  final String label;
}

Future<({String accountId, double amount})?> showAddCategoryBudgetSheet(
  BuildContext context, {
  required List<CategoryBudgetOption> options,
}) {
  return showAppBottomSheet<({String accountId, double amount})>(
    context,
    mode: AppBottomSheetMode.scrollable,
    initialChildSize: 0.85,
    maxChildSize: 0.95,
    scrollableBuilder: (_, scrollController) =>
        _AddCategoryBudgetSheet(options: options, scrollController: scrollController),
  );
}

class _AddCategoryBudgetSheet extends StatefulWidget {
  const _AddCategoryBudgetSheet({
    required this.options,
    required this.scrollController,
  });

  final List<CategoryBudgetOption> options;
  final ScrollController scrollController;

  @override
  State<_AddCategoryBudgetSheet> createState() => _AddCategoryBudgetSheetState();
}

class _AddCategoryBudgetSheetState extends State<_AddCategoryBudgetSheet> {
  static const Duration _stepAnimationDuration = Duration(milliseconds: 300);
  static const Curve _stepAnimationCurve = Curves.easeOutCubic;

  CategoryBudgetOption? _selectedOption;
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
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

  Future<void> _animateToAmountStep(CategoryBudgetOption option) async {
    setState(() => _selectedOption = option);
    await _pageController.animateToPage(
      1,
      duration: _stepAnimationDuration,
      curve: _stepAnimationCurve,
    );
    if (mounted) _amountFocus.requestFocus();
  }

  Future<void> _animateBackToCategoryStep() async {
    _amountFocus.unfocus();
    await _pageController.animateToPage(
      0,
      duration: _stepAnimationDuration,
      curve: _stepAnimationCurve,
    );
    if (!mounted) return;
    setState(() {
      _selectedOption = null;
      _amountController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selectedOption = _selectedOption;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Column(
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
                controller: widget.scrollController,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                itemCount: widget.options.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: cs.outline.withValues(alpha: 0.12)),
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  return ListTile(
                    title: Text(option.label, style: theme.textStyles.bodyLarge),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    onTap: () => _animateToAmountStep(option),
                  );
                },
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: _animateBackToCategoryStep,
                          ),
                          Expanded(
                            child: Text(
                              selectedOption?.label ?? '',
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                        decoration: InputDecoration(
                          hintText: '輸入金額',
                          prefixText: '\$ ',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + viewInsets.bottom),
              child: FilledButton(onPressed: _submit, child: const Text('加入')),
            ),
          ],
        ),
      ],
    );
  }
}
