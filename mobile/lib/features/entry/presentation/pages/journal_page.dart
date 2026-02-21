import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/features/entry/data/repositories/entry.dart' as entry_repo;
import 'package:mobile/features/entry/domain/entry_type.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key, this.refreshTrigger});

  final ValueListenable<int>? refreshTrigger;

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  late Future<List<Map<String, Object?>>> _future;

  @override
  void initState() {
    super.initState();
    _future = entry_repo.EntryRepository.getAll();
    widget.refreshTrigger?.addListener(_onRefreshTrigger);
  }

  @override
  void didUpdateWidget(JournalPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      oldWidget.refreshTrigger?.removeListener(_onRefreshTrigger);
      widget.refreshTrigger?.addListener(_onRefreshTrigger);
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTrigger);
    super.dispose();
  }

  void _onRefreshTrigger() {
    setState(() {
      _future = entry_repo.EntryRepository.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('明細'),
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('錯誤：${snapshot.error}'));
          }
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(child: Text('尚無紀錄'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final e = entries[index];
              final typeStr = e['type'] as String? ?? '';
              final type = EntryType.values.asNameMap()[typeStr] ?? EntryType.expense;
              final amount = (e['amount'] as num?)?.toDouble() ?? 0.0;
              final occurredAt = e['occurred_at'] as String? ?? '';
              final memo = e['memo'] as String?;
              final date = _formatDate(occurredAt);
              return ListTile(
                title: Text('${type.label} · $date'),
                subtitle: memo != null && memo.isNotEmpty ? Text(memo) : null,
                trailing: Text(
                  amount.toStringAsFixed(0),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: type == EntryType.income
                        ? Colors.green
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return iso;
    }
  }
}
