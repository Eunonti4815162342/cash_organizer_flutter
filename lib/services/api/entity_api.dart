import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/financial_entity.dart';
import '../../core/logger/app_logger.dart';
import 'api_client.dart';

class EntityApi {
  final ApiClient _client;

  EntityApi(this._client);

  Future<List<FinancialEntity>> fetchAll() async {
    final url = '${_client.baseUrl}/entities';
    final headers = await _client.authHeaders();
    AppLogger.logRequest('GET', url, headers);

    final response = await http.get(Uri.parse(url), headers: headers)
        .timeout(Duration(seconds: _client.apiTimeout));
        
    final List<dynamic> list = _client.processResponse(response);
    return list.map((json) => FinancialEntity.fromJson(json)).toList();
  }

  Future<FinancialEntity?> create(Map<String, dynamic> data) async {
    final url = '${_client.baseUrl}/entities';
    final headers = await _client.authHeaders();
    AppLogger.logRequest('POST', url, headers);

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    ).timeout(Duration(seconds: _client.apiTimeout));
    
    return FinancialEntity.fromJson(_client.processResponse(response));
  }

  Future<bool> delete(int id) async {
    final url = '${_client.baseUrl}/entities/$id';
    final headers = await _client.authHeaders();
    AppLogger.logRequest('DELETE', url, headers);

    final response = await http.delete(Uri.parse(url), headers: headers)
        .timeout(Duration(seconds: _client.apiTimeout));
        
    return _client.isSuccess(response.statusCode);
  }
}
