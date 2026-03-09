import 'package:flutter/material.dart';
import 'package:mobile/features/account/domain/constants.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;
import 'package:mobile/features/entry/domain/entry_type.dart';
import 'package:mobile/features/entry/presentation/pages/entry_page.dart';
import 'package:mobile/shared/scopes/data_refresh.dart';
import 'package:mobile/shared/theme/app_theme.dart';
import 'package:mobile/shared/utils/thousand_separator_input_formatter.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';
import 'package:mobile/shared/widgets/confirm_delete_dialog.dart';

class EntryListHandlers {
  EntryListHandlers._();

  static void openEntry(
    BuildContext context,
    Map<String, Object?> entry,
    void Function() onSaved,
  ) {
    final typeStr = entry['type'] as String? ?? 'expense';
    final type = EntryType.values.asNameMap()[typeStr];
    if (type == EntryType.adjustment) {
      _showAdjustmentDetailSheet(context, entry);
      return;
    }
    final entryId = entry['id'] as String;
    Navigator.of(context)
        .push<Object?>(
          MaterialPageRoute<Object?>(builder: (_) => EntryPage(entryId: entryId)),
        )
        .then((result) {
          if (!context.mounted) return;
          if (result is Map && result['deleted'] != null) {
            final deletedEntryId = result['deleted'] as String;
            onSaved();
            DataRefreshScope.notify(context);
            final messenger = ScaffoldMessenger.of(context);
            final overlayContext = Navigator.of(context).overlay?.context;
            messenger.showSnackBar(
              SnackBar(
                content: const Text('紀錄已刪除'),
                duration: const Duration(seconds: 4),
                persist: false,
                action: SnackBarAction(
                  label: '復原',
                  onPressed: () async {
                    await EntryRepository.restore(deletedEntryId);
                    onSaved();
                    if (overlayContext != null && overlayContext.mounted) {
                      DataRefreshScope.notify(overlayContext);
                    }
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(const SnackBar(content: Text('已復原')));
                  },
                ),
              ),
            );
          } else if (result == true) {
            onSaved();
            DataRefreshScope.notify(context);
          }
        });
  }

  static void _showAdjustmentDetailSheet(
    BuildContext context,
    Map<String, Object?> entry,
  ) {
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
    final debitId = entry['debit_account_id'] as String? ?? '';
    final isGain = debitId != defaultEquityUnrealizedGainId;
    final displayAmount = formatAmountForDisplay(amount);
    final amountText = isGain ? '+$displayAmount' : '-$displayAmount';

    showAppBottomSheet<void>(
      context,
      title: '資產市值更新',
      mode: AppBottomSheetMode.static,
      builder: (context) {
        final theme = Theme.of(context);
        final amountColor = isGain
            ? AccountingColors.of(context).income
            : AccountingColors.of(context).expense;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  amountText,
                  style: theme.textStyles.headlineEmphasis.copyWith(color: amountColor),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '這筆紀錄是透過「更新市值」功能自動產生的未實現損益。如需修改，請再次更新市值，或將此紀錄刪除。',
                      style: theme.textStyles.bodySmallMuted.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  static Future<void> deleteEntry(
    BuildContext context,
    Map<String, Object?> entry,
    void Function() onDeleted,
  ) async {
    final entryId = entry['id'] as String;
    final confirmed = await ConfirmDeleteDialog.show(context, content: '確定要刪除這筆紀錄嗎？');
    if (confirmed != true || !context.mounted) return;
    await EntryRepository.softDelete(entryId);
    if (context.mounted) {
      onDeleted();
      DataRefreshScope.notify(context);
      final messenger = ScaffoldMessenger.of(context);
      final overlayContext = Navigator.of(context).overlay?.context;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('紀錄已刪除'),
          duration: const Duration(seconds: 4),
          persist: false,
          action: SnackBarAction(
            label: '復原',
            onPressed: () async {
              await EntryRepository.restore(entryId);
              onDeleted();
              if (overlayContext != null && overlayContext.mounted) {
                DataRefreshScope.notify(overlayContext);
              }
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(const SnackBar(content: Text('已復原')));
            },
          ),
        ),
      );
    }
  }

  static Future<void> copyEntry(
    BuildContext context,
    Map<String, Object?> entry,
    void Function() onCopied,
  ) async {
    final entryId = entry['id'] as String;
    try {
      await EntryRepository.duplicate(entryId, DateTime.now());
      if (context.mounted) {
        onCopied();
        DataRefreshScope.notify(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('複製成功！'),
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '複製時發生錯誤，請再試一次',
              style: TextStyle(color: theme.colorScheme.onError),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }
}
