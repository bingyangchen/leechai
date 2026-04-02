import 'package:flutter/material.dart';
import 'package:mobile/features/account/domain/account.dart';
import 'package:mobile/shared/widgets/app_bottom_sheet.dart';

void showAccountPickerSheet(
  BuildContext context, {
  required List<Account> accounts,
  required ValueChanged<Account> onSelect,
}) {
  showAppBottomSheet<void>(
    context,
    mode: AppBottomSheetMode.static,
    builder: (ctx) {
      final maxListHeight = MediaQuery.sizeOf(ctx).height * 0.5;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxListHeight),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final a = accounts[index];
            return ListTile(
              leading: Icon(
                a.displayIcon,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(a.name ?? ''),
              onTap: () {
                onSelect(a);
                Navigator.of(ctx).pop();
              },
            );
          },
        ),
      );
    },
  );
}
