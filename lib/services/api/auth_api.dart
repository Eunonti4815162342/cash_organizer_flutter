import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/logger/app_logger.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient _client;
  final _storage = const FlutterSecureStorage();

  AuthApi(this._client);

  Future<Map<String, dynamic>?> login(String email, String password, {bool rememberMe = false}) async {
    final data = await _client.post('auth/login', body: {
      'email': email,
      'password': password,
      'rememberMe': rememberMe,
    });

    if (data != null && data['token'] != null) {
      await _storage.write(key: 'jwt_token', value: data['token']);
      AppLogger.info('Login successful for $email');
    }
    return data;
  }

  Future<bool> register(String email, String password) async {
    await _client.post('auth/register', body: {'email': email, 'password': password});
    return true;
  }

  Future<bool> forgotPassword(String email) async {
    await _client.post('auth/forgot-password', body: {'email': email});
    return true;
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    await _client.post('auth/reset-password', body: {'token': token, 'newPassword': newPassword});
    return true;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    AppLogger.info('Logout successful');
  }

  Future<bool> isOnline() async {
    try {
      // Usamos un timeout muy corto para el check de conectividad
      await _client.get('auth/login'); // O cualquier endpoint ligero
      return true;
    } catch (e) {
      return false;
    }
  }
}
