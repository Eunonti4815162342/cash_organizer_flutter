import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/financial_entity.dart';
import 'api_client.dart';

class EntityApi {
  final ApiClient _client;

  EntityApi(this._client);

  Future<List<FinancialEntity>> fetchAll() async {
    final response = await http.get(
      Uri.parse('${_client.baseUrl}/entities'),
      headers: await _client.authHeaders(),
    );
    final List<dynamic> list = _client.processResponse(response);
    return list.map((json) => FinancialEntity.fromJson(json)).toList();
  }

  Future<FinancialEntity?> create(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${_client.baseUrl}/entities'),
      headers: await _client.authHeaders(),
      body: jsonEncode(data),
    );
    return FinancialEntity.fromJson(_client.processResponse(response));
  }

  Future<bool> delete(int id) async {
    final response = await http.delete(
      Uri.parse('${_client.baseUrl}/entities/$id'),
      headers: await _client.authHeaders(),
    );
    return _client.isSuccess(response.statusCode);
  }
}
