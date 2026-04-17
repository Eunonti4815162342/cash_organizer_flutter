import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment_factory.dart';

class HttpClientManager {
  final _storage = const FlutterSecureStorage();

  /// Get base URL from current environment configuration
  String get baseUrl => EnvironmentFactory.current.apiBaseUrl;

  /// Get API timeout in seconds from current environment
  int get apiTimeout => EnvironmentFactory.current.apiTimeout;

  /// Check if logging is enabled
  bool get enableLogging => EnvironmentFactory.current.enableLogging;

  Future<Map<String, String>> getHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}
