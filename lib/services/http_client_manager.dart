import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HttpClientManager {
  final _storage = const FlutterSecureStorage();
  static const String _serverUrl = "http://100.86.48.34:8085/api";

  String get baseUrl {
    String url = _serverUrl.trim();
    if (kIsWeb) url = 'http://localhost:8085/api';
    return url;
  }

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
