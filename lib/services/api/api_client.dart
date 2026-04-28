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
    final uri = _buildUri(endpoint, queryParameters);
    return _sendRequest('GET', uri);
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    final uri = _buildUri(endpoint, null);
    return _sendRequest('POST', uri, body: body);
  }

  Future<dynamic> put(String endpoint, {dynamic body}) async {
    final uri = _buildUri(endpoint, null);
    return _sendRequest('PUT', uri, body: body);
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = _buildUri(endpoint, null);
    return _sendRequest('DELETE', uri);
  }

  Uri _buildUri(String endpoint, Map<String, String>? queryParameters) {
    String cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$baseUrl$cleanEndpoint').replace(queryParameters: queryParameters);
  }

  Future<dynamic> _sendRequest(String method, Uri uri, {dynamic body}) async {
    final headers = await authHeaders();
    AppLogger.logRequest(method, uri.toString(), headers);

    try {
      late http.Response response;
      final duration = Duration(seconds: apiTimeout);

      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(duration);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(duration);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: jsonEncode(body)).timeout(duration);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(duration);
          break;
      }
      return processResponse(response);
    } catch (e, stack) {
      _handleNetworkError(e, stack);
    }
  }

  void _handleNetworkError(Object e, StackTrace stack) {
    if (e is http.ClientException || e.toString().contains('SocketException')) {
      throw ConnectionException(message: 'No internet connection', originalError: e, stackTrace: stack);
    }
    if (e.toString().contains('TimeoutException')) {
      throw TimeoutException(message: 'Request timed out', originalError: e, stackTrace: stack);
    }
    if (e is AppException) rethrow;
    throw UnknownException(message: e.toString(), originalError: e, stackTrace: stack);
  }

  dynamic processResponse(http.Response response) {
    final status = response.statusCode;
    AppLogger.logResponse(status, response.request?.url.toString() ?? 'unknown', response.body);
    
    if (status >= 200 && status < 300) {
      if (response.body.isEmpty) return null;
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

  bool isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;
}
