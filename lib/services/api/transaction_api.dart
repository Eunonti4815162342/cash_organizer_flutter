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
    
    final body = await _client.get('transactions', queryParameters: params.isEmpty ? null : params);
    final List<dynamic> list = body['content'] ?? [];
    return list.map((json) => TransactionItem.fromJson(json)).toList();
  }

  Future<TransactionItem?> create(Map<String, dynamic> data) async {
    final body = await _client.post('transactions', body: data);
    return body != null ? TransactionItem.fromJson(body) : null;
  }

  Future<TransactionItem?> update(int id, Map<String, dynamic> data) async {
    final body = await _client.put('transactions/$id', body: data);
    return body != null ? TransactionItem.fromJson(body) : null;
  }

  Future<bool> delete(int id) async {
    // Para el delete, el cliente devuelve null si es 200/204
    await _client.delete('transactions/$id');
    return true; // Si no lanzó excepción, es éxito
  }
}
