import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/transaction_item.dart';
import '../../core/logger/app_logger.dart';
import 'api_client.dart';

class TransactionApi {
  final ApiClient _client;

  TransactionApi(this._client);

  Future<List<TransactionItem>> fetch({String? startDate, String? endDate, String? accountId}) async {
    final params = <String, String>{};
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    if (accountId != null) params['accountId'] = accountId;
    
    final uri = Uri.parse('${_client.baseUrl}/transactions').replace(queryParameters: params.isEmpty ? null : params);
    final headers = await _client.authHeaders();
    
    AppLogger.logRequest('GET', uri.toString(), headers);

    final response = await http.get(uri, headers: headers)
        .timeout(Duration(seconds: _client.apiTimeout));
        
    final body = _client.processResponse(response);
    final List<dynamic> list = body['content'] ?? [];
    return list.map((json) => TransactionItem.fromJson(json)).toList();
  }

  Future<TransactionItem?> create(Map<String, dynamic> data) async {
    final url = '${_client.baseUrl}/transactions';
    final headers = await _client.authHeaders();
    
    AppLogger.logRequest('POST', url, headers);

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    ).timeout(Duration(seconds: _client.apiTimeout));
    
    return TransactionItem.fromJson(_client.processResponse(response));
  }

  Future<TransactionItem?> update(int id, Map<String, dynamic> data) async {
    final url = '${_client.baseUrl}/transactions/$id';
    final headers = await _client.authHeaders();
    
    AppLogger.logRequest('PUT', url, headers);

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    ).timeout(Duration(seconds: _client.apiTimeout));
    
    return TransactionItem.fromJson(_client.processResponse(response));
  }

  Future<bool> delete(int id) async {
    final url = '${_client.baseUrl}/transactions/$id';
    final headers = await _client.authHeaders();
    
    AppLogger.logRequest('DELETE', url, headers);

    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    ).timeout(Duration(seconds: _client.apiTimeout));
    
    return _client.isSuccess(response.statusCode);
  }
}
