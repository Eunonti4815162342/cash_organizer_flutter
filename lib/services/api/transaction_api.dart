import 'package:natave_flutter/domain/models/transaction_item.dart';
import 'package:natave_flutter/domain/models/transaction_filters.dart';
import 'package:natave_flutter/services/api/api_client.dart';

class TransactionApi {
  final ApiClient _client;

  TransactionApi(this._client);

  Future<List<TransactionItem>> fetch(TransactionFilters filters) async {
    final params = <String, String>{};
    if (filters.startDate != null) params['startDate'] = filters.startDate!;
    if (filters.endDate != null) params['endDate'] = filters.endDate!;
    if (filters.accountIds != null && filters.accountIds!.isNotEmpty) {
      params['accountIds'] = filters.accountIds!.join(',');
    }
    if (filters.categoryIds != null && filters.categoryIds!.isNotEmpty) {
      params['categoryIds'] = filters.categoryIds!.join(',');
    }
    if (filters.subcategoryIds != null && filters.subcategoryIds!.isNotEmpty) {
      params['subcategoryIds'] = filters.subcategoryIds!.join(',');
    }
    if (filters.beneficiaryIds != null && filters.beneficiaryIds!.isNotEmpty) {
      params['beneficiaryIds'] = filters.beneficiaryIds!.join(',');
    }
    
    params['page'] = filters.page.toString();
    params['size'] = filters.size.toString();
    
    final body = await _client.get('transactions', queryParameters: params.isEmpty ? null : params);
    final List<dynamic> list = body?['content'] ?? [];
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
    await _client.delete('transactions/$id');
    return true; 
  }
}
