import 'package:flutter/material.dart';

void showReplacingSnackBar(BuildContext context, SnackBar snackBar) {
  showReplacingSnackBarForMessenger(ScaffoldMessenger.of(context), snackBar);
}

void showReplacingSnackBarForMessenger(
  ScaffoldMessengerState messenger,
  SnackBar snackBar,
) {
  messenger.clearSnackBars();
  messenger.showSnackBar(snackBar);
}
