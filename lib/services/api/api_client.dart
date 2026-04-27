import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/exceptions/app_exceptions.dart';
import '../../core/logger/app_logger.dart';
import '../../config/environment_factory.dart';

/// Shared HTTP concerns: base URL resolution, auth headers, error mapping.
class ApiClient {
  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _defaultNativeUrl = 'http://192.168.1.192:8085/api';
  static const String _defaultWebUrl = 'http://localhost:8085/api';

  final _storage = const FlutterSecureStorage();

  String get baseUrl {
    if (_envApiBaseUrl.isNotEmpty) return _envApiBaseUrl;
    return EnvironmentFactory.getApiBaseUrl();
  }

  int get apiTimeout => EnvironmentFactory.current.apiTimeout;

  Future<Map<String, String>> authHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    return headers;
  }

  Map<String, String> jsonHeaders() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParameters}) async {
    // Si endpoint ya empieza por /, y baseUrl termina en /api, evitamos duplicar
    String cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = Uri.parse('$baseUrl$cleanEndpoint').replace(queryParameters: queryParameters);
    final headers = await authHeaders();
    AppLogger.logRequest('GET', uri.toString(), headers);

    final response = await http.get(uri, headers: headers).timeout(Duration(seconds: apiTimeout));
    return processResponse(response);
  }

  dynamic processResponse(http.Response response) {
    final status = response.statusCode;
    AppLogger.logResponse(status, response.request?.url.toString() ?? 'unknown', response.body);
    
    if (status == 200 || status == 201) {
      return jsonDecode(response.body);
    }
    if (status == 401 || status == 403) {
      throw SessionExpiredException();
    }
    if (status == 404) {
      throw NotFoundException(statusCode: status, message: response.body);
    }
    if (status >= 400 && status < 500) {
      throw BadRequestException(statusCode: status, message: response.body);
    }
    throw ServerErrorException(statusCode: status, message: response.body);
  }

  bool isSuccess(int statusCode) => statusCode == 200 || statusCode == 201 || statusCode == 204;
}
