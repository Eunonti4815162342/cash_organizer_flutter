import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient _client;
  final _storage = const FlutterSecureStorage();

  AuthApi(this._client);

  Future<Map<String, dynamic>?> login(String email, String password, {bool rememberMe = false}) async {
    final response = await http.post(
      Uri.parse('${_client.baseUrl}/auth/login'),
      headers: _client.jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password, 'rememberMe': rememberMe}),
    ).timeout(const Duration(seconds: 15));
    return _client.processResponse(response);
  }

  Future<bool> register(String email, String password) async {
    final response = await http.post(
      Uri.parse('${_client.baseUrl}/auth/register'),
      headers: _client.jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _client.isSuccess(response.statusCode);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> isOnline() async {
    try {
      final response = await http
          .get(Uri.parse('${_client.baseUrl}/auth/login'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode != 0;
    } catch (_) {
      return false;
    }
  }
}
