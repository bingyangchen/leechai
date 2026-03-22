import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/core/auth/auth_session_events.dart';
import 'package:mobile/core/auth/credential_store.dart';

class ApiClient {
  ApiClient({
    required AuthCredentialStore credentialStore,
    this.baseUrl = 'https://api.leechai.app',
    http.Client? httpClient,
  }) : _credentialStore = credentialStore,
       _httpClient = httpClient ?? http.Client();

  final AuthCredentialStore _credentialStore;
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
    final credentials = await _credentialStore.load();
    return credentials?.accessToken;
  }

  Future<bool> _refreshTokensIfNeeded() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final credentials = await _credentialStore.load();
      final refresh = credentials?.refreshToken;
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
        await _credentialStore.clear();
        AuthSessionEvents.onSessionInvalidated?.call();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        return false;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final access = data['access_token'] as String;
      final newRefresh = data['refresh_token'] as String;
      await _credentialStore.updateTokens(
        accessToken: access,
        refreshToken: newRefresh,
      );
      AuthSessionEvents.onTokensRefreshed?.call(access, newRefresh);
      if (!completer.isCompleted) {
        completer.complete(true);
      }
      return true;
    } catch (_) {
      await _credentialStore.clear();
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
