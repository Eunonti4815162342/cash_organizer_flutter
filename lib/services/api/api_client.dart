import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:natave_flutter/core/exceptions/app_exceptions.dart';
import 'package:natave_flutter/core/logger/app_logger.dart';
import 'package:natave_flutter/config/environment_factory.dart';
import 'package:natave_flutter/core/ports/storage_port.dart';
import 'package:natave_flutter/services/storage/storage_factory.dart';

/// Shared HTTP concerns: base URL resolution, auth headers, error mapping.
class ApiClient {
  final StoragePort _storage = StorageFactory.create();
  
  // CACHE DE TOKEN: Evita leer del SecureStorage (lento en Android) en cada petición
  static String? _cachedToken;

  String get baseUrl => EnvironmentFactory.getApiBaseUrl();
  int get apiTimeout => EnvironmentFactory.current.apiTimeout;

  Future<Map<String, String>> authHeaders() async {
    // Si no tenemos el token en memoria, lo leemos una única vez
    _cachedToken ??= await _storage.read(key: 'jwt_token');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_cachedToken != null) 'Authorization': 'Bearer $_cachedToken',
    };
  }

  /// Limpia el token en memoria (usar al hacer logout)
  static void clearTokenCache() {
    _cachedToken = null;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParameters, Duration? customTimeout}) async {
    final uri = _buildUri(endpoint, queryParameters);
    return _sendRequest('GET', uri, customTimeout: customTimeout);
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

  Future<dynamic> _sendRequest(String method, Uri uri, {dynamic body, Duration? customTimeout}) async {
    final headers = await authHeaders();
    AppLogger.logRequest(method, uri.toString(), headers);

    try {
      late http.Response response;
      final timeout = customTimeout ?? Duration(seconds: apiTimeout);

      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(timeout);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(timeout);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: jsonEncode(body)).timeout(timeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(timeout);
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
    if (e is AppException) throw e;
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
      final hadToken = _cachedToken != null;
      clearTokenCache();
      if (hadToken) throw SessionExpiredException();
      throw UnauthorizedException(statusCode: status);
    }
    if (status == 404) throw NotFoundException(statusCode: status, message: response.body);
    if (status >= 400 && status < 500) throw BadRequestException(statusCode: status, message: response.body);
    throw ServerErrorException(statusCode: status, message: response.body);
  }

  bool isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;
}
