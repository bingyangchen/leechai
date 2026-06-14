import 'package:flutter/material.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/account/domain/asset_type.dart';
import 'package:mobile/features/account/presentation/widgets/account_balance_chart.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class AccountSummaryHeader extends StatelessWidget {
  const AccountSummaryHeader({
    super.key,
    required this.account,
    required this.balance,
    required this.privacyMode,
    required this.balanceHistory,
    required this.totalAdjustments,
    required this.topPadding,
    this.onUpdateMarketValue,
  });

  final Account account;
  final double balance;
  final bool privacyMode;
  final List<({DateTime date, double balance})> balanceHistory;
  final double totalAdjustments;
  final double topPadding;
  final VoidCallback? onUpdateMarketValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isSecurities = account.subType == AssetType.securities.name;
    final isLiability = account.type == AccountType.liability;
    final displayBalance = isLiability ? balance.abs() : balance;
    final balanceText = privacyMode ? '****' : formatAmountForDisplay(displayBalance);

    String labelText;
    if (isLiability) {
      labelText = '當前欠款';
    } else if (isSecurities) {
      labelText = '當前估值';
    } else {
      labelText = '當前餘額';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPadding - 4, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(labelText, style: theme.textStyles.labelSmallMuted),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '\$$balanceText',
                  style: theme.textStyles.headlineLargeEmphasis.copyWith(fontSize: 32),
                ),
              ),
              if (isSecurities && onUpdateMarketValue != null)
                OutlinedButton.icon(
                  onPressed: onUpdateMarketValue,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.06),
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                      width: 1,
                    ),
                    foregroundColor: colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  icon: const Icon(Icons.trending_up, size: 14),
                  label: const Text(
                    '更新市值',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          if (isSecurities && balanceHistory.length >= 2) ...[
            const SizedBox(height: 12),
            AccountBalanceChart(history: balanceHistory, privacyMode: privacyMode),
          ],
        ],
      ),
    );
  }
}
