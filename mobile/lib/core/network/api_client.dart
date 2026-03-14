import 'package:http/http.dart' as http;
import 'package:mobile/features/auth/data/repositories/auth.dart';

class ApiClient {
  ApiClient({this.baseUrl = 'https://api.leechai.app', http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Future<http.Response> get(String path) async {
    final token = await _getToken();
    return _httpClient.get(
      Uri.parse('$baseUrl$path'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
  }

  Future<http.Response> post(String path, {required String body}) async {
    final token = await _getToken();
    return _httpClient.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: body,
    );
  }

  Future<String?> _getToken() async {
    final state = await AuthRepository.load();
    return state?.appToken;
  }
}
