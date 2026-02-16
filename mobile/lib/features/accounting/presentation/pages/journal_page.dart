import 'package:flutter/material.dart';
import 'package:mobile/features/accounting/presentation/pages/new_record_page.dart';

/// 明細（記帳首頁）— 預設首頁，用戶每天打開 App 看到的第一個畫面
class JournalPage extends StatelessWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('明細'),
      ),
      body: const Center(
        child: Text('每日收支明細（此處之後顯示紀錄列表）'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const NewRecordPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
