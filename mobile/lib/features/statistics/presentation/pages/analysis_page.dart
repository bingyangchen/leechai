import 'package:flutter/material.dart';

/// 統計（依賴 accounting 層的數據進行視覺化：圓餅圖、趨勢圖）
class AnalysisPage extends StatelessWidget {
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('統計'),
      ),
      body: const Center(
        child: Text('圖表分析（圓餅圖、長條圖）'),
      ),
    );
  }
}
