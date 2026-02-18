import 'package:flutter/material.dart';

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
