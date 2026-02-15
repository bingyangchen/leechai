import 'package:flutter/material.dart';

/// 新增一筆紀錄的頁面（之後再實作表單等內容）
class NewRecordPage extends StatelessWidget {
  const NewRecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增紀錄'),
      ),
      body: const Center(
        child: Text('new record'),
      ),
    );
  }
}
