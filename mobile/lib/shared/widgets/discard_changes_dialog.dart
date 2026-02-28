import 'package:flutter/material.dart';

class DiscardChangesDialog extends StatelessWidget {
  const DiscardChangesDialog({
    super.key,
    this.title = '捨棄變更？',
    this.content = '有未儲存的變更，確定要離開嗎？',
    this.confirmLabel = '離開',
  });

  final String title;
  final String content;
  final String confirmLabel;

  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? content,
    String? confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DiscardChangesDialog(
        title: title ?? '捨棄變更？',
        content: content ?? '有未儲存的變更，確定要離開嗎？',
        confirmLabel: confirmLabel ?? '離開',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
