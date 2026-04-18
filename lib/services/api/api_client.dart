import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/exceptions/app_exceptions.dart';

/// Shared HTTP concerns: base URL resolution, auth headers, error mapping.
class ApiClient {
  static const String _defaultServerUrl = 'http://100.86.48.34:8085/api';

  final _storage = const FlutterSecureStorage();

  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8085/api';
    return _defaultServerUrl;
  }

  Future<Map<String, String>> authHeaders() async {
    final token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> jsonHeaders() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  dynamic processResponse(http.Response response) {
    final status = response.statusCode;
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
