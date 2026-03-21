import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/core/auth/auth_session_events.dart';
import 'package:mobile/features/auth/data/repositories/auth.dart';

class ApiClient {
  ApiClient({
    this.baseUrl = 'https://b2e1-1-161-12-66.ngrok-free.app',
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  static Completer<bool>? _refreshCompleter;

  Future<http.Response> get(String path, {Map<String, String>? queryParameters}) async {
    return _withAuthRetry((token) async {
      var uri = Uri.parse('$baseUrl$path');
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }
      return _httpClient.get(
        uri,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );
    });
  }

  Future<http.Response> post(String path, {required String body}) async {
    return _withAuthRetry((token) async {
      return _httpClient.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      );
    });
  }

  Future<http.Response> postAnonymous({
    required String path,
    required String body,
  }) async {
    return _httpClient.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
  }

  Future<http.Response> _withAuthRetry(
    Future<http.Response> Function(String? token) send,
  ) async {
    final token = await _getAccessToken();
    var response = await send(token);
    if (response.statusCode == 401 && token != null) {
      final refreshed = await _refreshTokensIfNeeded();
      if (refreshed) {
        final newToken = await _getAccessToken();
        response = await send(newToken);
      }
    }
    return response;
  }

  Future<String?> _getAccessToken() async {
    final state = await AuthRepository.load();
    return state?.accessToken;
  }

  Future<bool> _refreshTokensIfNeeded() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final state = await AuthRepository.load();
      final refresh = state?.refreshToken;
      if (refresh == null || refresh.isEmpty) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        return false;
      }
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refresh}),
      );
      if (response.statusCode != 200) {
        await AuthRepository.clear();
        AuthSessionEvents.onSessionInvalidated?.call();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        return false;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final access = data['access_token'] as String;
      final newRefresh = data['refresh_token'] as String;
      await AuthRepository.updateTokens(accessToken: access, refreshToken: newRefresh);
      AuthSessionEvents.onTokensRefreshed?.call(access, newRefresh);
      if (!completer.isCompleted) {
        completer.complete(true);
      }
      return true;
    } catch (_) {
      await AuthRepository.clear();
      AuthSessionEvents.onSessionInvalidated?.call();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }
}
