import '../../core/logger/app_logger.dart';
import '../../core/ports/storage_port.dart';
import '../storage/storage_factory.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient _client;
  final StoragePort _storage = StorageFactory.create();

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
      // Usamos un endpoint que acepte GET (como accounts)
      // Si el servidor responde (aunque sea un 401), significa que hay conexión
      await _client.get('accounts');
      return true;
    } catch (e) {
      // Si el error es de red (ConnectionException/Timeout), devolvemos false
      // Si el error es de servidor o auth (401, 500), devolvemos true porque el servidor es alcanzable
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('connection') || errStr.contains('timeout') || errStr.contains('socket')) {
        return false;
      }
      return true; // El servidor respondió, ergo hay conexión
    }
  }
}
