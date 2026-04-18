import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/account_item.dart';
import 'api_client.dart';

class AccountApi {
  final ApiClient _client;

  AccountApi(this._client);

  Future<List<AccountItem>> fetchAll() async {
    final response = await http.get(
      Uri.parse('${_client.baseUrl}/accounts'),
      headers: await _client.authHeaders(),
    );
    final body = _client.processResponse(response);
    final List<dynamic> list = body is List ? body : (body['content'] ?? []);
    return list.map((json) => AccountItem.fromJson(json)).toList();
  }

  Future<AccountItem?> create(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${_client.baseUrl}/accounts'),
      headers: await _client.authHeaders(),
      body: jsonEncode(data),
    );
    return AccountItem.fromJson(_client.processResponse(response));
  }

  Future<AccountItem?> update(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${_client.baseUrl}/accounts/$id'),
      headers: await _client.authHeaders(),
      body: jsonEncode(data),
    );
    return AccountItem.fromJson(_client.processResponse(response));
  }

  Future<bool> delete(int id) async {
    final response = await http.delete(
      Uri.parse('${_client.baseUrl}/accounts/$id'),
      headers: await _client.authHeaders(),
    );
    return _client.isSuccess(response.statusCode);
  }

  Future<bool> deletePermanently(int id) async {
    final response = await http.delete(
      Uri.parse('${_client.baseUrl}/accounts/$id/permanent'),
      headers: await _client.authHeaders(),
    );
    return _client.isSuccess(response.statusCode);
  }
}
