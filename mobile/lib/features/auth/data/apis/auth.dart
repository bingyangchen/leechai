import 'dart:convert';

import 'package:mobile/core/network/api_client.dart';

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.displayName,
    required this.email,
    this.avatarUrl,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String displayName;
  final String email;
  final String? avatarUrl;
}

class AuthApi {
  AuthApi({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<LoginResponse> loginWithGoogle(String idToken) async {
    final response = await _client.postAnonymous(
      path: '/auth/login/google',
      body: jsonEncode({'id_token': idToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return LoginResponse.fromJson(data);
    } else {
      throw Exception('後端登入失敗: ${response.statusCode}');
    }
  }

  Future<void> logout(String refreshToken) async {
    await _client.postAnonymous(
      path: '/auth/logout',
      body: jsonEncode({'refresh_token': refreshToken}),
    );
  }
}
