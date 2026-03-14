import 'dart:convert';

import 'package:mobile/core/network/api_client.dart';

class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.userId,
    required this.displayName,
    required this.email,
    this.avatarUrl,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String token;
  final String userId;
  final String displayName;
  final String email;
  final String? avatarUrl;
}

class AuthApi {
  AuthApi({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<LoginResponse> loginWithGoogle(String idToken) async {
    final response = await _client.post(
      '/login/google',
      body: jsonEncode({'idToken': idToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return LoginResponse.fromJson(data);
    } else {
      throw Exception('後端登入失敗: ${response.statusCode}');
    }
  }
}
