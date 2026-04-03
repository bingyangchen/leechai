import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/account/data/repositories/account.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/budget/data/repositories/budget.dart';
import 'package:mobile/features/budget/data/services/budget.dart';
import 'package:mobile/features/budget/presentation/widgets/add_category_budget_sheet.dart';
import 'package:mobile/features/statistics/data/services/statistics.dart';
import 'package:mobile/features/statistics/presentation/constants/category_colors.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/snackbar.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';
import 'package:mobile/shared/widgets/meta_chip.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key, this.refreshTrigger});

  final ValueListenable<int>? refreshTrigger;

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final TextEditingController _totalController = TextEditingController();
  late Map<String, double> _categoryAmounts;
  late Map<String, double> _initialCategoryAmounts;
  late Map<String, Account> _expenseAccountsById;
  double? _initialTotal;
  bool _loading = true;
  late Future<_Suggestions> _suggestionsFuture;
  late Future<double> _spentExpenseFuture;

  int get _year => DateTime.now().year;
  int get _month => DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _suggestionsFuture = _loadSuggestions();
    _spentExpenseFuture = _spentExpenseThisMonth();
    _load();
  }

  Future<_Suggestions> _loadSuggestions() async {
    final now = DateTime.now();
    final avg = await BudgetService.averageExpenseLastThreeFullMonths(now);
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    final prevTotal = await BudgetRepository.getTotalForMonth(
      prevMonth.year,
      prevMonth.month,
    );
    final prevCategories = await BudgetRepository.getCategoryBudgetsForMonth(
      prevMonth.year,
      prevMonth.month,
    );
    return _Suggestions(
      suggestedFromAverage: avg,
      lastMonthTotal: prevTotal,
      lastMonthCategoryBudgets: Map<String, double>.from(prevCategories),
    );
  }

  Future<void> _confirmApplyLastMonthBudget(_Suggestions suggestions) async {
    final total = suggestions.lastMonthTotal;
    if (total == null || total <= 0) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('套用上月預算？'),
        content: const Text('將套用上一個月的總預算與分類預算至本月，尚未儲存的變更將會被覆寫。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('套用'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    _totalController.text = formatAmountForDisplay(total);
    setState(() {
      _categoryAmounts = {
        for (final e in suggestions.lastMonthCategoryBudgets.entries)
          if (e.value > 0) e.key: e.value,
      };
    });
  }

  Future<void> _load() async {
    final total = await BudgetRepository.getTotalForMonth(_year, _month);
    final cats = await BudgetRepository.getCategoryBudgetsForMonth(_year, _month);
    final expenseAccounts = await AccountRepository.getByType(AccountType.expense.name);
    if (!mounted) return;
    setState(() {
      _initialTotal = total;
      _categoryAmounts = Map<String, double>.from(cats);
      _initialCategoryAmounts = Map<String, double>.from(cats);
      _expenseAccountsById = {
        for (final account in expenseAccounts) account.id: account,
      };
      _totalController.text = total != null && total > 0
          ? formatAmountForDisplay(total)
          : '';
      _loading = false;
    });
  }

  @override
  void dispose() {
    _totalController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    if (_loading) return false;
    if (!_totalMatchesSaved()) return true;
    if (_categoryAmounts.length != _initialCategoryAmounts.length) return true;
    for (final entry in _categoryAmounts.entries) {
      final saved = _initialCategoryAmounts[entry.key];
      if (saved == null || (saved - entry.value).abs() > 0.01) return true;
    }
    for (final key in _initialCategoryAmounts.keys) {
      if (!_categoryAmounts.containsKey(key)) return true;
    }
    return false;
  }

  bool _totalMatchesSaved() {
    final parsed = _parseTotal();
    final saved = _initialTotal;
    final parsedEmpty = parsed == null || parsed <= 0;
    final savedEmpty = saved == null || saved <= 0;
    if (parsedEmpty && savedEmpty) return true;
    if (parsedEmpty != savedEmpty) return false;
    if (parsed == null || saved == null) return false;
    return (parsed - saved).abs() < 0.01;
  }

  Future<double> _spentExpenseThisMonth() async {
    final start = DateTime(_year, _month, 1);
    final end = DateTime(_year, _month + 1, 0, 23, 59, 59, 999);
    final totals = await StatisticsService.getRangeTotals(start, end);
    return totals.totalExpense;
  }

  double? _parseTotal() {
    final raw = stripAmount(_totalController.text);
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  Future<void> _save() async {
    final total = _parseTotal();
    if (total != null && total < 0) {
      showReplacingSnackBar(context, const SnackBar(content: Text('預算金額不可為負數')));
      return;
    }
    if (total != null && total > 0) {
      await BudgetRepository.upsertTotalForMonth(_year, _month, total);
    } else {
      await BudgetRepository.clearTotalForMonth(_year, _month);
    }

    final initialKeys = _initialCategoryAmounts.keys.toSet();
    final currentKeys = _categoryAmounts.keys.toSet();
    for (final k in initialKeys.difference(currentKeys)) {
      await BudgetRepository.deleteCategoryBudget(_year, _month, k);
    }
    for (final e in _categoryAmounts.entries) {
      if (e.value > 0) {
        await BudgetRepository.upsertCategoryBudget(_year, _month, e.key, e.value);
      } else {
        await BudgetRepository.deleteCategoryBudget(_year, _month, e.key);
      }
    }

    (widget.refreshTrigger as ValueNotifier<int>?)?.value++;
    if (!mounted) return;
    showReplacingSnackBar(
      context,
      const SnackBar(content: Text('已更新預算'), duration: Duration(milliseconds: 1500)),
    );
    Navigator.of(context).pop(true);
  }

  Color _ratioColor(ColorScheme cs, double ratio) {
    if (ratio > 1.0) return cs.error;
    if (ratio >= 0.8) return cs.secondary;
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('捨棄變更？'),
            content: const Text('尚未儲存的變更將會遺失。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('捨棄'),
              ),
            ],
          ),
        );
        if (discard == true && navigator.mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: kToolbarHeight,
          title: const Text('預算'),
          actions: [
            TextButton(
              onPressed: (_loading || !_hasUnsavedChanges) ? null : _save,
              child: Text(
                '完成',
                style: theme.textStyles.labelLargeEmphasis.copyWith(
                  color: (_loading || !_hasUnsavedChanges)
                      ? cs.onSurfaceVariant.withValues(alpha: 0.38)
                      : cs.primary,
                ),
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  32.0 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                children: [
                  Text('本月總預算', style: theme.textStyles.sectionLabel),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _totalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: InputDecoration(
                      hintText: '輸入金額',
                      prefixText: '\$ ',
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                  _buildPreview(theme),
                  const SizedBox(height: 24),
                  FutureBuilder<_Suggestions>(
                    future: _suggestionsFuture,
                    builder: (context, snap) {
                      Widget child = const SizedBox.shrink();
                      if (snap.hasData && stripAmount(_totalController.text).isEmpty) {
                        final s = snap.data!;
                        final hasSuggestionChips =
                            s.suggestedFromAverage > 0 ||
                            (s.lastMonthTotal != null && s.lastMonthTotal! > 0);
                        if (hasSuggestionChips) {
                          child = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('建議預算', style: theme.textStyles.sectionLabel),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (s.suggestedFromAverage > 0)
                                    MetaChip(
                                      icon: Icons.auto_awesome_outlined,
                                      label:
                                          '使用建議 \$${formatAmountForDisplay(s.suggestedFromAverage)}',
                                      onTap: () {
                                        _totalController.text = formatAmountForDisplay(
                                          s.suggestedFromAverage,
                                        );
                                        setState(() {});
                                      },
                                    ),
                                  if (s.lastMonthTotal != null && s.lastMonthTotal! > 0)
                                    MetaChip(
                                      icon: Icons.event_repeat_outlined,
                                      label:
                                          '與上月相同 \$${formatAmountForDisplay(s.lastMonthTotal!)}',
                                      onTap: () => _confirmApplyLastMonthBudget(s),
                                    ),
                                ],
                              ),
                            ],
                          );
                        }
                      }
                      return AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        clipBehavior: Clip.hardEdge,
                        child: child,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildCategorySumWarning(theme),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('分類預算', style: theme.textStyles.sectionLabel),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _onAddCategory,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('新增'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('僅列出已設定上限的分類', style: theme.textStyles.bodySmallMuted),
                  const SizedBox(height: 8),
                  if (_categoryAmounts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('尚未設定分類預算', style: theme.textStyles.bodyMuted),
                      ),
                    )
                  else
                    ..._buildCategoryRows(theme),
                ],
              ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    final cs = theme.colorScheme;
    final total = _parseTotal();
    if (total == null || total <= 0) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        FutureBuilder<double>(
          future: _spentExpenseFuture,
          builder: (context, snap) {
            final spent = snap.data ?? 0.0;
            final ratio = (spent / total).clamp(0.0, 1.0);
            final color = _ratioColor(cs, spent / total);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '已用 \$${formatAmountForDisplay(spent)}',
                  style: theme.textStyles.bodySmallMuted,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 9,
                        width: double.infinity,
                        color: cs.outline.withValues(alpha: 0.12),
                      ),
                      FractionallySizedBox(
                        widthFactor: ratio,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 9,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategorySumWarning(ThemeData theme) {
    final total = _parseTotal() ?? 0;
    final sum = _categoryAmounts.values.fold<double>(0, (a, b) => a + b);
    final show = total > 0 && sum > total + 0.01;
    final cs = theme.colorScheme;

    Widget child = const SizedBox.shrink();
    if (show) {
      child = Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withValues(alpha: 0.22)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: cs.onSurfaceVariant.withValues(alpha: 0.75),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '分類預算合計高於本月總預算，請確認是否為您預期的設定。',
                style: theme.textStyles.bodySmallMuted.copyWith(height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }

  List<Widget> _buildCategoryRows(ThemeData theme) {
    final spentFuture = BudgetService.expenseAmountsBySubTypeForMonth(_year, _month);
    return [
      FutureBuilder<Map<String, double>>(
        future: spentFuture,
        builder: (context, snap) {
          final spentMap = snap.data ?? {};
          final keys = _categoryAmounts.keys.toList()
            ..sort((left, right) {
              final leftName = _expenseAccountsById[left]?.subType ?? left;
              final rightName = _expenseAccountsById[right]?.subType ?? right;
              return leftName.compareTo(rightName);
            });
          return Column(
            children: [
              for (var i = 0; i < keys.length; i++)
                _CategoryBudgetTile(
                  categoryName: _expenseAccountsById[keys[i]]?.subType ?? '其他分類',
                  budgetAmount: _categoryAmounts[keys[i]]!,
                  spentAmount:
                      spentMap[_expenseAccountsById[keys[i]]?.subType ?? '其他'] ?? 0,
                  index: i,
                  onAmountChanged: (value) {
                    setState(() {
                      _categoryAmounts[keys[i]] = value;
                    });
                  },
                  onDelete: () {
                    final accountId = keys[i];
                    final categoryName =
                        _expenseAccountsById[accountId]?.subType ?? '其他分類';
                    final amount = _categoryAmounts[accountId]!;
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _categoryAmounts.remove(accountId);
                    });
                    if (!mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    showReplacingSnackBarForMessenger(
                      messenger,
                      SnackBar(
                        content: Text('已移除「$categoryName」分類預算'),
                        duration: const Duration(seconds: 4),
                        persist: false,
                        action: SnackBarAction(
                          label: '復原',
                          onPressed: () {
                            if (!mounted) return;
                            setState(() {
                              _categoryAmounts[accountId] = amount;
                            });
                            showReplacingSnackBarForMessenger(
                              messenger,
                              const SnackBar(
                                content: Text('已復原'),
                                duration: Duration(milliseconds: 1500),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    ];
  }

  Future<void> _onAddCategory() async {
    if (!mounted) return;
    final availableAccounts =
        _expenseAccountsById.values
            .where((account) => !_categoryAmounts.containsKey(account.id))
            .toList()
          ..sort((left, right) => left.subType.compareTo(right.subType));
    if (availableAccounts.isEmpty) {
      showReplacingSnackBar(context, const SnackBar(content: Text('沒有可新增的分類')));
      return;
    }
    final options = availableAccounts
        .map(
          (account) =>
              CategoryBudgetOption(accountId: account.id, label: account.subType),
        )
        .toList();
    final result = await showAddCategoryBudgetSheet(context, options: options);
    if (result == null || !mounted) return;
    setState(() {
      _categoryAmounts[result.accountId] = result.amount;
    });
  }
}

class _Suggestions {
  _Suggestions({
    required this.suggestedFromAverage,
    this.lastMonthTotal,
    this.lastMonthCategoryBudgets = const {},
  });

  final double suggestedFromAverage;
  final double? lastMonthTotal;
  final Map<String, double> lastMonthCategoryBudgets;
}

class _CategoryBudgetTile extends StatefulWidget {
  const _CategoryBudgetTile({
    required this.categoryName,
    required this.budgetAmount,
    required this.spentAmount,
    required this.index,
    required this.onAmountChanged,
    required this.onDelete,
  });

  final String categoryName;
  final double budgetAmount;
  final double spentAmount;
  final int index;
  final void Function(double value) onAmountChanged;
  final VoidCallback onDelete;

  @override
  State<_CategoryBudgetTile> createState() => _CategoryBudgetTileState();
}

class _CategoryBudgetTileState extends State<_CategoryBudgetTile> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: formatAmountForDisplay(widget.budgetAmount),
    );
  }

  @override
  void didUpdateWidget(_CategoryBudgetTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.budgetAmount != widget.budgetAmount) {
      final next = formatAmountForDisplay(widget.budgetAmount);
      if (stripAmount(_amountController.text) != stripAmount(next)) {
        _amountController.text = next;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ratio = widget.budgetAmount <= 0
        ? 0.0
        : (widget.spentAmount / widget.budgetAmount);
    final barColor = ratio > 1.0
        ? cs.error
        : ratio >= 0.8
        ? cs.secondary
        : cs.primary;
    final color = colorForSubType(context, widget.categoryName, widget.index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.categoryName, style: theme.textStyles.bodyLarge),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 22),
                    onPressed: widget.onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 4,
                      width: double.infinity,
                      color: cs.outline.withValues(alpha: 0.12),
                    ),
                    FractionallySizedBox(
                      widthFactor: ratio.clamp(0.0, 1.0),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatAmountForDisplay(widget.spentAmount)}／${formatAmountForDisplay(widget.budgetAmount)}',
                      style: theme.textStyles.bodySmallMuted,
                    ),
                  ),
                  SizedBox(
                    width: 112,
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      textAlign: TextAlign.end,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        prefixText: '\$ ',
                      ),
                      onChanged: (text) {
                        final v = double.tryParse(stripAmount(text));
                        if (v != null) widget.onAmountChanged(v);
                      },
                      onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
