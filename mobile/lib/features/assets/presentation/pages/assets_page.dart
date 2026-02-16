import 'package:flutter/material.dart';

/// 資產 — 管理現金、銀行卡、信用卡、電子支付的餘額
class AssetsPage extends StatelessWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('資產'),
      ),
      body: const Center(
        child: Text('現金、銀行卡、信用卡、電子支付餘額管理'),
      ),
    );
  }
}
