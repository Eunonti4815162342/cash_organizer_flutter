import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/logger/app_logger.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient _client;
  final _storage = const FlutterSecureStorage();

  AuthApi(this._client);

  Future<Map<String, dynamic>?> login(String email, String password, {bool rememberMe = false}) async {
    final url = '${_client.baseUrl}/auth/login';
    final body = jsonEncode({'email': email, 'password': password, 'rememberMe': rememberMe});
    
    AppLogger.logRequest('POST', url, _client.jsonHeaders());
    
    final response = await http.post(
      Uri.parse(url),
      headers: _client.jsonHeaders(),
      body: body,
    ).timeout(Duration(seconds: _client.apiTimeout));

    final data = _client.processResponse(response);
    if (data != null && data['token'] != null) {
      await _storage.write(key: 'jwt_token', value: data['token']);
      AppLogger.info('Login successful for $email');
    }
    return data;
  }

  Future<bool> register(String email, String password) async {
    final url = '${_client.baseUrl}/auth/register';
    final body = jsonEncode({'email': email, 'password': password});
    
    AppLogger.logRequest('POST', url, _client.jsonHeaders());

    final response = await http.post(
      Uri.parse(url),
      headers: _client.jsonHeaders(),
      body: body,
    ).timeout(Duration(seconds: _client.apiTimeout));
    
    final success = _client.isSuccess(response.statusCode);
    if (success) {
      AppLogger.info('Registration successful for $email');
    }
    return success;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    AppLogger.info('Logout successful');
  }

  Future<bool> isOnline() async {
    try {
      final response = await http
          .get(Uri.parse('${_client.baseUrl}/auth/login'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode != 0;
    } catch (e) {
      AppLogger.debug('Connectivity check failed', e);
      return false;
    }
  }
}
