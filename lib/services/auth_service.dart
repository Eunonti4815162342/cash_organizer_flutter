import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_client_manager.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/error/error_handler.dart';
import '../core/logger/app_logger.dart';

class AuthService {
  final HttpClientManager _clientManager;

  AuthService(this._clientManager);

  Future<Map<String, dynamic>?> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      final url = '${_clientManager.baseUrl}/auth/login';
      AppLogger.logRequest('POST', url, {'Content-Type': 'application/json'});

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'rememberMe': rememberMe
        }),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await _clientManager.saveToken(data['token']);
          AppLogger.info('Login successful for $email');
        }
        return data;
      } else {
        throw ErrorHandler.handleHttpError(response);
      }
    } on AppException {
      rethrow;
    } catch (e, stackTrace) {
      final exception = ErrorHandler.handleException(e, stackTrace);
      AppLogger.logException(exception);
      rethrow;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      final url = '${_clientManager.baseUrl}/auth/register';
      AppLogger.logRequest('POST', url, {'Content-Type': 'application/json'});

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      final success = response.statusCode == 200 || response.statusCode == 201;
      if (success) {
        AppLogger.info('Registration successful for $email');
      } else {
        AppLogger.warning('Registration failed: ${response.statusCode}');
      }
      return success;
    } catch (e, stackTrace) {
      final exception = ErrorHandler.handleException(e, stackTrace);
      AppLogger.logException(exception);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _clientManager.clearToken();
      AppLogger.info('Logout successful');
    } catch (e, stackTrace) {
      AppLogger.error('Logout error', e, stackTrace);
    }
  }

  Future<bool> isOnline() async {
    try {
      final url = '${_clientManager.baseUrl}/auth/login';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 2));
      return response.statusCode != 0;
    } catch (e) {
      AppLogger.debug('Connectivity check failed', e);
      return false;
    }
  }
}
