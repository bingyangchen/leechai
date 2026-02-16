import 'package:flutter/material.dart';

/// 登入/註冊頁（之後實作）
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登入')),
      body: const Center(child: Text('登入 / 註冊')),
    );
  }
}
