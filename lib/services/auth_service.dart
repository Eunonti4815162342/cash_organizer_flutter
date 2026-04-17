import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_client_manager.dart';

class AuthService {
  final HttpClientManager _clientManager;

  AuthService(this._clientManager);

  Future<Map<String, dynamic>?> login(String email, String password, {bool rememberMe = false}) async {
    try {
      final url = '${_clientManager.baseUrl}/auth/login';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'rememberMe': rememberMe}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await _clientManager.saveToken(data['token']);
        }
        return data;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw 'SESSION_EXPIRED';
      } else {
        throw 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      final url = '${_clientManager.baseUrl}/auth/register';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _clientManager.clearToken();
  }

  Future<bool> isOnline() async {
    try {
      final url = '${_clientManager.baseUrl}/auth/login';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 2));
      return response.statusCode != 0;
    } catch (_) {
      return false;
    }
  }
}
