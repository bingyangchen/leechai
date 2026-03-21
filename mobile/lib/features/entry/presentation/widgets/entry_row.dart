import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/constants/entry_type_colors.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';

class EntryRow extends StatefulWidget {
  const EntryRow({
    super.key,
    required this.entry,
    required this.accounts,
    required this.entryTagTitles,
    required this.privacyMode,
    required this.onTap,
    required this.onDelete,
    required this.onCopy,
    this.perspectiveAccountId,
  });

  final Map<String, Object?> entry;
  final Map<String, Account> accounts;
  final Map<String, List<String>> entryTagTitles;
  final bool privacyMode;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final String? perspectiveAccountId;

  static const double _actionPaneExtentRatio = 0.25;

  @override
  State<EntryRow> createState() => _EntryRowState();
}

class _EntryRowState extends State<EntryRow> with SingleTickerProviderStateMixin {
  late final SlidableController _slidableController;

  @override
  void initState() {
    super.initState();
    _slidableController = SlidableController(this);
  }

  @override
  void dispose() {
    _slidableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeStr = widget.entry['type'] as String? ?? 'expense';
    final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
    final amount = (widget.entry['amount'] as num?)?.toDouble() ?? 0.0;
    final memo = widget.entry['memo'] as String?;
    final debitId = widget.entry['debit_account_id'] as String? ?? '';
    final creditId = widget.entry['credit_account_id'] as String? ?? '';
    final debitAccount = widget.accounts[debitId];
    final creditAccount = widget.accounts[creditId];

    String title;
    if (memo != null && memo.trim().isNotEmpty) {
      final firstLine = memo.split('\n').first.trim();
      title = firstLine.length > 20 ? '${firstLine.substring(0, 20)}…' : firstLine;
    } else {
      title = _categoryLabel(type, debitAccount, creditAccount);
    }

    final accountLabel = _accountLabel(type, debitAccount, creditAccount);
    final entryId = widget.entry['id'] as String? ?? '';
    final tagTitles = widget.entryTagTitles[entryId] ?? [];

    final color = type == EntryType.adjustment && widget.perspectiveAccountId != null
        ? EntryTypeColors.forAdjustment(
            context,
            isGain: widget.perspectiveAccountId == debitId,
          )
        : EntryTypeColors.forType(context, type);
    final amountText = widget.privacyMode
        ? '****'
        : (type == EntryType.income
              ? '+${formatAmountForDisplay(amount)}'
              : type == EntryType.expense
              ? '-${formatAmountForDisplay(amount)}'
              : type == EntryType.adjustment
              ? (_adjustmentAmountText(amount, debitId, creditId))
              : formatAmountForDisplay(amount));

    final showCopyAction = type != EntryType.adjustment;
    return Slidable(
      key: ValueKey(widget.entry['id']),
      controller: _slidableController,
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: EntryRow._actionPaneExtentRatio,
        children: [
          _SlidableIconAction(
            controller: _slidableController,
            isStartPane: false,
            icon: Icons.delete_outline,
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            onPressed: widget.onDelete,
          ),
        ],
      ),
      startActionPane: showCopyAction
          ? ActionPane(
              motion: const DrawerMotion(),
              extentRatio: EntryRow._actionPaneExtentRatio,
              children: [
                _SlidableIconAction(
                  controller: _slidableController,
                  isStartPane: true,
                  icon: Icons.copy,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  onPressed: widget.onCopy,
                ),
              ],
            )
          : null,
      child: ListTile(
        onTap: widget.onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _categoryIcon(type, debitAccount, creditAccount),
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: theme.textStyles.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: (accountLabel != null || tagTitles.isNotEmpty)
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (accountLabel != null)
                      Text(
                        accountLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textStyles.bodySmallMuted,
                      ),
                    ...tagTitles.map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('#$t', style: theme.textStyles.labelSmallMuted),
                      ),
                    ),
                  ],
                ),
              )
            : null,
        trailing: Text(
          amountText,
          style: theme.textStyles.titleEmphasis.copyWith(color: color),
        ),
      ),
    );
  }

  String _adjustmentAmountText(double amount, String debitId, String creditId) {
    if (widget.perspectiveAccountId == debitId) {
      return '+${formatAmountForDisplay(amount)}';
    }
    if (widget.perspectiveAccountId == creditId) {
      return '-${formatAmountForDisplay(amount)}';
    }
    return formatAmountForDisplay(amount);
  }

  String _categoryLabel(EntryType type, Account? debit, Account? credit) {
    switch (type) {
      case EntryType.expense:
        return debit?.subType.isNotEmpty == true
            ? debit!.subType
            : (debit?.name ?? '支出');
      case EntryType.income:
        return credit?.subType.isNotEmpty == true
            ? credit!.subType
            : (credit?.name ?? '收入');
      case EntryType.adjustment:
        return type.label;
      default:
        return type.label;
    }
  }

  IconData _categoryIcon(EntryType type, Account? debit, Account? credit) {
    switch (type) {
      case EntryType.expense:
        return debit?.displayIcon ?? Icons.payments;
      case EntryType.income:
        return credit?.displayIcon ?? Icons.trending_up;
      case EntryType.transfer:
        return Icons.swap_horiz;
      case EntryType.borrow:
        return Icons.handshake;
      case EntryType.repay:
        return Icons.reply;
      case EntryType.adjustment:
        return Icons.show_chart;
    }
  }

  String? _accountLabel(EntryType type, Account? debit, Account? credit) {
    switch (type) {
      case EntryType.expense:
        return credit?.name ?? credit?.subType;
      case EntryType.income:
        return debit?.name ?? debit?.subType;
      case EntryType.transfer:
      case EntryType.borrow:
      case EntryType.repay:
        if (debit != null && credit != null) {
          return '${credit.name ?? credit.subType} → ${debit.name ?? debit.subType}';
        }
        return null;
      case EntryType.adjustment:
        return null;
    }
  }
}

class _SlidableIconAction extends StatefulWidget {
  const _SlidableIconAction({
    required this.controller,
    required this.isStartPane,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final SlidableController controller;
  final bool isStartPane;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  State<_SlidableIconAction> createState() => _SlidableIconActionState();
}

class _SlidableIconActionState extends State<_SlidableIconAction>
    with SingleTickerProviderStateMixin {
  static const double _minIconSize = 16;
  static const double _maxIconSize = 24;
  static const double _iconOvershootCap = 1.15;
  static const double _popTriggerProgress = 0.65;

  late final AnimationController _popController;
  late final CurvedAnimation _popCurved;
  double? _previousProgress;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _popCurved = CurvedAnimation(
      parent: _popController,
      curve: Curves.elasticOut,
      reverseCurve: Curves.elasticIn,
    );
    _popController.addListener(_onPopTick);
    widget.controller.animation.addListener(_onSlidableTick);
  }

  @override
  void didUpdateWidget(covariant _SlidableIconAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.animation.removeListener(_onSlidableTick);
      widget.controller.animation.addListener(_onSlidableTick);
      _previousProgress = null;
    }
  }

  @override
  void dispose() {
    widget.controller.animation.removeListener(_onSlidableTick);
    _popController.removeListener(_onPopTick);
    _popCurved.dispose();
    _popController.dispose();
    super.dispose();
  }

  void _onPopTick() {
    if (mounted) setState(() {});
  }

  void _onSlidableTick() {
    if (!mounted) return;
    final progress = _progress();
    final previous = _previousProgress;
    if (previous != null) {
      final expandThreshold = _popTriggerProgress;
      final shrinkThreshold = 1.0 - _popTriggerProgress;
      final crossedExpandUp = progress >= expandThreshold && previous < expandThreshold;
      final crossedShrinkDown =
          progress < shrinkThreshold && previous >= shrinkThreshold;
      if (crossedExpandUp) {
        HapticFeedback.lightImpact();
        _popController.forward();
      } else if (crossedShrinkDown) {
        HapticFeedback.lightImpact();
        _popController.reverse();
      }
    }
    _previousProgress = progress;
    setState(() {});
  }

  double _progress() {
    if (widget.isStartPane) {
      final ratio = widget.controller.ratio;
      if (ratio <= 0) return 0;
      final extent = widget.controller.startActionPaneExtentRatio;
      if (extent <= 0) return 0;
      return (ratio / extent).clamp(0.0, 1.0);
    }
    final ratio = widget.controller.ratio;
    if (ratio >= 0) return 0;
    final extent = widget.controller.endActionPaneExtentRatio;
    if (extent <= 0) return 0;
    return ((-ratio) / extent).clamp(0.0, 1.0);
  }

  double _iconSize() {
    final u = _popCurved.value.clamp(0.0, _iconOvershootCap);
    return lerpDouble(_minIconSize, _maxIconSize, u)!;
  }

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      onPressed: (_) => widget.onPressed(),
      backgroundColor: widget.backgroundColor,
      foregroundColor: widget.foregroundColor,
      padding: EdgeInsets.zero,
      child: Center(
        child: Icon(widget.icon, size: _iconSize(), color: widget.foregroundColor),
      ),
    );
  }
}
