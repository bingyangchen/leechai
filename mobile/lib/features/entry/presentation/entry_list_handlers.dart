import 'package:flutter/material.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart'
    show EntryRepository;
import 'package:mobile/features/entry/presentation/pages/entry_page.dart';
import 'package:mobile/shared/widgets/confirm_delete_dialog.dart';

class EntryListHandlers {
  EntryListHandlers._();

  static void openEntry(BuildContext context, String entryId, void Function() onSaved) {
    Navigator.of(context)
        .push<bool?>(
          MaterialPageRoute<bool?>(builder: (_) => EntryPage(entryId: entryId)),
        )
        .then((saved) {
          if (saved == true) onSaved();
        });
  }

  static Future<void> deleteEntry(
    BuildContext context,
    String entryId,
    void Function() onDeleted,
  ) async {
    final confirmed = await ConfirmDeleteDialog.show(context);
    if (confirmed != true || !context.mounted) return;
    await EntryRepository.softDelete(entryId);
    if (context.mounted) onDeleted();
  }

  static Future<void> copyEntry(
    BuildContext context,
    String entryId,
    void Function() onCopied,
  ) async {
    try {
      await EntryRepository.duplicate(entryId, DateTime.now());
      if (context.mounted) {
        onCopied();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已複製一筆紀錄'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('複製失敗'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}
