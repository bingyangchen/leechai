import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog({super.key, this.title, required this.content});

  static const String _defaultTitle = '確認刪除';

  final String? title;
  final String content;

  static Future<bool?> show(
    BuildContext context, {
    String? title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDeleteDialog(title: title, content: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title ?? _defaultTitle),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('刪除'),
        ),
      ],
    );
  }
}
