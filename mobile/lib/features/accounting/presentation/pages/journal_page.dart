import 'package:flutter/material.dart';

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
    );
  }
}
