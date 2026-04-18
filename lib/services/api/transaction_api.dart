import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/transaction_item.dart';
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

    final response = await http.get(uri, headers: await _client.authHeaders());
    final body = _client.processResponse(response);
    final List<dynamic> list = body['content'] ?? [];
    return list.map((json) => TransactionItem.fromJson(json)).toList();
  }

  Future<TransactionItem?> create(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${_client.baseUrl}/transactions'),
      headers: await _client.authHeaders(),
      body: jsonEncode(data),
    );
    return TransactionItem.fromJson(_client.processResponse(response));
  }

  Future<TransactionItem?> update(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${_client.baseUrl}/transactions/$id'),
      headers: await _client.authHeaders(),
      body: jsonEncode(data),
    );
    return TransactionItem.fromJson(_client.processResponse(response));
  }

  Future<bool> delete(int id) async {
    final response = await http.delete(
      Uri.parse('${_client.baseUrl}/transactions/$id'),
      headers: await _client.authHeaders(),
    );
    return _client.isSuccess(response.statusCode);
  }
}
