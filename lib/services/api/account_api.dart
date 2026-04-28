import '../../domain/models/account_item.dart';
import 'api_client.dart';

class AccountApi {
  final ApiClient _client;

  AccountApi(this._client);

  Future<List<AccountItem>> fetchAll() async {
    final body = await _client.get('accounts');
    final List<dynamic> list = body is List ? body : (body['content'] ?? []);
    return list.map((json) => AccountItem.fromJson(json)).toList();
  }

  Future<AccountItem?> create(Map<String, dynamic> data) async {
    final body = await _client.post('accounts', body: data);
    return body != null ? AccountItem.fromJson(body) : null;
  }

  Future<AccountItem?> update(int id, Map<String, dynamic> data) async {
    final body = await _client.put('accounts/$id', body: data);
    return body != null ? AccountItem.fromJson(body) : null;
  }

  Future<bool> delete(int id) async {
    await _client.delete('accounts/$id');
    return true;
  }

  Future<bool> deletePermanently(int id) async {
    await _client.delete('accounts/$id/permanent');
    return true;
  }
}
