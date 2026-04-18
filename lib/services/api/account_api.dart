import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/account_item.dart';
import '../../core/logger/app_logger.dart';
import 'api_client.dart';

class AccountApi {
  final ApiClient _client;

  AccountApi(this._client);

  Future<List<AccountItem>> fetchAll() async {
    final url = '${_client.baseUrl}/accounts';
    final headers = await _client.authHeaders();
    AppLogger.logRequest('GET', url, headers);

    final response = await http.get(Uri.parse(url), headers: headers)
        .timeout(Duration(seconds: _client.apiTimeout));
        
    final body = _client.processResponse(response);
    final List<dynamic> list = body is List ? body : (body['content'] ?? []);
    return list.map((json) => AccountItem.fromJson(json)).toList();
  }

  Future<AccountItem?> create(Map<String, dynamic> data) async {
    final url = '${_client.baseUrl}/accounts';
    final headers = await _client.authHeaders();
    AppLogger.logRequest('POST', url, headers);

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    ).timeout(Duration(seconds: _client.apiTimeout));
    
    return AccountItem.fromJson(_client.processResponse(response));
  }

  Future<AccountItem?> update(int id, Map<String, dynamic> data) async {
    final url = '${_client.baseUrl}/accounts/$id';
    final headers = await _client.authHeaders();
    AppLogger.logRequest('PUT', url, headers);

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    ).timeout(Duration(seconds: _client.apiTimeout));
    
    return AccountItem.fromJson(_client.processResponse(response));
  }

  Future<bool> delete(int id) async {
    final url = '${_client.baseUrl}/accounts/$id';
    final headers = await _client.authHeaders();
    AppLogger.logRequest('DELETE', url, headers);

    final response = await http.delete(Uri.parse(url), headers: headers)
        .timeout(Duration(seconds: _client.apiTimeout));
        
    return _client.isSuccess(response.statusCode);
  }

  Future<bool> deletePermanently(int id) async {
    final url = '${_client.baseUrl}/accounts/$id/permanent';
    final headers = await _client.authHeaders();
    AppLogger.logRequest('DELETE', url, headers);

    final response = await http.delete(Uri.parse(url), headers: headers)
        .timeout(Duration(seconds: _client.apiTimeout));
        
    return _client.isSuccess(response.statusCode);
  }
}
