import 'package:flutter/material.dart';

enum SyncStatus { idle, syncing, error }

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key, required this.status});
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SyncStatus.idle:
        return Icon(
          Icons.cloud_done_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        );
      case SyncStatus.syncing:
        return Icon(
          Icons.cloud_upload_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        );
      case SyncStatus.error:
        return Icon(
          Icons.cloud_off_outlined,
          color: Theme.of(context).colorScheme.error,
          size: 24,
        );
    }
  }
}
