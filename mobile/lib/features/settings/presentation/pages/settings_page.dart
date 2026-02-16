import 'package:flutter/material.dart';

/// 設定 — 分類管理、預算設定、固定收支、匯出資料、帳號資訊
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: const Center(
        child: Text('分類管理、預算設定、固定收支、匯出資料、帳號資訊'),
      ),
    );
  }
}
