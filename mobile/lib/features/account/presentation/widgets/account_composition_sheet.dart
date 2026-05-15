import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/account/domain/asset_type.dart';
import 'package:mobile/features/account/domain/liability_type.dart';
import 'package:mobile/shared/theme/category_colors.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class AccountCompositionSheet extends StatefulWidget {
  const AccountCompositionSheet({
    super.key,
    required this.accounts,
    required this.balances,
    required this.isLiability,
    required this.privacyMode,
    required this.onAddAssetAccount,
    this.scrollController,
  });

  final List<Account> accounts;
  final Map<String, double> balances;
  final bool isLiability;
  final bool privacyMode;
  final VoidCallback onAddAssetAccount;
  final ScrollController? scrollController;

  @override
  State<AccountCompositionSheet> createState() => _AccountCompositionSheetState();
}

class _AccountCompositionSheetState extends State<AccountCompositionSheet> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final items =
        widget.accounts
            .map(
              (account) => _CompositionItem(
                account: account,
                amount: (widget.balances[account.id] ?? 0).abs(),
              ),
            )
            .where((item) => item.amount > 0)
            .toList()
          ..sort((left, right) => right.amount.compareTo(left.amount));
    final total = items.fold<double>(0, (sum, item) => sum + item.amount);

    if (widget.accounts.isEmpty) {
      return ListView(
        controller: widget.scrollController,
        padding: EdgeInsets.zero,
        children: [
          _EmptyCompositionState(
            isLiability: widget.isLiability,
            hasAccounts: false,
            onAddAssetAccount: widget.onAddAssetAccount,
          ),
        ],
      );
    }

    if (total <= 0) {
      return ListView(
        controller: widget.scrollController,
        padding: EdgeInsets.zero,
        children: [
          _EmptyCompositionState(
            isLiability: widget.isLiability,
            hasAccounts: true,
            onAddAssetAccount: widget.onAddAssetAccount,
          ),
        ],
      );
    }

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        _CompositionDonutChart(
          items: items,
          total: total,
          isLiability: widget.isLiability,
          privacyMode: widget.privacyMode,
          touchedIndex: _touchedIndex,
          onSectionTouched: (index) => setState(() => _touchedIndex = index),
        ),
        const SizedBox(height: 8),
        _CompositionLegend(items: items, total: total),
      ],
    );
  }
}

class _CompositionDonutChart extends StatelessWidget {
  const _CompositionDonutChart({
    required this.items,
    required this.total,
    required this.isLiability,
    required this.privacyMode,
    required this.touchedIndex,
    required this.onSectionTouched,
  });

  final List<_CompositionItem> items;
  final double total;
  final bool isLiability;
  final bool privacyMode;
  final int? touchedIndex;
  final void Function(int?) onSectionTouched;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final touched = touchedIndex;
    final hasTouched = touched != null && touched >= 0 && touched < items.length;
    final displayLabel = hasTouched
        ? _accountName(items[touched].account)
        : isLiability
        ? '總負債'
        : '總資產';
    final displayAmount = privacyMode
        ? '****'
        : formatAmountForDisplay(hasTouched ? items[touched].amount : total);

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  onSectionTouched(response?.touchedSection?.touchedSectionIndex);
                },
              ),
              sectionsSpace: 2,
              centerSpaceRadius: 72,
              sections: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isTouched = hasTouched && index == touched;
                final opacity = hasTouched && !isTouched ? 0.32 : 1.0;
                return PieChartSectionData(
                  value: item.amount,
                  title: '',
                  color: colorForCategoryIndex(
                    context,
                    index,
                  ).withValues(alpha: opacity),
                  radius: isTouched ? 34 : 26,
                );
              }).toList(),
            ),
            duration: const Duration(milliseconds: 200),
          ),
          Transform.translate(
            offset: const Offset(0, -5),
            child: SizedBox(
              width: 124,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayLabel,
                    style: theme.textStyles.bodySmallMuted,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '\$$displayAmount',
                      style: theme.textStyles.headlineSmallEmphasis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompositionLegend extends StatelessWidget {
  const _CompositionLegend({required this.items, required this.total});

  final List<_CompositionItem> items;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final percentage = total <= 0 ? 0.0 : item.amount / total * 100;
        return _CompositionLegendChip(
          label: _accountName(item.account),
          percentage: percentage,
          color: colorForCategoryIndex(context, index),
        );
      }).toList(),
    );
  }
}

class _CompositionLegendChip extends StatelessWidget {
  const _CompositionLegendChip({
    required this.label,
    required this.percentage,
    required this.color,
  });

  final String label;
  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 36, maxWidth: 176),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textStyles.bodySmallMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: theme.textStyles.labelEmphasis,
          ),
        ],
      ),
    );
  }
}

class _EmptyCompositionState extends StatelessWidget {
  const _EmptyCompositionState({
    required this.isLiability,
    required this.hasAccounts,
    required this.onAddAssetAccount,
  });

  final bool isLiability;
  final bool hasAccounts;
  final VoidCallback onAddAssetAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = isLiability
        ? hasAccounts
              ? '還沒有可分析的負債餘額'
              : '目前沒有負債帳戶'
        : hasAccounts
        ? '還沒有可分析的資產餘額'
        : '還沒有資產帳戶';
    final description = isLiability
        ? hasAccounts
              ? '有未繳金額或貸款餘額後，這裡會顯示負債組成。'
              : '新增信用卡或貸款後，可查看負債組成。'
        : hasAccounts
        ? '新增餘額或記一筆交易後，這裡會顯示資產組成。'
        : '先新增一個資產帳戶，開始掌握你的資產分布。';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLiability ? Icons.credit_card_off_rounded : Icons.donut_large_rounded,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textStyles.titleEmphasis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: theme.textStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
          if (!isLiability && !hasAccounts) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddAssetAccount,
              icon: const Icon(Icons.add),
              label: const Text('新增資產帳戶'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompositionItem {
  const _CompositionItem({required this.account, required this.amount});

  final Account account;
  final double amount;
}

String _accountName(Account account) {
  if (account.name case final name?) return name;
  final assetType = AssetTypeX.fromName(account.subType);
  if (assetType != null) return assetType.label;
  final liabilityType = LiabilityTypeX.fromName(account.subType);
  if (liabilityType != null) return liabilityType.label;
  return account.subType.isNotEmpty ? account.subType : '帳戶';
}
