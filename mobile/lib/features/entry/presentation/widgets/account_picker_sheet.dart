import 'package:flutter/material.dart';
import 'package:mobile/features/entry/domain/account_item.dart';

void showAccountPickerSheet(
  BuildContext context, {
  required List<AccountItem> accounts,
  required ValueChanged<AccountItem> onSelect,
  String? excludeAccountId,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final a = accounts[index];
                final isDisabled =
                    excludeAccountId != null && a.id == excludeAccountId;
                return ListTile(
                  leading: Icon(
                    a.displayIcon,
                    color: isDisabled
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    a.name,
                    style: isDisabled
                        ? TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.5),
                          )
                        : null,
                  ),
                  onTap: isDisabled
                      ? null
                      : () {
                          onSelect(a);
                          Navigator.of(ctx).pop();
                        },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
